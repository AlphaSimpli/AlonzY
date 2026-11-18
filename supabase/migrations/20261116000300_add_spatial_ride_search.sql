-- AlonzY : pre-filtrage spatial des offres avant OSRM et classement.
-- Prerequis : 20261116000200_add_ride_geography.sql.
-- Aucun trajet ni aucune politique RLS ne sont modifies.
-- Ce filtre compare les points de depart, pas les itineraires routiers.
-- Documentation :
-- https://postgis.net/docs/en/ST_DWithin.html
-- https://supabase.com/docs/guides/database/functions

BEGIN;

-- Refuser une installation sur une table dont la RLS serait desactivee.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class
        WHERE oid = 'public.rides'::regclass
          AND relrowsecurity
    ) THEN
        RAISE EXCEPTION 'La RLS doit etre active sur public.rides.';
    END IF;
END;
$$;

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
            MESSAGE = 'Coordonnees de depart invalides.';
    END IF;

    IF p_departure_from IS NULL OR p_departure_until IS NULL
       OR NOT pg_catalog.isfinite(p_departure_from)
       OR NOT pg_catalog.isfinite(p_departure_until)
       OR p_departure_until <= p_departure_from THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Fournir un debut et une fin de creneau valides.';
    END IF;

    -- Choix initial configurable : 10 km par defaut, plafond de 100 km.
    IF p_radius_m IS NULL OR NOT (p_radius_m > 0 AND p_radius_m <= 100000) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Le rayon doit etre strictement positif et au plus 100000 metres.';
    END IF;

    IF p_min_seats IS NULL OR p_min_seats < 1 THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Le nombre de places demandees doit etre au moins 1.';
    END IF;

    IF p_max_price IS NOT NULL AND NOT (
        p_max_price >= 0 AND p_max_price < 'Infinity'::numeric
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'Le prix maximal doit etre un nombre fini positif ou nul.';
    END IF;

    IF p_limit IS NULL OR NOT (p_limit BETWEEN 1 AND 500) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'La limite de resultats doit etre comprise entre 1 et 500.';
    END IF;

    -- ST_MakePoint attend la longitude avant la latitude.
    v_origin := extensions.ST_SetSRID(
        extensions.ST_MakePoint(p_origin_lng, p_origin_lat), 4326
    )::extensions.geography;

    RETURN QUERY
    SELECT r.*
    FROM public.rides AS r
    WHERE r.status = 'available'
      AND r.available_seats >= p_min_seats
      -- Intervalle semi-ouvert : debut inclus, fin exclue.
      AND r.departure_time >= p_departure_from
      AND r.departure_time < p_departure_until
      AND (p_max_price IS NULL OR r.price_per_seat <= p_max_price)
      AND r.origin_geog IS NOT NULL
      AND extensions.ST_DWithin(r.origin_geog, v_origin, p_radius_m)
    -- Ordre preliminaire seulement : OSRM et le score viennent ensuite.
    ORDER BY extensions.ST_Distance(r.origin_geog, v_origin),
             r.departure_time,
             r.id
    LIMIT p_limit;
END;
$function$;

COMMENT ON FUNCTION public.search_ride_candidates(
    double precision, double precision, timestamptz, timestamptz,
    double precision, integer, numeric, integer
) IS 'Pre-filtre origine/date/places/prix. SECURITY INVOKER : conserve les permissions et la RLS de l''appelant. Pas de calcul de detour routier.';

-- Pas de droit d'execution implicite pour PUBLIC ni pour les visiteurs anonymes.
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

-- Verification de structure et de droits, pas encore un test fonctionnel.
-- Attendu : une ligne ; security_definer=false ;
-- executable_connecte=true ; executable_anonyme=false ; rls_active=true.
SELECT
    p.proname AS fonction,
    p.prosecdef AS security_definer,
    pg_catalog.has_function_privilege(
        'authenticated', p.oid, 'EXECUTE'
    ) AS executable_connecte,
    pg_catalog.has_function_privilege(
        'anon', p.oid, 'EXECUTE'
    ) AS executable_anonyme,
    (
        SELECT c.relrowsecurity
        FROM pg_catalog.pg_class AS c
        WHERE c.oid = 'public.rides'::regclass
    ) AS rls_active
FROM pg_catalog.pg_proc AS p
JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'search_ride_candidates'
  AND p.pronargs = 8;