UPDATE public.rides
SET origin_lat = COALESCE(origin_lat, start_lat),
		origin_lng = COALESCE(origin_lng, start_lng),
		destination_lat = COALESCE(destination_lat, end_lat),
		destination_lng = COALESCE(destination_lng, end_lng),
		origin_address = COALESCE(origin_address, start_location),
		destination_address = COALESCE(destination_address, end_location);

ALTER TABLE public.rides
	DROP COLUMN IF EXISTS start_lat,
	DROP COLUMN IF EXISTS start_lng,
	DROP COLUMN IF EXISTS end_lat,
	DROP COLUMN IF EXISTS end_lng,
	DROP COLUMN IF EXISTS start_location,
	DROP COLUMN IF EXISTS end_location;

NOTIFY pgrst, 'reload schema';
