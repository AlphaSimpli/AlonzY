ALTER TABLE public.safety_shares
    ADD COLUMN IF NOT EXISTS consent_given_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS stopped_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION public.track_safety_share_state()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
    IF TG_OP = 'UPDATE'
       AND NEW.consent_given_at IS DISTINCT FROM OLD.consent_given_at THEN
        RAISE EXCEPTION 'Safety-share consent evidence is immutable';
    END IF;

    IF NEW.is_active THEN
        NEW.stopped_at := NULL;
    ELSIF TG_OP = 'INSERT' THEN
        NEW.stopped_at := COALESCE(NEW.stopped_at, now());
    ELSIF OLD.is_active THEN
        NEW.stopped_at := now();
    END IF;

    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS track_safety_share_state ON public.safety_shares;
CREATE TRIGGER track_safety_share_state
    BEFORE INSERT OR UPDATE
    ON public.safety_shares
    FOR EACH ROW
    EXECUTE FUNCTION public.track_safety_share_state();

DROP POLICY IF EXISTS safety_shares_insert_confirmed_booking
    ON public.safety_shares;
CREATE POLICY safety_shares_insert_confirmed_booking
    ON public.safety_shares FOR INSERT TO authenticated
    WITH CHECK (
        is_active
        AND consent_given_at IS NOT NULL
        AND consent_given_at <= now()
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

DROP POLICY IF EXISTS safety_shares_update_booking_owner
    ON public.safety_shares;
CREATE POLICY safety_shares_update_booking_owner
    ON public.safety_shares FOR UPDATE TO authenticated
    USING (
        is_active
        AND EXISTS (
            SELECT 1
            FROM public.bookings b
            WHERE b.id = booking_id
              AND b.passenger_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        NOT is_active
        AND EXISTS (
            SELECT 1
            FROM public.bookings b
            WHERE b.id = booking_id
              AND b.passenger_id = (SELECT auth.uid())
        )
    );

REVOKE UPDATE ON public.safety_shares FROM authenticated;
GRANT UPDATE (is_active) ON public.safety_shares TO authenticated;

CREATE OR REPLACE FUNCTION public.purge_expired_ride_positions()
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
    v_deleted BIGINT;
BEGIN
    WITH stale_rides AS (
        SELECT DISTINCT b.ride_id
        FROM public.safety_shares s
        JOIN public.bookings b ON b.id = s.booking_id
        WHERE s.expires_at <= now()
           OR (
               NOT s.is_active
               AND s.stopped_at <= now() - interval '15 minutes'
           )
    )
    DELETE FROM public.ride_positions rp
    USING stale_rides stale
    WHERE rp.ride_id = stale.ride_id
      AND NOT EXISTS (
          SELECT 1
          FROM public.safety_shares active_share
          JOIN public.bookings active_booking
            ON active_booking.id = active_share.booking_id
          WHERE active_booking.ride_id = rp.ride_id
            AND active_share.is_active
            AND active_share.expires_at > now()
      );

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$function$;

REVOKE ALL ON FUNCTION public.purge_expired_ride_positions()
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.purge_expired_ride_positions()
    TO service_role;

DO $schedule$
DECLARE
    v_job_id BIGINT;
    v_unscheduled BOOLEAN;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_available_extensions
        WHERE name = 'pg_cron'
    ) THEN
        BEGIN
            EXECUTE 'CREATE EXTENSION IF NOT EXISTS pg_cron';
        EXCEPTION
            WHEN insufficient_privilege
              OR feature_not_supported
              OR object_not_in_prerequisite_state
              OR undefined_file THEN
                RAISE NOTICE
                    'pg_cron could not be enabled; schedule purge_expired_ride_positions() manually';
        END;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_extension
        WHERE extname = 'pg_cron'
    ) THEN
        BEGIN
            FOR v_job_id IN EXECUTE
                'SELECT jobid FROM cron.job WHERE jobname = $1'
                USING 'alonzy-purge-expired-ride-positions'
            LOOP
                EXECUTE 'SELECT cron.unschedule($1)'
                    INTO v_unscheduled
                    USING v_job_id;
            END LOOP;

            EXECUTE 'SELECT cron.schedule($1, $2, $3)'
                INTO v_job_id
                USING
                    'alonzy-purge-expired-ride-positions',
                    '*/15 * * * *',
                    'SELECT public.purge_expired_ride_positions();';
        EXCEPTION
            WHEN insufficient_privilege OR undefined_table THEN
                RAISE NOTICE
                    'Could not schedule pg_cron purge; schedule purge_expired_ride_positions() manually';
        END;
    ELSE
        RAISE NOTICE
            'pg_cron is unavailable; schedule purge_expired_ride_positions() manually';
    END IF;
END;
$schedule$;
