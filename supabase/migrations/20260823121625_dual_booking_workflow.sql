CREATE OR REPLACE FUNCTION public.create_booking_request(
	p_ride_id UUID,
	p_seats_booked INTEGER,
	p_total_price NUMERIC,
	p_pickup_location TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	ride_row public.rides%ROWTYPE;
	booking_id UUID;
	conversation_id UUID;
	passenger_name TEXT;
	booking_status TEXT;
BEGIN
	IF auth.uid() IS NULL THEN RAISE EXCEPTION 'User not authenticated'; END IF;
	SELECT * INTO ride_row FROM public.rides WHERE id = p_ride_id FOR UPDATE;
	IF ride_row.id IS NULL THEN RAISE EXCEPTION 'Ride does not exist'; END IF;
	IF p_seats_booked <= 0 OR ride_row.available_seats < p_seats_booked THEN
		RAISE EXCEPTION 'Not enough seats available';
	END IF;

	booking_status := CASE WHEN COALESCE(ride_row.instant_booking, FALSE)
		THEN 'confirmed' ELSE 'pending' END;
	INSERT INTO public.bookings
		(ride_id, passenger_id, seats_booked, total_price, status, pickup_location)
	VALUES
		(p_ride_id, auth.uid(), p_seats_booked, p_total_price,
		 booking_status, p_pickup_location)
	RETURNING id INTO booking_id;

	IF booking_status = 'confirmed' THEN
		UPDATE public.rides
		SET available_seats = available_seats - p_seats_booked
		WHERE id = p_ride_id;
	END IF;

	SELECT CONCAT_WS(' ', first_name, last_name) INTO passenger_name
	FROM public.profiles WHERE id = auth.uid();
	INSERT INTO public.conversations (ride_id, passenger_id, driver_id)
	VALUES (p_ride_id, auth.uid(), ride_row.driver_id)
	ON CONFLICT (ride_id, passenger_id)
	DO UPDATE SET driver_id = EXCLUDED.driver_id
	RETURNING id INTO conversation_id;

	INSERT INTO public.chat_messages (conversation_id, sender_id, message)
	VALUES (conversation_id, auth.uid(), CASE WHEN booking_status = 'confirmed'
		THEN 'Booking automatically confirmed!'
		ELSE 'Booking request sent. Waiting for driver approval.' END);
	RETURN booking_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_booking_request(UUID, INTEGER, NUMERIC, TEXT)
	TO authenticated;

CREATE OR REPLACE FUNCTION public.approve_booking(p_booking_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE b public.bookings%ROWTYPE; r public.rides%ROWTYPE;
DECLARE c UUID;
BEGIN
	SELECT * INTO b FROM public.bookings WHERE id=p_booking_id FOR UPDATE;
	SELECT * INTO r FROM public.rides WHERE id=b.ride_id FOR UPDATE;
	IF b.id IS NULL OR r.driver_id <> auth.uid() OR b.status <> 'pending' THEN
		RAISE EXCEPTION 'Only a pending booking can be approved by its driver';
	END IF;
	IF r.available_seats < b.seats_booked THEN RAISE EXCEPTION 'Not enough seats available'; END IF;
	UPDATE public.rides SET available_seats=available_seats-b.seats_booked WHERE id=r.id;
	UPDATE public.bookings SET status='confirmed', updated_at=CURRENT_TIMESTAMP WHERE id=b.id;
	SELECT id INTO c FROM public.conversations WHERE ride_id=r.id AND passenger_id=b.passenger_id;
	INSERT INTO public.chat_messages(conversation_id,sender_id,message)
	VALUES(c, auth.uid(), 'Driver accepted your booking request!');
END; $$;

CREATE OR REPLACE FUNCTION public.reject_booking(p_booking_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE b public.bookings%ROWTYPE; r public.rides%ROWTYPE; c UUID;
BEGIN
	SELECT * INTO b FROM public.bookings WHERE id=p_booking_id FOR UPDATE;
	SELECT * INTO r FROM public.rides WHERE id=b.ride_id;
	IF b.id IS NULL OR r.driver_id <> auth.uid() OR b.status <> 'pending' THEN
		RAISE EXCEPTION 'Only a pending booking can be rejected by its driver';
	END IF;
	UPDATE public.bookings SET status='rejected', updated_at=CURRENT_TIMESTAMP WHERE id=b.id;
	SELECT id INTO c FROM public.conversations WHERE ride_id=r.id AND passenger_id=b.passenger_id;
	INSERT INTO public.chat_messages(conversation_id,sender_id,message)
	VALUES(c, auth.uid(), 'Driver declined the booking request.');
END; $$;

GRANT EXECUTE ON FUNCTION public.approve_booking(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_booking(UUID) TO authenticated;
NOTIFY pgrst, 'reload schema';
