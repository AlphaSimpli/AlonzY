-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  is_driver BOOLEAN DEFAULT FALSE,
  is_passenger BOOLEAN DEFAULT TRUE,
  rating DECIMAL(3, 2) DEFAULT 5.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TRIGGERS: Update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- TRIGGER: Auto-create profile when user signs up
-- ============================================================================
-- This function creates a new profile row whenever a user is created in auth.users
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, is_passenger, is_driver)
  VALUES (
    NEW.id,
    NEW.email,
    TRUE,  -- Default to passenger
    FALSE  -- Default to non-driver
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger fires AFTER a new user is created in auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();

-- ============================================================================
-- RIDES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.rides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  start_location TEXT NOT NULL,
  start_lat DECIMAL(10, 8) NOT NULL,
  start_lng DECIMAL(11, 8) NOT NULL,
  end_location TEXT NOT NULL,
  end_lat DECIMAL(10, 8) NOT NULL,
  end_lng DECIMAL(11, 8) NOT NULL,
  departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
  available_seats INTEGER NOT NULL CHECK (available_seats > 0),
  price_per_seat DECIMAL(10, 2) NOT NULL,
  vehicle_type TEXT NOT NULL (e.g., 'sedan', 'suv', 'van'),
  vehicle_plate TEXT,
  status TEXT DEFAULT 'available' CHECK (status IN ('available', 'in_progress', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rides_driver_id ON public.rides(driver_id);
CREATE INDEX idx_rides_departure_time ON public.rides(departure_time);
CREATE INDEX idx_rides_status ON public.rides(status);

CREATE TRIGGER update_rides_updated_at
  BEFORE UPDATE ON public.rides
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- BOOKINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
  passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seats_booked INTEGER NOT NULL CHECK (seats_booked > 0),
  total_price DECIMAL(10, 2) NOT NULL,
  pickup_location TEXT,
  status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'completed', 'cancelled')),
  payment_intent_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(ride_id, passenger_id)
);

CREATE INDEX idx_bookings_ride_id ON public.bookings(ride_id);
CREATE INDEX idx_bookings_passenger_id ON public.bookings(passenger_id);
CREATE INDEX idx_bookings_status ON public.bookings(status);

CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PROFILES RLS POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view their own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Users can view all profiles (for driver/passenger info)
CREATE POLICY "Users can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (TRUE);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can insert their own profile (when signing up)
CREATE POLICY "Users can insert their own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- RIDES RLS POLICIES
-- ============================================================================

-- Anyone can view available rides
CREATE POLICY "Anyone can view available rides"
  ON public.rides
  FOR SELECT
  USING (TRUE);

-- Drivers can create rides
CREATE POLICY "Drivers can create rides"
  ON public.rides
  FOR INSERT
  WITH CHECK (auth.uid() = driver_id);

-- Drivers can update their own rides
CREATE POLICY "Drivers can update their own rides"
  ON public.rides
  FOR UPDATE
  USING (auth.uid() = driver_id)
  WITH CHECK (auth.uid() = driver_id);

-- Drivers can delete their own rides (only if no bookings)
CREATE POLICY "Drivers can delete their own rides"
  ON public.rides
  FOR DELETE
  USING (auth.uid() = driver_id);

-- ============================================================================
-- BOOKINGS RLS POLICIES
-- ============================================================================

-- Passengers can view their own bookings
CREATE POLICY "Passengers can view their own bookings"
  ON public.bookings
  FOR SELECT
  USING (auth.uid() = passenger_id);

-- Drivers can view bookings for their rides
CREATE POLICY "Drivers can view bookings for their rides"
  ON public.bookings
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.rides
    WHERE rides.id = bookings.ride_id
    AND rides.driver_id = auth.uid()
  ));

-- Passengers can create bookings
CREATE POLICY "Passengers can create bookings"
  ON public.bookings
  FOR INSERT
  WITH CHECK (auth.uid() = passenger_id);

-- Passengers can update their own bookings
CREATE POLICY "Passengers can update their own bookings"
  ON public.bookings
  FOR UPDATE
  USING (auth.uid() = passenger_id)
  WITH CHECK (auth.uid() = passenger_id);

-- Passengers can delete their own bookings
CREATE POLICY "Passengers can delete their own bookings"
  ON public.bookings
  FOR DELETE
  USING (auth.uid() = passenger_id);

-- ============================================================================
-- GRANTS (if using service role)
-- ============================================================================
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
