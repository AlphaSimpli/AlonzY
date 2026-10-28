ALTER TABLE public.rides
	ADD COLUMN IF NOT EXISTS origin_lat DOUBLE PRECISION,
	ADD COLUMN IF NOT EXISTS origin_lng DOUBLE PRECISION,
	ADD COLUMN IF NOT EXISTS destination_lat DOUBLE PRECISION,
	ADD COLUMN IF NOT EXISTS destination_lng DOUBLE PRECISION;

UPDATE public.rides
SET origin_lat = COALESCE(origin_lat, start_lat),
		origin_lng = COALESCE(origin_lng, start_lng),
		destination_lat = COALESCE(destination_lat, end_lat),
		destination_lng = COALESCE(destination_lng, end_lng)
WHERE origin_lat IS NULL
	 OR origin_lng IS NULL
	 OR destination_lat IS NULL
	 OR destination_lng IS NULL;

NOTIFY pgrst, 'reload schema';
