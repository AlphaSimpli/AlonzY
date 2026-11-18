-- Matching feedback and temporary, token-based safety sharing.
-- The origin_geog generated column and GiST index are provided by
-- 20261116000200_add_ride_geography.sql. Its generated expression replaces a
-- trigger and also backfills existing rides.

BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.set_ride_origin_geog()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
    NEW.origin_geog := CASE
        WHEN NEW.origin_lat IS NOT NULL AND NEW.origin_lng IS NOT NULL
        THEN extensions.ST_SetSRID(
            extensions.ST_MakePoint(NEW.origin_lng, NEW.origin_lat), 4326
        )::extensions.geography
        ELSE NULL
    END;
    RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.set_ride_origin_geog() FROM PUBLIC;

-- Earlier deployments already use a GENERATED column, which is safer than a
-- trigger and also backfills old rows. Install the trigger only on legacy
-- schemas that have (or need) an ordinary geography column.
DO $$
DECLARE
    v_generated TEXT;
BEGIN
    SELECT is_generated INTO v_generated
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'rides'
      AND column_name = 'origin_geog';

    IF v_generated IS NULL THEN
        ALTER TABLE public.rides
            ADD COLUMN origin_geog extensions.geography(Point, 4326);
    END IF;

    IF v_generated IS DISTINCT FROM 'ALWAYS' THEN
        DROP TRIGGER IF EXISTS rides_set_origin_geog ON public.rides;
        CREATE TRIGGER rides_set_origin_geog
            BEFORE INSERT OR UPDATE OF origin_lat, origin_lng ON public.rides
            FOR EACH ROW
            EXECUTE FUNCTION public.set_ride_origin_geog();
        UPDATE public.rides
        SET origin_geog = CASE
            WHEN origin_lat IS NOT NULL AND origin_lng IS NOT NULL
            THEN extensions.ST_SetSRID(
                extensions.ST_MakePoint(origin_lng, origin_lat), 4326
            )::extensions.geography
            ELSE NULL
        END;
    END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS rides_origin_geog_gist
    ON public.rides USING GIST (origin_geog);

CREATE TABLE IF NOT EXISTS public.match_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    detour_min DOUBLE PRECISION NOT NULL CHECK (detour_min >= 0),
    time_gap_min INTEGER NOT NULL CHECK (time_gap_min >= 0),
    pref_score DOUBLE PRECISION NOT NULL CHECK (pref_score BETWEEN 0 AND 100),
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    rule_score DOUBLE PRECISION NOT NULL CHECK (rule_score BETWEEN 0 AND 100),
    accepted BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS match_feedback_passenger_created_idx
    ON public.match_feedback (passenger_id, created_at DESC);

ALTER TABLE public.match_feedback ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON public.match_feedback TO authenticated;
GRANT UPDATE (accepted) ON public.match_feedback TO authenticated;

DROP POLICY IF EXISTS match_feedback_select_own ON public.match_feedback;
CREATE POLICY match_feedback_select_own
    ON public.match_feedback FOR SELECT TO authenticated
    USING (passenger_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS match_feedback_insert_own ON public.match_feedback;
CREATE POLICY match_feedback_insert_own
    ON public.match_feedback FOR INSERT TO authenticated
    WITH CHECK (
        passenger_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.rides r
            WHERE r.id = ride_id AND r.status = 'available'
        )
    );

DROP POLICY IF EXISTS match_feedback_update_own ON public.match_feedback;
CREATE POLICY match_feedback_update_own
    ON public.match_feedback FOR UPDATE TO authenticated
    USING (passenger_id = (SELECT auth.uid()))
    WITH CHECK (passenger_id = (SELECT auth.uid()));

CREATE TABLE IF NOT EXISTS public.safety_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE CHECK (length(token) BETWEEN 32 AND 128),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS safety_shares_booking_idx
    ON public.safety_shares (booking_id);

ALTER TABLE public.safety_shares ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE ON public.safety_shares TO authenticated;

DROP POLICY IF EXISTS safety_shares_select_booking_owner ON public.safety_shares;
CREATE POLICY safety_shares_select_booking_owner
    ON public.safety_shares FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id AND b.passenger_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS safety_shares_insert_confirmed_booking ON public.safety_shares;
CREATE POLICY safety_shares_insert_confirmed_booking
    ON public.safety_shares FOR INSERT TO authenticated
    WITH CHECK (
        is_active
        AND expires_at > now()
        AND expires_at <= now() + interval '24 hours'
        AND EXISTS (
            SELECT 1
            FROM public.bookings b
            JOIN public.rides r ON r.id = b.ride_id
            WHERE b.id = booking_id
              AND b.passenger_id = (SELECT auth.uid())
              AND b.status = 'confirmed'
              AND r.status = 'in_progress'
        )
    );

