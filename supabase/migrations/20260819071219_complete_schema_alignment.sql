-- Complete schema alignment for all Flutter Supabase models and services.

CREATE TABLE IF NOT EXISTS public.profiles (
	id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
	email TEXT,
	first_name TEXT,
	last_name TEXT,
	phone TEXT,
	avatar_url TEXT,
	is_driver BOOLEAN NOT NULL DEFAULT FALSE,
	is_passenger BOOLEAN NOT NULL DEFAULT TRUE,
	rating NUMERIC(3, 2) NOT NULL DEFAULT 5.0,
	bio TEXT,
	contact_preference TEXT NOT NULL DEFAULT 'email',
	email_verified BOOLEAN NOT NULL DEFAULT FALSE,
	phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
	govt_id_status TEXT NOT NULL DEFAULT 'none',
	govt_id_verified_at TIMESTAMPTZ,
	verified_rides INTEGER NOT NULL DEFAULT 0,
	vehicle_make TEXT,
	vehicle_model TEXT,
	vehicle_color TEXT,
	vehicle_plate TEXT,
	vehicle_year INTEGER,
	created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.profiles
	ADD COLUMN IF NOT EXISTS email TEXT,
	ADD COLUMN IF NOT EXISTS first_name TEXT,
	ADD COLUMN IF NOT EXISTS last_name TEXT,
	ADD COLUMN IF NOT EXISTS phone TEXT,
	ADD COLUMN IF NOT EXISTS avatar_url TEXT,
	ADD COLUMN IF NOT EXISTS is_driver BOOLEAN NOT NULL DEFAULT FALSE,
	ADD COLUMN IF NOT EXISTS is_passenger BOOLEAN NOT NULL DEFAULT TRUE,
	ADD COLUMN IF NOT EXISTS rating NUMERIC(3, 2) NOT NULL DEFAULT 5.0,
	ADD COLUMN IF NOT EXISTS bio TEXT,
	ADD COLUMN IF NOT EXISTS contact_preference TEXT NOT NULL DEFAULT 'email',
	ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE,
	ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
	ADD COLUMN IF NOT EXISTS govt_id_status TEXT NOT NULL DEFAULT 'none',
	ADD COLUMN IF NOT EXISTS govt_id_verified_at TIMESTAMPTZ,
	ADD COLUMN IF NOT EXISTS verified_rides INTEGER NOT NULL DEFAULT 0,
	ADD COLUMN IF NOT EXISTS vehicle_make TEXT,
	ADD COLUMN IF NOT EXISTS vehicle_model TEXT,
	ADD COLUMN IF NOT EXISTS vehicle_color TEXT,
	ADD COLUMN IF NOT EXISTS vehicle_plate TEXT,
	ADD COLUMN IF NOT EXISTS vehicle_year INTEGER,
	ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public.rides
	ADD COLUMN IF NOT EXISTS vehicle_year INTEGER,
	ADD COLUMN IF NOT EXISTS vehicle_make TEXT,
	ADD COLUMN IF NOT EXISTS vehicle_model TEXT,
	ADD COLUMN IF NOT EXISTS vehicle_color TEXT,
	ADD COLUMN IF NOT EXISTS pets_allowed BOOLEAN NOT NULL DEFAULT FALSE,
	ADD COLUMN IF NOT EXISTS luggage_policy TEXT NOT NULL DEFAULT 'moderate',
	ADD COLUMN IF NOT EXISTS instant_booking BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS public.bookings (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
	passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
	seats_booked INTEGER NOT NULL CHECK (seats_booked > 0),
	total_price NUMERIC(10, 2) NOT NULL,
	pickup_location TEXT,
	status TEXT NOT NULL DEFAULT 'pending',
	payment_intent_id TEXT,
	created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	UNIQUE (ride_id, passenger_id)
);

ALTER TABLE public.bookings
	ADD COLUMN IF NOT EXISTS pickup_location TEXT,
	ADD COLUMN IF NOT EXISTS payment_intent_id TEXT,
	ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending',
	ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

CREATE TABLE IF NOT EXISTS public.reviews (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
	reviewer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
	reviewee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
	rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
	comment TEXT,
	created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	UNIQUE (ride_id, reviewer_id)
);

CREATE TABLE IF NOT EXISTS public.conversations (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	ride_id UUID REFERENCES public.rides(id) ON DELETE CASCADE,
	passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
	driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
	last_message TEXT,
	last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	last_sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
	passenger_last_read_at TIMESTAMPTZ,
	driver_last_read_at TIMESTAMPTZ,
	created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
	UNIQUE (ride_id, passenger_id)
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
	sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
	message TEXT NOT NULL,
	created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bookings_ride_id ON public.bookings(ride_id);
CREATE INDEX IF NOT EXISTS idx_bookings_passenger_id ON public.bookings(passenger_id);
CREATE INDEX IF NOT EXISTS idx_reviews_reviewee_id ON public.reviews(reviewee_id);
CREATE INDEX IF NOT EXISTS idx_conversations_passenger ON public.conversations(passenger_id);
CREATE INDEX IF NOT EXISTS idx_conversations_driver ON public.conversations(driver_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation
	ON public.chat_messages(conversation_id, created_at);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

NOTIFY pgrst, 'reload schema';
