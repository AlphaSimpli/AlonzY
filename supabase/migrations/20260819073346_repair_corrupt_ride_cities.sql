UPDATE public.rides
SET origin_city = CASE
			WHEN COALESCE(origin_address, start_location) ILIKE '%Montréal%'
				OR COALESCE(origin_address, start_location) ILIKE '%Montreal%'
				THEN 'Montreal'
			WHEN COALESCE(origin_address, start_location) ILIKE '%Gatineau%'
				THEN 'Gatineau'
			WHEN COALESCE(origin_address, start_location) ILIKE '%San Francisco%'
				THEN 'San Francisco'
			ELSE NULL
		END
WHERE origin_city ~ '^[0-9]'
	 OR origin_city ~ '^-?[0-9]+([., ]|$)'
	 OR origin_city ~* '\m(street|st\.?|road|rd\.?|avenue|ave\.?|boulevard|blvd\.?)\M'
	 OR origin_city ILIKE '%Hôtel de Ville%';

UPDATE public.rides
SET destination_city = CASE
			WHEN COALESCE(destination_address, end_location) ILIKE '%Montréal%'
				OR COALESCE(destination_address, end_location) ILIKE '%Montreal%'
				THEN 'Montreal'
			WHEN COALESCE(destination_address, end_location) ILIKE '%Gatineau%'
				THEN 'Gatineau'
			WHEN COALESCE(destination_address, end_location) ILIKE '%San Francisco%'
				THEN 'San Francisco'
			ELSE NULL
		END
WHERE destination_city ~ '^[0-9]'
	 OR destination_city ~ '^-?[0-9]+([., ]|$)'
	 OR destination_city ~* '\m(street|st\.?|road|rd\.?|avenue|ave\.?|boulevard|blvd\.?)\M'
	 OR destination_city ILIKE '%Hôtel de Ville%';

NOTIFY pgrst, 'reload schema';
