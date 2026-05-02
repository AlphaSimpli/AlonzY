# Supabase Flutter Ridesharing App - Implementation Guide

## ✅ What's Been Completed

### Phase 1: Authentication ✨
- ✅ **Fixed AuthGate** - Now uses `StreamBuilder` for real-time auth changes
- ✅ **Consolidated LoginPage** - Uses `AuthService` consistently
- ✅ **Fixed Signup Flow** - Proper navigation to `SignupPage`
- ✅ **Auto-profile Creation** - Creates user profile on signup

### Phase 2: Database & Schema 🗄️
- ✅ **Database Schema** - 3 main tables:
  - `profiles` - User information (drivers & passengers)
  - `rides` - Available rides posted by drivers
  - `bookings` - Passenger bookings for rides
  
- ✅ **RLS Policies** - Complete security:
  - Users can only see/edit their own data
  - Drivers manage their rides
  - Passengers manage their bookings
  
- ✅ **Automation** - Triggers to auto-update timestamps

### Phase 3: Frontend Services 🎨
- ✅ **AuthService** - Login, signup, logout, current user
- ✅ **DatabaseService** - Full CRUD for profiles, rides, bookings
- ✅ **HomePage** - Display available rides with booking UI
- ✅ **Enhanced UI** - Better forms, error handling, loading states

---

## 🚀 Getting Started

### Step 1: Deploy Database Schema

Go to [DATABASE_SETUP.md](DATABASE_SETUP.md) and follow one of these:

**Option A: Supabase Dashboard (Easy)**
1. Open https://supabase.com/dashboard → Your Project → SQL Editor
2. Create a new query
3. Copy & paste from `supabase/migrations/001_initial_schema.sql`
4. Click Run

**Option B: Supabase CLI (Advanced)**
```bash
cd supabase_flutter_app
supabase link --project-id <YOUR_PROJECT_ID>
supabase db push
```

### Step 2: Test Authentication

1. Run the app: `flutter run`
2. Click "Create account"
3. Enter email and password
4. Verify email (check spam folder)
5. Log back in

### Step 3: Create Test Rides (Admin Only)

**Option A: Supabase Dashboard**
1. Go to SQL Editor
2. Run this query to insert a test ride:

```sql
INSERT INTO public.rides (
  driver_id, start_location, start_lat, start_lng,
  end_location, end_lat, end_lng, departure_time,
  available_seats, price_per_seat, vehicle_type
) VALUES (
  'YOUR_USER_ID_HERE', 'Downtown', 40.7128, -74.0060,
  'Airport', 40.7700, -73.8740, 
  NOW() + INTERVAL '2 hours',
  3, 25.00, 'sedan'
);
```

3. Get your user ID from: SQL Editor → `SELECT id FROM public.profiles LIMIT 1;`

**Option B: Add Driver UI Screen (Todo)**
We need to create a "Post Ride" screen for drivers.

### Step 4: Book a Ride

1. Log in as passenger (different account)
2. See available rides on home page
3. Click "Book"
4. Select number of seats
5. Click "Book Now"

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry, AuthGate, Supabase init
├── screens/
│   ├── login_page.dart           # Login UI with AuthService
│   ├── signup_page.dart          # Signup UI with profile creation
│   └── home_page.dart            # Available rides list & booking
├── services/
│   ├── auth_service.dart         # Auth: signup, login, logout
│   └── database_service.dart     # Database: profiles, rides, bookings
supabase/
└── migrations/
    └── 001_initial_schema.sql    # Schema, RLS policies, triggers
DATABASE_SETUP.md                 # Database deployment guide
IMPLEMENTATION.md                 # This file
```

---

## 🎯 Key Features Implemented

### Authentication
```dart
final auth = AuthService();

// Signup
await auth.signUp(
  email: 'user@example.com',
  password: 'password',
  firstName: 'John',
  lastName: 'Doe',
);

// Login
await auth.signIn(
  email: 'user@example.com',
  password: 'password',
);

// Logout
await auth.signOut();
```

### Ride Management
```dart
final db = DatabaseService();

// Post a ride (Driver)
await db.createRide(
  startLocation: 'Downtown',
  startLat: 40.7128, startLng: -74.0060,
  endLocation: 'Airport',
  endLat: 40.7700, endLng: -73.8740,
  departureTime: DateTime.now().add(Duration(hours: 2)),
  availableSeats: 3,
  pricePerSeat: 25.00,
  vehicleType: 'sedan',
);

// Get available rides
final rides = await db.getAvailableRides();

// Book a ride (Passenger)
await db.createBooking(
  rideId: 'ride-id',
  seatsBooked: 2,
  totalPrice: 50.00,
);

// View my bookings
final bookings = await db.getMyBookings(userId);

// Cancel booking
await db.cancelBooking(bookingId, rideId);
```

---

## 🛠️ Architecture Overview

### Auth Flow
```
LoginPage ──signup──→ SignupPage ──signup/verify──→ profiles table
         ──login──→ AuthGate (StreamBuilder) ──authenticated──→ HomePage
