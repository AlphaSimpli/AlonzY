CREATE OR REPLACE FUNCTION public.cancel_booking(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	booking_row public.bookings%ROWTYPE;
	ride_row public.rides%ROWTYPE;
	conversation_id UUID;
BEGIN
	SELECT * INTO booking_row
	FROM public.bookings
	WHERE id = p_booking_id
		AND passenger_id = auth.uid()
	FOR UPDATE;

	IF booking_row.id IS NULL THEN
		RAISE EXCEPTION 'Booking not found';
	END IF;

	IF booking_row.status = 'cancelled' THEN
		RETURN;
	END IF;

	SELECT * INTO ride_row
	FROM public.rides
	WHERE id = booking_row.ride_id
	FOR UPDATE;

	IF booking_row.status IN ('confirmed', 'accepted') THEN
		UPDATE public.rides
		SET available_seats = available_seats + booking_row.seats_booked
		WHERE id = booking_row.ride_id;
	END IF;

	UPDATE public.bookings
	SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
	WHERE id = p_booking_id;

	SELECT id INTO conversation_id
	FROM public.conversations
	WHERE ride_id = booking_row.ride_id
		AND passenger_id = booking_row.passenger_id;

	IF conversation_id IS NOT NULL THEN
		INSERT INTO public.chat_messages(conversation_id, sender_id, message)
		VALUES (conversation_id, auth.uid(), 'Booking cancelled.');
	END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cancel_booking(UUID) TO authenticated;
NOTIFY pgrst, 'reload schema';
