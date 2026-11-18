-- Ensure the spatial ride search RPC exists in deployed Supabase projects.
-- PostgREST resolves RPC parameters by name; keep these names in sync with
-- DatabaseService._searchSpatialRides.

BEGIN;

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

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
            ADD COLUMN origin_geog extensions.geography(Point, 4326)
            GENERATED ALWAYS AS (
                CASE
                    WHEN origin_lat IS NOT NULL AND origin_lng IS NOT NULL
                    THEN extensions.ST_SetSRID(
                        extensions.ST_MakePoint(origin_lng, origin_lat), 4326
                    )::extensions.geography
                    ELSE NULL
                END
            ) STORED;
    ELSIF v_generated <> 'ALWAYS' THEN
        -- Older installations may have an ordinary geography column.
        ALTER TABLE public.rides
            ALTER COLUMN origin_geog TYPE extensions.geography(Point, 4326)
            USING origin_geog::extensions.geography;

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

CREATE OR REPLACE FUNCTION public.search_ride_candidates(
    p_origin_lat double precision,
    p_origin_lng double precision,
    p_departure_from timestamptz,
    p_departure_until timestamptz,
    p_radius_m double precision DEFAULT 10000,
    p_min_seats integer DEFAULT 1,
    p_max_price numeric DEFAULT NULL,
    p_limit integer DEFAULT 100
)
RETURNS SETOF public.rides
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
    v_origin extensions.geography;
BEGIN
    IF p_origin_lat IS NULL OR NOT (p_origin_lat BETWEEN -90 AND 90)
       OR p_origin_lng IS NULL OR NOT (p_origin_lng BETWEEN -180 AND 180) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Invalid origin coordinates.';
    END IF;

    IF p_departure_from IS NULL OR p_departure_until IS NULL
       OR NOT pg_catalog.isfinite(p_departure_from)
       OR NOT pg_catalog.isfinite(p_departure_until)
       OR p_departure_until <= p_departure_from THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Provide a valid departure time range.';
    END IF;

    IF p_radius_m IS NULL OR NOT (p_radius_m > 0 AND p_radius_m <= 100000) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Radius must be greater than 0 and at most 100000 metres.';
    END IF;

    IF p_min_seats IS NULL OR p_min_seats < 1 THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'At least one seat must be requested.';
    END IF;

    IF p_max_price IS NOT NULL AND NOT (
        p_max_price >= 0 AND p_max_price < 'Infinity'::numeric
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Maximum price must be finite and non-negative.';
    END IF;

    IF p_limit IS NULL OR NOT (p_limit BETWEEN 1 AND 500) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Result limit must be between 1 and 500.';
    END IF;

    v_origin := extensions.ST_SetSRID(
        extensions.ST_MakePoint(p_origin_lng, p_origin_lat), 4326
    )::extensions.geography;

    RETURN QUERY
    SELECT r.*
    FROM public.rides AS r
    WHERE r.status = 'available'
      AND r.available_seats >= p_min_seats
      AND r.departure_time >= p_departure_from
      AND r.departure_time < p_departure_until
      AND (p_max_price IS NULL OR r.price_per_seat <= p_max_price)
      AND r.origin_geog IS NOT NULL
      AND extensions.ST_DWithin(r.origin_geog, v_origin, p_radius_m)
    ORDER BY extensions.ST_Distance(r.origin_geog, v_origin),
             r.departure_time,
             r.id
    LIMIT p_limit;
END;
$function$;

COMMENT ON FUNCTION public.search_ride_candidates(
    double precision, double precision, timestamptz, timestamptz,
    double precision, integer, numeric, integer
) IS 'PostGIS prefilter for available rides by origin, departure window, seats and price. Honors caller RLS.';

REVOKE ALL ON FUNCTION public.search_ride_candidates(
    double precision, double precision, timestamptz, timestamptz,
    double precision, integer, numeric, integer
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.search_ride_candidates(
    double precision, double precision, timestamptz, timestamptz,
    double precision, integer, numeric, integer
) TO authenticated;

NOTIFY pgrst, 'reload schema';

COMMIT;
