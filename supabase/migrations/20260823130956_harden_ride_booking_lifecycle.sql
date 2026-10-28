CREATE OR REPLACE FUNCTION public.complete_ride(p_ride_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	ride_row public.rides%ROWTYPE;
BEGIN
	SELECT * INTO ride_row FROM public.rides WHERE id = p_ride_id FOR UPDATE;
	IF ride_row.id IS NULL OR ride_row.driver_id <> auth.uid() THEN
		RAISE EXCEPTION 'Only the ride driver can complete this ride';
	END IF;

	UPDATE public.rides
	SET status = 'completed', updated_at = CURRENT_TIMESTAMP
	WHERE id = p_ride_id;

	UPDATE public.bookings
	SET status = 'completed', updated_at = CURRENT_TIMESTAMP
	WHERE ride_id = p_ride_id AND status = 'confirmed';
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_booking_by_driver(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	booking_row public.bookings%ROWTYPE;
	ride_row public.rides%ROWTYPE;
BEGIN
	SELECT * INTO booking_row FROM public.bookings WHERE id = p_booking_id FOR UPDATE;
	SELECT * INTO ride_row FROM public.rides WHERE id = booking_row.ride_id FOR UPDATE;
	IF booking_row.id IS NULL OR ride_row.driver_id <> auth.uid() THEN
		RAISE EXCEPTION 'Only the ride driver can cancel this booking';
	END IF;
	IF booking_row.status = 'confirmed' THEN
		UPDATE public.rides
		SET available_seats = available_seats + booking_row.seats_booked
		WHERE id = booking_row.ride_id;
	END IF;
	UPDATE public.bookings
	SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
	WHERE id = p_booking_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_ride(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_booking_by_driver(UUID) TO authenticated;
NOTIFY pgrst, 'reload schema';
