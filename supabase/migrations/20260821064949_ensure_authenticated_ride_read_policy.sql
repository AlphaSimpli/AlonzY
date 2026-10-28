DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1
		FROM pg_policies
		WHERE schemaname = 'public'
			AND tablename = 'rides'
			AND policyname = 'Allow authenticated read on rides'
	) THEN
		CREATE POLICY "Allow authenticated read on rides"
			ON public.rides
			FOR SELECT
			TO authenticated
			USING (true);
	END IF;
END;
$$;

NOTIFY pgrst, 'reload schema';