```

### Database Flow
```
App ──DatabaseService──→ Supabase (PostgreSQL)
                          └─ RLS Policies enforce security
                          └─ Triggers auto-update timestamps
```

### Security (RLS)
- `auth.uid()` - Currently authenticated user
- Users only see rides they created or are available
- Bookings only visible to passenger or ride driver
- No direct INSERT into tables - must go through app

---

## 📋 Database Reference

### Profiles Table
```sql
id            UUID PRIMARY KEY (user ID)
email         TEXT UNIQUE
first_name    TEXT
last_name     TEXT
phone         TEXT
avatar_url    TEXT
is_driver     BOOLEAN (default: false)
is_passenger  BOOLEAN (default: true)
rating        DECIMAL (default: 5.0) ⭐
created_at    TIMESTAMP
updated_at    TIMESTAMP (auto-updated)
```

### Rides Table
```sql
id              UUID PRIMARY KEY
driver_id       UUID → profiles.id
start_location  TEXT
start_lat       DECIMAL (10,8)
start_lng       DECIMAL (11,8)
end_location    TEXT
end_lat         DECIMAL (10,8)
end_lng         DECIMAL (11,8)
departure_time  TIMESTAMP
available_seats INT
price_per_seat  DECIMAL (10,2)
vehicle_type    TEXT (sedan|suv|van)
vehicle_plate   TEXT
status          TEXT (available|in_progress|completed|cancelled)
notes           TEXT
created_at      TIMESTAMP
updated_at      TIMESTAMP (auto-updated)
```

### Bookings Table
```sql
id                UUID PRIMARY KEY
ride_id           UUID → rides.id
passenger_id      UUID → profiles.id
seats_booked      INT
total_price       DECIMAL (10,2)
pickup_location   TEXT
status            TEXT (confirmed|completed|cancelled)
payment_intent_id TEXT (for Stripe)
created_at        TIMESTAMP
updated_at        TIMESTAMP (auto-updated)
UNIQUE            (ride_id, passenger_id) - one booking per passenger per ride
```

---

## 🔄 Next Steps / Todo

### Phase 4: Driver Features 📝
- [ ] Create "Post Ride" screen
- [ ] View driver's posted rides
- [ ] Accept/reject bookings
- [ ] Mark ride as completed

### Phase 5: Payments 💳
- [ ] Integrate Stripe
- [ ] Create Supabase Edge Functions for payment processing
- [ ] Store payment intents in bookings table

### Phase 6: Notifications 🔔
- [ ] Send booking confirmation emails
- [ ] Push notifications for new bookings
- [ ] SMS updates

### Phase 7: Maps & Location 📍
- [ ] Google Maps integration
- [ ] Show ride routes
- [ ] Real-time driver location (if needed)
- [ ] Distance calculation

### Phase 8: Ratings & Reviews ⭐
- [ ] Rate passengers/drivers after trip
- [ ] Review system
- [ ] Block/report users

---

## 🐛 Troubleshooting

### "Permission denied" on any action
**Problem:** RLS policies not allowing the action
**Solution:** 
1. Check if user is authenticated: `print(supabase.auth.currentUser)`
2. Verify RLS policies in Supabase Dashboard → Tables → [Table] → Policies
3. Add more permissive policy if needed

### "Duplicate key value violates unique constraint"
**Problem:** Trying to insert duplicate email or ride+passenger booking
**Solution:**
1. Use `.maybeSingle()` or `.eq()` to check first
2. Handle existing records before insert

### Rides not showing up
**Problem:** 
1. No rides in database
2. RLS policy blocking SELECT
3. Status not 'available'
**Solution:**
1. Create test ride via SQL Editor
2. Check rides have `status = 'available'`
3. Check `departure_time` is in future

### Profile creation fails during signup
**Problem:** Foreign key constraint or email duplicate
**Solution:**
1. Ensure Supabase auth user was created first
2. Check profiles.email is unique
3. Add error logging to `AuthService.signUp()`

---

## 📚 Resources

- [Supabase Docs](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [PostgreSQL RLS](https://www.postgresql.org/docs/current/rls.html)
- [Flutter Form Best Practices](https://flutter.dev/docs/cookbook/forms)

---

## 💡 Tips & Best Practices

1. **Always check `if (mounted)` before setState** - Prevents crashes after navigation
2. **Use `.maybeSingle()` for optional queries** - Returns null if not found
3. **Handle null cases in UI** - Use `??` operator for default values
4. **Add loading states** - Better UX with spinners
5. **Log important actions** - Helps with debugging
6. **Test RLS policies** - Try actions as different users
7. **Use transactions for complex operations** - Ensure data consistency

---

## Questions?

Check the comments in code files or consult Supabase documentation. Happy coding! 🚀
