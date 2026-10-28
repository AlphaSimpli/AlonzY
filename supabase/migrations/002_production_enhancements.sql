-- ============================================================================
-- 002_PRODUCTION_ENHANCEMENTS.sql
--
-- Production hardening and feature parity:
--   1. Profiles: bio, contact preference, nullable email (phone-only users)
--   2. Rides: vehicle make/model/colour, pets, luggage policy
--   3. Reviews + automatic driver rating aggregation
--   4. Server-side seat accounting (no client double-booking) with
--      overbooking protection
-- ============================================================================

-- ============================================================================
-- PROFILES ENHANCEMENTS
-- ============================================================================

-- Phone-only sign-in users have no email; make it optional.
ALTER TABLE public.profiles ALTER COLUMN email DROP NOT NULL;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS bio TEXT,
  ADD COLUMN IF NOT EXISTS contact_preference TEXT NOT NULL DEFAULT 'email'
    CHECK (contact_preference IN ('email', 'phone', 'in_app')),
  ADD COLUMN IF NOT EXISTS vehicle_make TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_model TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_color TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_plate TEXT;

-- Store the phone number on the profile when a phone-created user signs up.
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, phone, is_passenger, is_driver)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.phone,
    TRUE,
    FALSE
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RIDES ENHANCEMENTS (vehicle details + policies)
-- ============================================================================

ALTER TABLE public.rides
  ADD COLUMN IF NOT EXISTS vehicle_make TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_model TEXT,
  ADD COLUMN IF NOT EXISTS vehicle_color TEXT,
  ADD COLUMN IF NOT EXISTS pets_allowed BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS luggage_policy TEXT NOT NULL DEFAULT 'moderate'
    CHECK (luggage_policy IN ('none', 'small', 'moderate', 'large'));

-- ============================================================================
-- REVIEWS (driver ratings)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reviewee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (ride_id, reviewer_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_reviewee_id ON public.reviews(reviewee_id);
CREATE INDEX IF NOT EXISTS idx_reviews_ride_id ON public.reviews(ride_id);

-- Recompute the driver's average rating whenever a review is written.
CREATE OR REPLACE FUNCTION update_profile_rating()
RETURNS TRIGGER AS $$
DECLARE
  new_avg DECIMAL(3, 2);
BEGIN
  SELECT ROUND(AVG(rating)::numeric, 2) INTO new_avg
  FROM public.reviews
  WHERE reviewee_id = NEW.reviewee_id;

  UPDATE public.profiles
  SET rating = COALESCE(new_avg, 5.0)
  WHERE id = NEW.reviewee_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_rating_on_review ON public.reviews;
CREATE TRIGGER update_rating_on_review
  AFTER INSERT OR UPDATE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_rating();

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Ratings are visible to everyone (they are part of the driver's public info).
CREATE POLICY "Anyone can view reviews"
  ON public.reviews
  FOR SELECT
  USING (TRUE);

-- Only the reviewer can write their own review (one per ride).
CREATE POLICY "Reviewers can create reviews"
  ON public.reviews
  FOR INSERT
  WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Reviewers can update their own reviews"
  ON public.reviews
  FOR UPDATE
  USING (auth.uid() = reviewer_id)
  WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Reviewers can delete their own reviews"
  ON public.reviews
  FOR DELETE
  USING (auth.uid() = reviewer_id);

-- ============================================================================
-- SERVER-SIDE SEAT ACCOUNTING
-- ============================================================================

-- Reject any booking that would exceed the ride's available seats.
CREATE OR REPLACE FUNCTION prevent_overbooking()
RETURNS TRIGGER AS $$
DECLARE
  ride_seats INT;
  booked_seats INT;
BEGIN
  SELECT available_seats INTO ride_seats
  FROM public.rides
  WHERE id = NEW.ride_id
  FOR UPDATE;

  IF ride_seats IS NULL THEN
    RAISE EXCEPTION 'Ride does not exist';
  END IF;

  SELECT COALESCE(SUM(seats_booked), 0) INTO booked_seats
  FROM public.bookings
  WHERE ride_id = NEW.ride_id
    AND status <> 'cancelled'
    AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000');

  IF booked_seats + NEW.seats_booked > ride_seats THEN
    RAISE EXCEPTION 'Not enough seats available on this ride';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_bookings_capacity ON public.bookings;
CREATE TRIGGER check_bookings_capacity
  BEFORE INSERT OR UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION prevent_overbooking();

-- Decrement available seats when a booking is created.
CREATE OR REPLACE FUNCTION apply_booking_seats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.rides
  SET available_seats = available_seats - NEW.seats_booked
  WHERE id = NEW.ride_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS apply_booking_seats_on_insert ON public.bookings;
CREATE TRIGGER apply_booking_seats_on_insert
  AFTER INSERT ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION apply_booking_seats();

-- Restore seats when a booking is cancelled.
CREATE OR REPLACE FUNCTION restore_booking_seats()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status <> 'cancelled' AND NEW.status = 'cancelled' THEN
    UPDATE public.rides
    SET available_seats = available_seats + OLD.seats_booked
    WHERE id = NEW.ride_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS restore_booking_seats_on_cancel ON public.bookings;
CREATE TRIGGER restore_booking_seats_on_cancel
  AFTER UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION restore_booking_seats();
