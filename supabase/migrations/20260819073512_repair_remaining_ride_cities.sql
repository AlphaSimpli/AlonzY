UPDATE public.rides
SET destination_city = 'Niagara Falls'
WHERE destination_city = 'Fall'
	AND destination_address ILIKE '%Niagara Falls%';

NOTIFY pgrst, 'reload schema';
