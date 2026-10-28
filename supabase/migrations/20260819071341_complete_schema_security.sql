CREATE OR REPLACE FUNCTION public.create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO public.profiles (id, email, phone)
	VALUES (NEW.id, NEW.email, NEW.phone)
	ON CONFLICT (id) DO NOTHING;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
	AFTER INSERT ON auth.users
	FOR EACH ROW EXECUTE FUNCTION public.create_profile_for_new_user();

DO $$
BEGIN
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_select_authenticated') THEN
		CREATE POLICY profiles_select_authenticated ON public.profiles FOR SELECT
			USING (auth.uid() IS NOT NULL);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_insert_own') THEN
		CREATE POLICY profiles_insert_own ON public.profiles FOR INSERT
			WITH CHECK (auth.uid() = id);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'profiles_update_own') THEN
		CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE
			USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'bookings_select_participant') THEN
		CREATE POLICY bookings_select_participant ON public.bookings FOR SELECT
			USING (auth.uid() = passenger_id OR EXISTS (
				SELECT 1 FROM public.rides r WHERE r.id = ride_id AND r.driver_id = auth.uid()
			));
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'bookings_insert_passenger') THEN
		CREATE POLICY bookings_insert_passenger ON public.bookings FOR INSERT
			WITH CHECK (auth.uid() = passenger_id);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'bookings_update_participant') THEN
		CREATE POLICY bookings_update_participant ON public.bookings FOR UPDATE
			USING (auth.uid() = passenger_id OR EXISTS (
				SELECT 1 FROM public.rides r WHERE r.id = ride_id AND r.driver_id = auth.uid()
			));
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'reviews_select_authenticated') THEN
		CREATE POLICY reviews_select_authenticated ON public.reviews FOR SELECT
			USING (auth.uid() IS NOT NULL);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'reviews_insert_reviewer') THEN
		CREATE POLICY reviews_insert_reviewer ON public.reviews FOR INSERT
			WITH CHECK (auth.uid() = reviewer_id);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conversations_select_participant') THEN
		CREATE POLICY conversations_select_participant ON public.conversations FOR SELECT
			USING (auth.uid() = passenger_id OR auth.uid() = driver_id);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conversations_insert_participant') THEN
		CREATE POLICY conversations_insert_participant ON public.conversations FOR INSERT
			WITH CHECK (auth.uid() = passenger_id OR auth.uid() = driver_id);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'conversations_update_participant') THEN
		CREATE POLICY conversations_update_participant ON public.conversations FOR UPDATE
			USING (auth.uid() = passenger_id OR auth.uid() = driver_id)
			WITH CHECK (auth.uid() = passenger_id OR auth.uid() = driver_id);
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'chat_messages_select_participant') THEN
		CREATE POLICY chat_messages_select_participant ON public.chat_messages FOR SELECT
			USING (EXISTS (
				SELECT 1 FROM public.conversations c
				WHERE c.id = conversation_id AND (c.passenger_id = auth.uid() OR c.driver_id = auth.uid())
			));
	END IF;
	IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'chat_messages_insert_participant') THEN
		CREATE POLICY chat_messages_insert_participant ON public.chat_messages FOR INSERT
			WITH CHECK (auth.uid() = sender_id AND EXISTS (
				SELECT 1 FROM public.conversations c
				WHERE c.id = conversation_id AND (c.passenger_id = auth.uid() OR c.driver_id = auth.uid())
			));
	END IF;
END;
$$;

NOTIFY pgrst, 'reload schema';
