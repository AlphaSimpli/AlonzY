BEGIN;

CREATE TABLE IF NOT EXISTS public.safety_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
    shared_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    consent_given_at TIMESTAMPTZ,
    consented_at TIMESTAMPTZ,
    stopped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.safety_shares
    ADD COLUMN IF NOT EXISTS booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS shared_user_id UUID,
    ADD COLUMN IF NOT EXISTS token TEXT,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS consent_given_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS consented_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS stopped_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

DO $migration$
DECLARE
    v_constraint RECORD;
BEGIN
    FOR v_constraint IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'public.safety_shares'::regclass
          AND contype = 'f'
          AND conkey = ARRAY[
              (SELECT attnum
               FROM pg_attribute
               WHERE attrelid = 'public.safety_shares'::regclass
                 AND attname = 'shared_user_id')
          ]::SMALLINT[]
    LOOP
        EXECUTE format(
            'ALTER TABLE public.safety_shares DROP CONSTRAINT %I',
            v_constraint.conname
        );
    END LOOP;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.safety_shares'::regclass
          AND conname = 'safety_shares_shared_user_id_fkey'
    ) THEN
        ALTER TABLE public.safety_shares
            ADD CONSTRAINT safety_shares_shared_user_id_fkey
            FOREIGN KEY (shared_user_id)
            REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END;
$migration$;

UPDATE public.safety_shares s
SET ride_id = b.ride_id,
    shared_user_id = COALESCE(s.shared_user_id, b.passenger_id),
    consented_at = COALESCE(s.consented_at, s.consent_given_at),
    consent_given_at = COALESCE(s.consent_given_at, s.consented_at)
FROM public.bookings b
WHERE b.id = s.booking_id
  AND (
      s.ride_id IS NULL
      OR s.shared_user_id IS NULL
      OR s.consented_at IS NULL
      OR s.consent_given_at IS NULL
  );

CREATE UNIQUE INDEX IF NOT EXISTS safety_shares_token_unique_idx
    ON public.safety_shares(token)
    WHERE token IS NOT NULL;
CREATE INDEX IF NOT EXISTS safety_shares_ride_user_active_idx
    ON public.safety_shares(ride_id, shared_user_id, expires_at)
    WHERE is_active;

ALTER TABLE public.safety_shares ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE ON public.safety_shares TO authenticated;

DROP POLICY IF EXISTS safety_shares_select_booking_owner
    ON public.safety_shares;
DROP POLICY IF EXISTS safety_shares_select_share_owner
    ON public.safety_shares;
CREATE POLICY safety_shares_select_share_owner
    ON public.safety_shares FOR SELECT TO authenticated
    USING (shared_user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS safety_shares_insert_confirmed_booking
    ON public.safety_shares;
CREATE POLICY safety_shares_insert_confirmed_booking
    ON public.safety_shares FOR INSERT TO authenticated
    WITH CHECK (
        shared_user_id = (SELECT auth.uid())
        AND is_active
        AND token IS NOT NULL
        AND expires_at > now()
        AND expires_at <= now() + interval '24 hours'
        AND COALESCE(consented_at, consent_given_at) IS NOT NULL
        AND COALESCE(consented_at, consent_given_at) <= now()
        AND EXISTS (
            SELECT 1
            FROM public.bookings b
            JOIN public.rides r ON r.id = b.ride_id
            WHERE b.id = safety_shares.booking_id
              AND b.ride_id = safety_shares.ride_id
              AND b.status = 'confirmed'
              AND r.status IN ('available', 'in_progress')
              AND (
                  b.passenger_id = (SELECT auth.uid())
                  OR r.driver_id = (SELECT auth.uid())
              )
        )
    );

DROP POLICY IF EXISTS safety_shares_update_booking_owner
    ON public.safety_shares;
CREATE POLICY safety_shares_update_booking_owner
    ON public.safety_shares FOR UPDATE TO authenticated
    USING (
        shared_user_id = (SELECT auth.uid())
        AND is_active
    )
    WITH CHECK (
        shared_user_id = (SELECT auth.uid())
        AND NOT is_active
    );

CREATE OR REPLACE FUNCTION public.sync_safety_share_consent_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.consented_at := COALESCE(NEW.consented_at, NEW.consent_given_at);
        NEW.consent_given_at := COALESCE(NEW.consent_given_at, NEW.consented_at);
    ELSIF NEW.consented_at IS DISTINCT FROM OLD.consented_at
       AND NEW.consent_given_at IS NOT DISTINCT FROM OLD.consent_given_at THEN
        NEW.consent_given_at := NEW.consented_at;
    ELSIF NEW.consent_given_at IS DISTINCT FROM OLD.consent_given_at
       AND NEW.consented_at IS NOT DISTINCT FROM OLD.consented_at THEN
        NEW.consented_at := NEW.consent_given_at;
    ELSIF NEW.consented_at IS DISTINCT FROM OLD.consented_at
       AND NEW.consent_given_at IS DISTINCT FROM OLD.consent_given_at THEN
        RAISE EXCEPTION 'Safety-share consent evidence is immutable';
    END IF;
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS sync_safety_share_consent_columns
    ON public.safety_shares;
CREATE TRIGGER sync_safety_share_consent_columns
    BEFORE INSERT OR UPDATE OF consented_at, consent_given_at
    ON public.safety_shares
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_safety_share_consent_columns();

CREATE OR REPLACE FUNCTION public.can_access_live_ride(p_ride_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
    SELECT EXISTS (
        SELECT 1
        FROM public.rides r
        WHERE r.id = p_ride_id
          AND r.status IN ('available', 'in_progress')
          AND (
              r.driver_id = (SELECT auth.uid())
              OR EXISTS (
                  SELECT 1
                  FROM public.bookings b
                  WHERE b.ride_id = r.id
                    AND b.passenger_id = (SELECT auth.uid())
                    AND b.status = 'confirmed'
              )
          )
    );
$function$;

REVOKE ALL ON FUNCTION public.can_access_live_ride(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_access_live_ride(UUID) TO authenticated;

ALTER TABLE public.ride_live_locations ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON public.ride_live_locations TO authenticated;

DROP POLICY IF EXISTS ride_live_locations_select_participants
    ON public.ride_live_locations;
CREATE POLICY ride_live_locations_select_participants
    ON public.ride_live_locations FOR SELECT TO authenticated
    USING (public.can_access_live_ride(ride_id));

DROP POLICY IF EXISTS ride_live_locations_insert_self
    ON public.ride_live_locations;
CREATE POLICY ride_live_locations_insert_self
    ON public.ride_live_locations FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND public.can_access_live_ride(ride_id)
    );

DROP POLICY IF EXISTS ride_live_locations_update_self
    ON public.ride_live_locations;
CREATE POLICY ride_live_locations_update_self
    ON public.ride_live_locations FOR UPDATE TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        AND public.can_access_live_ride(ride_id)
    )
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND public.can_access_live_ride(ride_id)
    );

DROP POLICY IF EXISTS ride_live_locations_delete_self
    ON public.ride_live_locations;
CREATE POLICY ride_live_locations_delete_self
    ON public.ride_live_locations FOR DELETE TO authenticated
    USING (user_id = (SELECT auth.uid()));

NOTIFY pgrst, 'reload schema';
COMMIT;
