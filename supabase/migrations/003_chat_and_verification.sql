-- ============================================================================
-- 003_CHAT_AND_VERIFICATION.sql
--
-- Feature-parity upgrade:
--   1. Multi-level user verification (email, phone, government ID) with
--      status synced from auth.users
--   2. Vehicle year on profiles and rides
--   3. Verified/completed ride count on profiles
--   4. Instant vs. approval-based booking (pending/rejected booking states,
--      seat holds released on rejection)
--   5. Real-time driver-passenger chat (conversations + messages, RLS)
-- ============================================================================

-- ============================================================================
-- USER VERIFICATION
-- ============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS govt_id_status TEXT NOT NULL DEFAULT 'none'
    CHECK (govt_id_status IN ('none', 'pending', 'verified')),
  ADD COLUMN IF NOT EXISTS govt_id_verified_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS verified_rides INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS vehicle_year INTEGER;

-- Keep verification flags in sync with the auth.users record.
CREATE OR REPLACE FUNCTION sync_verification_status()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET email_verified = NEW.email_confirmed_at IS NOT NULL,
      phone_verified = NEW.phone_confirmed_at IS NOT NULL
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS sync_verification_status_on_auth_user ON auth.users;
CREATE TRIGGER sync_verification_status_on_auth_user
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_verification_status();

-- Backfill flags for users created before this migration.
UPDATE public.profiles p
SET email_verified = (u.email_confirmed_at IS NOT NULL),
    phone_verified = (u.phone_confirmed_at IS NOT NULL)
FROM auth.users u
WHERE p.id = u.id;

-- Count completed trips per driver (a booking counts once when it is
-- transitioned to 'completed').
CREATE OR REPLACE FUNCTION increment_verified_rides()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status <> 'completed' AND NEW.status = 'completed' THEN
    UPDATE public.profiles
    SET verified_rides = verified_rides + 1
    WHERE id = (SELECT driver_id FROM public.rides WHERE id = NEW.ride_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS increment_verified_rides_on_complete ON public.bookings;
CREATE TRIGGER increment_verified_rides_on_complete
  AFTER UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION increment_verified_rides();

-- ============================================================================
-- RIDES: vehicle year + booking mode
-- ============================================================================

ALTER TABLE public.rides
  ADD COLUMN IF NOT EXISTS vehicle_year INTEGER,
  ADD COLUMN IF NOT EXISTS instant_booking BOOLEAN NOT NULL DEFAULT FALSE;

-- ============================================================================
-- BOOKINGS: approval lifecycle
-- ============================================================================

-- Allow 'pending' (awaiting driver approval) and 'rejected' states.
ALTER TABLE public.bookings
  DROP CONSTRAINT IF EXISTS bookings_status_check,
  ADD CONSTRAINT bookings_status_check
    CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'rejected'));

-- Pending bookings hold seats; rejection must release them like cancellation.
CREATE OR REPLACE FUNCTION restore_booking_seats()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status <> 'cancelled' AND NEW.status = 'cancelled'
     OR OLD.status <> 'rejected' AND NEW.status = 'rejected' THEN
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

-- Seat capacity check must ignore rejected bookings.
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
    AND status NOT IN ('cancelled', 'rejected')
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

-- ============================================================================
-- CHAT
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
  passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message TEXT,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  passenger_last_read_at TIMESTAMP WITH TIME ZONE,
  driver_last_read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (ride_id, passenger_id)
);

CREATE INDEX IF NOT EXISTS idx_conversations_passenger
  ON public.conversations(passenger_id);
CREATE INDEX IF NOT EXISTS idx_conversations_driver
  ON public.conversations(driver_id);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation
  ON public.chat_messages(conversation_id, created_at);

-- Keep the conversation preview in sync with the latest message.
CREATE OR REPLACE FUNCTION touch_conversation()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations
  SET last_message = NEW.message,
      last_message_at = NEW.created_at,
      last_sender_id = NEW.sender_id
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS touch_conversation_on_message ON public.chat_messages;
CREATE TRIGGER touch_conversation_on_message
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION touch_conversation();

-- ----------------------------------------------------------------------------
-- RLS: conversations are private between the two participants.
-- ----------------------------------------------------------------------------
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can view conversations"
  ON public.conversations
  FOR SELECT
  USING (auth.uid() = passenger_id OR auth.uid() = driver_id);

CREATE POLICY "Participants can create conversations"
  ON public.conversations
  FOR INSERT
  WITH CHECK (auth.uid() = passenger_id OR auth.uid() = driver_id);

CREATE POLICY "Participants can update conversation reads"
  ON public.conversations
  FOR UPDATE
  USING (auth.uid() = passenger_id OR auth.uid() = driver_id)
  WITH CHECK (auth.uid() = passenger_id OR auth.uid() = driver_id);

CREATE POLICY "Participants can view messages"
  ON public.chat_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (auth.uid() = c.passenger_id OR auth.uid() = c.driver_id)
    )
  );

CREATE POLICY "Participants can send messages"
  ON public.chat_messages
  FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (auth.uid() = c.passenger_id OR auth.uid() = c.driver_id)
    )
  );

-- ----------------------------------------------------------------------------
-- Realtime: only messages and conversation updates flow to clients.
-- ----------------------------------------------------------------------------
ALTER PUBLICATION supabase_realtime
  ADD TABLE public.chat_messages;

ALTER PUBLICATION supabase_realtime
  ADD TABLE public.conversations;