-- AlonzY : points geographiques calcules et index spatiaux.
-- Prerequis : PostGIS installe dans le schema extensions.
-- Les quatre colonnes de coordonnees existantes sont conservees.
-- Documentation :
-- https://supabase.com/docs/guides/database/extensions/postgis
-- https://postgis.net/docs/ST_MakePoint.html

BEGIN;

-- Refuser les coordonnees hors limites, sans inventer de valeurs manquantes.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.rides'::regclass
          AND conname = 'rides_coordinate_ranges_check'
    ) THEN
        ALTER TABLE public.rides
        ADD CONSTRAINT rides_coordinate_ranges_check CHECK (
            (origin_lat IS NULL OR origin_lat BETWEEN -90 AND 90)
            AND (origin_lng IS NULL OR origin_lng BETWEEN -180 AND 180)
            AND (destination_lat IS NULL OR destination_lat BETWEEN -90 AND 90)
            AND (destination_lng IS NULL OR destination_lng BETWEEN -180 AND 180)
        );
    END IF;
END;
$$;

-- Attention : ST_MakePoint prend la longitude AVANT la latitude.
-- STORED calcule aussi les points des lignes deja presentes.
-- Les points sont recalcules lorsque les coordonnees sources changent.
ALTER TABLE public.rides
ADD COLUMN IF NOT EXISTS origin_geog extensions.geography(Point, 4326)
GENERATED ALWAYS AS (
    CASE
        WHEN origin_lat IS NOT NULL AND origin_lng IS NOT NULL
        THEN extensions.ST_SetSRID(
            extensions.ST_MakePoint(origin_lng, origin_lat), 4326
        )::extensions.geography
        ELSE NULL
    END
) STORED;

ALTER TABLE public.rides
ADD COLUMN IF NOT EXISTS destination_geog extensions.geography(Point, 4326)
GENERATED ALWAYS AS (
    CASE
        WHEN destination_lat IS NOT NULL AND destination_lng IS NOT NULL
        THEN extensions.ST_SetSRID(
            extensions.ST_MakePoint(destination_lng, destination_lat), 4326
        )::extensions.geography
        ELSE NULL
    END
) STORED;

CREATE INDEX IF NOT EXISTS rides_origin_geog_gist
    ON public.rides USING GIST (origin_geog);

CREATE INDEX IF NOT EXISTS rides_destination_geog_gist
    ON public.rides USING GIST (destination_geog);

NOTIFY pgrst, 'reload schema';

COMMIT;

-- Verification : deux lignes attendues avec is_generated = ALWAYS.
SELECT
    column_name,
    udt_schema,
    udt_name,
    is_generated
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'rides'
  AND column_name IN ('origin_geog', 'destination_geog')
ORDER BY column_name;
