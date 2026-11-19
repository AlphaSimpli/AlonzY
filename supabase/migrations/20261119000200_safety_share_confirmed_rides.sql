BEGIN;

ALTER TABLE public.safety_shares
    ADD COLUMN IF NOT EXISTS shared_user_id UUID
        REFERENCES public.profiles(id) ON DELETE CASCADE;

UPDATE public.safety_shares s
SET shared_user_id = b.passenger_id
FROM public.bookings b
WHERE b.id = s.booking_id
  AND s.shared_user_id IS NULL;

ALTER TABLE public.safety_shares
    ALTER COLUMN shared_user_id SET NOT NULL;

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
        AND consent_given_at IS NOT NULL
        AND consent_given_at <= now()
        AND expires_at > now()
        AND expires_at <= now() + interval '24 hours'
        AND EXISTS (
            SELECT 1
            FROM public.bookings b
            JOIN public.rides r ON r.id = b.ride_id
            WHERE b.id = booking_id
              AND b.status IN ('confirmed', 'in_progress')
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

DROP POLICY IF EXISTS ride_positions_insert_active_participant
    ON public.ride_positions;
CREATE POLICY ride_positions_insert_active_participant
    ON public.ride_positions FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1
            FROM public.rides r
            WHERE r.id = ride_id
              AND r.status IN ('available', 'in_progress')
              AND (
                  r.driver_id = (SELECT auth.uid())
                  OR EXISTS (
                      SELECT 1
                      FROM public.bookings b
                      WHERE b.ride_id = r.id
                        AND b.passenger_id = (SELECT auth.uid())
                        AND b.status IN ('confirmed', 'in_progress')
                  )
              )
        )
        AND EXISTS (
            SELECT 1
            FROM public.safety_shares s
            JOIN public.bookings b ON b.id = s.booking_id
            WHERE b.ride_id = public.ride_positions.ride_id
              AND s.shared_user_id = (SELECT auth.uid())
              AND s.is_active
              AND s.consent_given_at IS NOT NULL
              AND s.expires_at > now()
        )
    );

CREATE OR REPLACE FUNCTION public.clear_revoked_safety_position()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_ride_id UUID;
BEGIN
    IF OLD.is_active AND NOT NEW.is_active THEN
        SELECT b.ride_id
        INTO v_ride_id
        FROM public.bookings b
        WHERE b.id = NEW.booking_id;

        DELETE FROM public.ride_positions rp
        WHERE rp.ride_id = v_ride_id
          AND rp.user_id = NEW.shared_user_id
          AND NOT EXISTS (
              SELECT 1
              FROM public.safety_shares s
              JOIN public.bookings b ON b.id = s.booking_id
              WHERE b.ride_id = v_ride_id
                AND s.shared_user_id = NEW.shared_user_id
                AND s.id <> NEW.id
                AND s.is_active
                AND s.expires_at > now()
          );
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_shared_position(share_token TEXT)
RETURNS TABLE (lat DOUBLE PRECISION, lng DOUBLE PRECISION, recorded_at TIMESTAMPTZ)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
    SELECT p.lat, p.lng, p.recorded_at
    FROM public.safety_shares s
    JOIN public.bookings b ON b.id = s.booking_id
    JOIN public.rides r ON r.id = b.ride_id
    JOIN LATERAL (
        SELECT rp.lat, rp.lng, rp.recorded_at
        FROM public.ride_positions rp
        WHERE rp.ride_id = r.id
          AND rp.user_id = s.shared_user_id
        ORDER BY rp.recorded_at DESC, rp.id DESC
        LIMIT 1
    ) p ON TRUE
    WHERE s.token = $1
      AND s.is_active
      AND s.expires_at > now()
      AND b.status IN ('confirmed', 'in_progress')
      AND r.status IN ('available', 'in_progress')
    LIMIT 1;
$function$;

CREATE OR REPLACE FUNCTION public.can_access_live_ride(p_ride_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.rides r
        WHERE r.id = p_ride_id
          AND r.status IN ('available', 'in_progress')
          AND (
              r.driver_id = auth.uid()
              OR EXISTS (
                  SELECT 1
                  FROM public.bookings b
                  WHERE b.ride_id = r.id
                    AND b.passenger_id = auth.uid()
                    AND b.status IN ('confirmed', 'accepted', 'in_progress')
              )
          )
    );
$$;

CREATE OR REPLACE FUNCTION public.clear_ended_ride_live_locations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF OLD.status IN ('available', 'in_progress')
       AND NEW.status NOT IN ('available', 'in_progress') THEN
        DELETE FROM public.ride_live_locations WHERE ride_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.clear_ended_safety_tracking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
    IF OLD.status IN ('available', 'in_progress')
       AND NEW.status NOT IN ('available', 'in_progress') THEN
        UPDATE public.safety_shares s
        SET is_active = FALSE
        FROM public.bookings b
        WHERE b.id = s.booking_id
          AND b.ride_id = NEW.id
          AND s.is_active;
        DELETE FROM public.ride_positions WHERE ride_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$function$;

NOTIFY pgrst, 'reload schema';
COMMIT;
