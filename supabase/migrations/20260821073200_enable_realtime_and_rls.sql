DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_policies
		WHERE schemaname = 'public' AND tablename = 'bookings'
			AND policyname = 'bookings_select_participant'
	) THEN
		CREATE POLICY bookings_select_participant ON public.bookings FOR SELECT
			USING (auth.uid() = passenger_id OR EXISTS (
				SELECT 1 FROM public.rides r
				WHERE r.id = bookings.ride_id AND r.driver_id = auth.uid()
			));
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_policies
		WHERE schemaname = 'public' AND tablename = 'chat_messages'
			AND policyname = 'chat_messages_select_participant'
	) THEN
		CREATE POLICY chat_messages_select_participant ON public.chat_messages FOR SELECT
			USING (EXISTS (
				SELECT 1 FROM public.conversations c
				WHERE c.id = chat_messages.conversation_id
					AND (c.passenger_id = auth.uid() OR c.driver_id = auth.uid())
			));
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_policies
		WHERE schemaname = 'public' AND tablename = 'chat_messages'
			AND policyname = 'chat_messages_insert_participant'
	) THEN
		CREATE POLICY chat_messages_insert_participant ON public.chat_messages FOR INSERT
			WITH CHECK (auth.uid() = sender_id AND EXISTS (
				SELECT 1 FROM public.conversations c
				WHERE c.id = chat_messages.conversation_id
					AND (c.passenger_id = auth.uid() OR c.driver_id = auth.uid())
			));
	END IF;
END;
$$;

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_publication_tables
		WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
	) THEN
		ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
	END IF;
	IF NOT EXISTS (
		SELECT 1 FROM pg_publication_tables
		WHERE pubname = 'supabase_realtime' AND tablename = 'conversations'
	) THEN
		ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
	END IF;
	IF NOT EXISTS (
		SELECT 1 FROM pg_publication_tables
		WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages'
	) THEN
		ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
	END IF;
END;
$$;

NOTIFY pgrst, 'reload schema';