DROP POLICY IF EXISTS safety_shares_update_booking_owner ON public.safety_shares;
CREATE POLICY safety_shares_update_booking_owner
    ON public.safety_shares FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id AND b.passenger_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        expires_at > now()
        AND EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id AND b.passenger_id = (SELECT auth.uid())
        )
    );

CREATE TABLE IF NOT EXISTS public.ride_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lat DOUBLE PRECISION NOT NULL CHECK (lat BETWEEN -90 AND 90),
    lng DOUBLE PRECISION NOT NULL CHECK (lng BETWEEN -180 AND 180),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ride_positions_latest_idx
    ON public.ride_positions (ride_id, user_id, recorded_at DESC);

ALTER TABLE public.ride_positions ENABLE ROW LEVEL SECURITY;
GRANT SELECT, DELETE ON public.ride_positions TO authenticated;
GRANT INSERT (ride_id, user_id, lat, lng)
    ON public.ride_positions TO authenticated;

DROP POLICY IF EXISTS ride_positions_insert_active_participant ON public.ride_positions;
CREATE POLICY ride_positions_insert_active_participant
    ON public.ride_positions FOR INSERT TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND
        EXISTS (
            SELECT 1
            FROM public.rides r
            WHERE r.id = ride_id
              AND r.status = 'in_progress'
              AND (
                  r.driver_id = (SELECT auth.uid())
                  OR EXISTS (
                      SELECT 1 FROM public.bookings b
                      WHERE b.ride_id = r.id
                        AND b.passenger_id = (SELECT auth.uid())
                        AND b.status = 'confirmed'
                  )
              )
        )
    );

DROP POLICY IF EXISTS ride_positions_select_participants ON public.ride_positions;
CREATE POLICY ride_positions_select_participants
    ON public.ride_positions FOR SELECT TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1
            FROM public.rides r
            WHERE r.id = ride_id
              AND (
                  r.driver_id = (SELECT auth.uid())
                  OR EXISTS (
                      SELECT 1 FROM public.bookings b
                      WHERE b.ride_id = r.id
                        AND b.passenger_id = (SELECT auth.uid())
                        AND b.status = 'confirmed'
                  )
              )
        )
    );

DROP POLICY IF EXISTS ride_positions_delete_participant ON public.ride_positions;
CREATE POLICY ride_positions_delete_participant
    ON public.ride_positions FOR DELETE TO authenticated
    USING (
        user_id = (SELECT auth.uid())
    );

CREATE OR REPLACE FUNCTION public.clear_revoked_safety_position()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_ride_id UUID;
    v_passenger_id UUID;
BEGIN
    IF OLD.is_active AND NOT NEW.is_active THEN
        SELECT b.ride_id, b.passenger_id
        INTO v_ride_id, v_passenger_id
        FROM public.bookings b
        WHERE b.id = NEW.booking_id;

        DELETE FROM public.ride_positions rp
        WHERE rp.ride_id = v_ride_id
          AND rp.user_id = v_passenger_id
          AND NOT EXISTS (
              SELECT 1
              FROM public.safety_shares s
              JOIN public.bookings b ON b.id = s.booking_id
              WHERE b.ride_id = v_ride_id
                AND b.passenger_id = v_passenger_id
                AND s.id <> NEW.id
                AND s.is_active
                AND s.expires_at > now()
          );
    END IF;
    RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.clear_revoked_safety_position() FROM PUBLIC;
DROP TRIGGER IF EXISTS clear_revoked_safety_position ON public.safety_shares;
CREATE TRIGGER clear_revoked_safety_position
    AFTER UPDATE OF is_active ON public.safety_shares
    FOR EACH ROW
    EXECUTE FUNCTION public.clear_revoked_safety_position();

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
          AND rp.user_id = b.passenger_id
        ORDER BY rp.recorded_at DESC, rp.id DESC
        LIMIT 1
    ) p ON TRUE
    WHERE s.token = $1
      AND s.is_active
      AND s.expires_at > now()
      AND b.status = 'confirmed'
      AND r.status = 'in_progress'
    LIMIT 1;
$function$;

REVOKE ALL ON FUNCTION public.get_shared_position(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_shared_position(TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.clear_ended_safety_tracking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
    IF OLD.status = 'in_progress' AND NEW.status <> 'in_progress' THEN
        UPDATE public.safety_shares s
        SET is_active = FALSE
        FROM public.bookings b
        WHERE b.id = s.booking_id AND b.ride_id = NEW.id;
        DELETE FROM public.ride_positions WHERE ride_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.clear_ended_safety_tracking() FROM PUBLIC;
DROP TRIGGER IF EXISTS clear_ended_safety_tracking ON public.rides;
CREATE TRIGGER clear_ended_safety_tracking
    AFTER UPDATE OF status ON public.rides
    FOR EACH ROW
    EXECUTE FUNCTION public.clear_ended_safety_tracking();

NOTIFY pgrst, 'reload schema';
COMMIT;
