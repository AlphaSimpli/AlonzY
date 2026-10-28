ALTER TABLE public.rides
	ADD COLUMN IF NOT EXISTS instant_booking BOOLEAN DEFAULT false;

NOTIFY pgrst, 'reload schema';
