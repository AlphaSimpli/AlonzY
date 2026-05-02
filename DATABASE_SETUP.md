# Supabase Database Setup Guide

## 🚀 How to Deploy the Database Schema

### Option 1: Using Supabase Dashboard (Recommended for Beginners)

1. **Go to Supabase Dashboard**
   - Navigate to https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "+ New Query"

3. **Run the Migration**
   - Copy the entire contents from [`supabase/migrations/001_initial_schema.sql`](supabase/migrations/001_initial_schema.sql)
   - Paste into the SQL editor
   - Click "Run" or press `Cmd+Enter`

4. **Verify**
   - Go to "Explore" > "Tables" to see the new tables:
     - `profiles`
     - `rides`
     - `bookings`

---

### Option 2: Using Supabase CLI (Recommended for Production)

**Prerequisites:**
```bash
npm install -g supabase@latest
```

**Steps:**
```bash
# Navigate to your project
cd supabase_flutter_app

# Initialize Supabase (if not already done)
supabase init

# Link to your Supabase project
supabase link --project-id <YOUR_PROJECT_ID>

# Push migrations
supabase db push
```

---

## 📊 Database Schema Overview

### Tables

#### 1. **profiles** (User Profiles)
- Stores user information (name, rating, avatar, etc.)
- Linked to Supabase `auth.users`
- Both drivers and passengers have profiles

```
id, email, first_name, last_name, phone, avatar_url, 
is_driver, is_passenger, rating, created_at, updated_at
```

#### 2. **rides** (Ride Listings)
- Created by drivers
- Contains route, time, and availability info
- Tracks booking status

```
id, driver_id, start_location, start_lat, start_lng,
end_location, end_lat, end_lng, departure_time,
available_seats, price_per_seat, vehicle_type, 
vehicle_plate, status, notes, created_at, updated_at
```

#### 3. **bookings** (Passenger Bookings)
- Created by passengers when booking a ride
- Tracks seats booked and payment info

```
id, ride_id, passenger_id, seats_booked, total_price,
pickup_location, status, payment_intent_id, 
created_at, updated_at
```

---

## 🔐 Row Level Security (RLS)

All tables have RLS enabled. Key policies:

| Table | Policy | Who | Action |
|-------|--------|-----|--------|
| **profiles** | Users can view all profiles | Anyone | SELECT |
| **profiles** | Users can update own | Owner | UPDATE |
| **rides** | Anyone can view available rides | Anyone | SELECT |
| **rides** | Drivers create/update/delete own | Driver | INSERT/UPDATE/DELETE |
| **bookings** | Passengers view own bookings | Passenger | SELECT |
| **bookings** | Drivers view bookings for their rides | Driver | SELECT |
| **bookings** | Passengers manage own | Passenger | INSERT/UPDATE/DELETE |

---

## ⚡ Triggers & Automation

### `update_updated_at_column()`
Automatically updates the `updated_at` timestamp whenever a row is modified.

Applied to:
- `profiles`
- `rides`
- `bookings`

---

## 🛠️ Using the Database Service in Flutter

### Basic Usage

```dart
import 'services/database_service.dart';

final db = DatabaseService();

// Create a ride
final rideId = await db.createRide(
  startLocation: 'Downtown Station',
  startLat: 40.7128,
  startLng: -74.0060,
  endLocation: 'Airport Terminal 1',
  endLat: 40.7700,
  endLng: -73.8740,
  departureTime: DateTime.now().add(Duration(hours: 2)),
  availableSeats: 3,
  pricePerSeat: 25.00,
  vehicleType: 'sedan',
  vehiclePlate: 'ABC-123',
);

// Get available rides
final rides = await db.getAvailableRides();

// Book a ride
final bookingId = await db.createBooking(
  rideId: rideId,
  seatsBooked: 2,
  totalPrice: 50.00,
  pickupLocation: 'Main Street',
);

// View my bookings
final myBookings = await db.getMyBookings(userId);

// Cancel booking
await db.cancelBooking(bookingId, rideId);
```

---

## 🔄 Real-Time Features (Coming Soon)

The `DatabaseService` includes real-time streams:

```dart
// Listen to available rides
db.watchAvailableRides().listen((rides) {
  print('Available rides updated: ${rides.length}');
});

// Listen to my bookings
db.watchMyBookings(userId).listen((bookings) {
  print('Bookings updated: ${bookings.length}');
});
```

---

## 📱 Next Steps

1. ✅ **Database Schema** - Deploy SQL migrations
2. 🚀 **Home Page** - Display available rides
3. 💳 **Payments** - Integrate Stripe with Edge Functions
4. 🔔 **Notifications** - Send booking confirmations
5. 📍 **Maps** - Show ride routes with Google Maps

---

## 🆘 Troubleshooting

### Issue: "Permission denied" on INSERT
**Solution:** Make sure the user is authenticated. Check that RLS policies allow the action.

### Issue: "Duplicate key value violates unique constraint"
**Solution:** The email or ride+passenger combination already exists.

### Issue: Available seats not updating after booking
**Solution:** Check that the `createBooking()` function updated the rides table. Add error logging.

---

## 📚 References
- [Supabase Docs](https://supabase.com/docs)
- [Flutter Supabase Plugin](https://pub.dev/packages/supabase_flutter)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
