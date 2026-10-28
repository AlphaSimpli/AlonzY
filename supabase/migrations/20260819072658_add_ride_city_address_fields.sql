ALTER TABLE public.rides
	ADD COLUMN IF NOT EXISTS origin_city TEXT,
	ADD COLUMN IF NOT EXISTS origin_address TEXT,
	ADD COLUMN IF NOT EXISTS destination_city TEXT,
	ADD COLUMN IF NOT EXISTS destination_address TEXT;

UPDATE public.rides
SET origin_address = COALESCE(origin_address, start_location),
		destination_address = COALESCE(destination_address, end_location),
		origin_city = COALESCE(origin_city, split_part(start_location, ',', 1)),
		destination_city = COALESCE(destination_city, split_part(end_location, ',', 1))
WHERE origin_city IS NULL
	 OR origin_address IS NULL
	 OR destination_city IS NULL
	 OR destination_address IS NULL;

NOTIFY pgrst, 'reload schema';
