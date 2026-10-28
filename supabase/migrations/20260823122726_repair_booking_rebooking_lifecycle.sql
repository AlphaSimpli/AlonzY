CREATE OR REPLACE FUNCTION public.create_booking_request(
	p_ride_id UUID,
	p_seats_booked INTEGER,
	p_total_price NUMERIC,
	p_pickup_location TEXT DEFAULT NULL
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
	ride_row public.rides%ROWTYPE;
	booking_row public.bookings%ROWTYPE;
	booking_id UUID;
	conversation_id UUID;
	booking_status TEXT;
	passenger_name TEXT;
BEGIN
	IF auth.uid() IS NULL THEN RAISE EXCEPTION 'User not authenticated'; END IF;
	IF p_seats_booked <= 0 THEN RAISE EXCEPTION 'Seats requested must be positive'; END IF;
	SELECT * INTO ride_row FROM public.rides WHERE id=p_ride_id FOR UPDATE;
	IF ride_row.id IS NULL THEN RAISE EXCEPTION 'Ride does not exist'; END IF;

	SELECT * INTO booking_row FROM public.bookings
	WHERE ride_id=p_ride_id AND passenger_id=auth.uid() FOR UPDATE;
	IF booking_row.id IS NOT NULL AND booking_row.status NOT IN ('cancelled','rejected') THEN
		RAISE EXCEPTION 'You already have an active booking for this ride';
	END IF;
	IF ride_row.available_seats < p_seats_booked THEN RAISE EXCEPTION 'Not enough seats available'; END IF;
	booking_status := CASE WHEN COALESCE(ride_row.instant_booking,FALSE) THEN 'confirmed' ELSE 'pending' END;

	IF booking_row.id IS NULL THEN
		INSERT INTO public.bookings(ride_id,passenger_id,seats_booked,total_price,status,pickup_location)
		VALUES(p_ride_id,auth.uid(),p_seats_booked,p_total_price,booking_status,p_pickup_location)
		RETURNING id INTO booking_id;
	ELSE
		UPDATE public.bookings SET seats_booked=p_seats_booked,total_price=p_total_price,
			status=booking_status,pickup_location=p_pickup_location,updated_at=CURRENT_TIMESTAMP
		WHERE id=booking_row.id RETURNING id INTO booking_id;
	END IF;
	IF booking_status='confirmed' THEN
		UPDATE public.rides SET available_seats=available_seats-p_seats_booked WHERE id=p_ride_id;
	END IF;

	SELECT id INTO conversation_id FROM public.conversations
	WHERE ride_id=p_ride_id AND passenger_id=auth.uid();
	IF conversation_id IS NULL THEN
		INSERT INTO public.conversations(ride_id,passenger_id,driver_id)
		VALUES(p_ride_id,auth.uid(),ride_row.driver_id) RETURNING id INTO conversation_id;
	END IF;
	SELECT COALESCE(NULLIF(TRIM(CONCAT_WS(' ',first_name,last_name)),''),'Passenger')
		INTO passenger_name FROM public.profiles WHERE id=auth.uid();
	INSERT INTO public.chat_messages(conversation_id,sender_id,message)
	VALUES(conversation_id,auth.uid(), 'Booking update: ' || passenger_name ||
		' requested ' || p_seats_booked || ' seat(s).');
	RETURN booking_id;
END; $$;

CREATE OR REPLACE FUNCTION public.cancel_booking(p_booking_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE b public.bookings%ROWTYPE; r public.rides%ROWTYPE;
BEGIN
	SELECT * INTO b FROM public.bookings WHERE id=p_booking_id FOR UPDATE;
	IF b.id IS NULL OR b.passenger_id <> auth.uid() THEN RAISE EXCEPTION 'Booking not found'; END IF;
	SELECT * INTO r FROM public.rides WHERE id=b.ride_id FOR UPDATE;
	IF b.status IN ('confirmed','accepted') THEN
		UPDATE public.rides SET available_seats=available_seats+b.seats_booked WHERE id=r.id;
	END IF;
	UPDATE public.bookings SET status='cancelled',updated_at=CURRENT_TIMESTAMP WHERE id=b.id;
END; $$;

GRANT EXECUTE ON FUNCTION public.create_booking_request(UUID,INTEGER,NUMERIC,TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_booking(UUID) TO authenticated;
NOTIFY pgrst, 'reload schema';
