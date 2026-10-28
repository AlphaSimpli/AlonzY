INSERT INTO public.profiles (id, email, phone)
SELECT u.id, u.email, u.phone
FROM auth.users u
WHERE NOT EXISTS (
	SELECT 1 FROM public.profiles p WHERE p.id = u.id
)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.rides
	DROP CONSTRAINT IF EXISTS rides_driver_id_fkey;

ALTER TABLE public.rides
	ADD CONSTRAINT rides_driver_id_fkey
	FOREIGN KEY (driver_id)
	REFERENCES public.profiles(id)
	ON DELETE CASCADE;

NOTIFY pgrst, 'reload schema';
