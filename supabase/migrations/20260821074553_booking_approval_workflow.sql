CREATE OR REPLACE FUNCTION public.approve_booking(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
	booking_row public.bookings%ROWTYPE;
	ride_row public.rides%ROWTYPE;
BEGIN
	SELECT b.* INTO booking_row
	FROM public.bookings b
	WHERE b.id = p_booking_id
	FOR UPDATE;

	IF booking_row.id IS NULL THEN
		RAISE EXCEPTION 'Booking does not exist';
	END IF;

	SELECT r.* INTO ride_row
	FROM public.rides r
	WHERE r.id = booking_row.ride_id
	FOR UPDATE;

	IF ride_row.driver_id <> auth.uid() THEN
		RAISE EXCEPTION 'Only the ride driver can approve this booking';
	END IF;
	IF booking_row.status <> 'pending' THEN
		RAISE EXCEPTION 'Only pending bookings can be approved';
	END IF;
	IF ride_row.available_seats < booking_row.seats_booked THEN
		RAISE EXCEPTION 'Not enough seats available';
	END IF;

	UPDATE public.rides
	SET available_seats = available_seats - booking_row.seats_booked
	WHERE id = booking_row.ride_id;

	UPDATE public.bookings
	SET status = 'confirmed', updated_at = CURRENT_TIMESTAMP
	WHERE id = p_booking_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_booking(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
	UPDATE public.bookings b
	SET status = 'rejected', updated_at = CURRENT_TIMESTAMP
	FROM public.rides r
	WHERE b.id = p_booking_id
		AND r.id = b.ride_id
		AND r.driver_id = auth.uid()
		AND b.status = 'pending';

	IF NOT FOUND THEN
		RAISE EXCEPTION 'Only the ride driver can reject a pending booking';
	END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_booking(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_booking(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
