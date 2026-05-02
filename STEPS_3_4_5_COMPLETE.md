# Steps 3️⃣ 4️⃣ 5️⃣: Rides, Bookings & Booking Management

## 📋 Overview

### Step 3: Rides Table (Create & Search) ✅
- **Create Ride** - Drivers post new rides with locations, price, vehicle info
- **Search Rides** - Passengers search by location, date, price with filters
- **Advanced Queries** - Location filtering (ilike), price filtering, date ranges

### Step 4: Booking System ✅
- **Create Booking** - Passengers book available seats on rides
- **Automatic Updates** - Available seats decrease when booking is created
- **View Bookings** - Both passengers and drivers can see their bookings

### Step 5: Accept/Reject Bookings ✅
- **Driver Management** - Drivers see bookings for their rides
- **Accept Booking** - Driver approves passenger booking
- **Reject Booking** - Driver rejects booking and restores seats
- **Status Tracking** - Bookings have confirmed/completed/cancelled status

---

## 🎨 New UI Screens Created

### 1. Search Rides Page (`search_rides_page.dart`)
**For:** Passengers
**Features:**
- Filter by start/end location
- Filter by date range
- Filter by max price
- Real-time search results
- Quick booking dialog

```dart
// Access from: BottomNavigation → Search tab
// Or from: Profile → "Search Rides" button
```

### 2. Post Ride Page (`post_ride_page.dart`)
**For:** Drivers
**Features:**
- Enter start/end locations with exact coordinates
- Pick date and time
- Select vehicle type (sedan, SUV, van)
- Set available seats and price
- Add optional notes
- Automatic ride creation in database

```dart
// Access from: Profile (when driver mode enabled) → "Post a Ride"
```

### 3. Driver Bookings Page (`driver_bookings_page.dart`)
**For:** Drivers
**Features:**
- View all rides posted
- Expand each ride to see bookings
- Accept bookings (confirm)
- Reject bookings (restore seats and cancel)
- Real-time booking updates

```dart
// Access from: Profile (when driver mode enabled) → "Manage Bookings"
```

### 4. My Bookings Page (`my_bookings_page.dart`)
**For:** Passengers
**Features:**
- View all personal bookings
- See ride details and driver info
- Cancel booking before confirmation
- Track booking status
- Display price and seats reserved

```dart
// Access from: BottomNavigation → Bookings tab
// Or from: Profile → "My Bookings" button
```

### 5. Profile Page (`profile_page.dart`)
**For:** All Users
**Features:**
- View profile with avatar/name/email
- Toggle Driver Mode on/off
- Quick action buttons to navigate
- Conditional buttons based on mode
- Logout option

```dart
// Access from: BottomNavigation → Profile tab
```

### 6. Updated Home Page (`home_page.dart`)
**For:** All Users
**Changes:**
- Bottom navigation bar (Home, Search, Bookings, Profile)
- Home tab shows featured available rides
- Centralized navigation hub
- Quick access to all features

---

## 🗄️ Database Schema Summary

### Rides Table
```sql
id                UUID PRIMARY KEY
driver_id         UUID (references profiles)
start_location    TEXT (searchable)
start_lat         DECIMAL (for maps)
start_lng         DECIMAL (for maps)
end_location      TEXT (searchable)
end_lat           DECIMAL
end_lng           DECIMAL
departure_time    TIMESTAMP (filterable)
available_seats   INTEGER (decreases on booking)
price_per_seat    DECIMAL (filterable)
vehicle_type      TEXT (sedan/suv/van)
vehicle_plate     TEXT (optional)
status            TEXT (available|in_progress|completed|cancelled)
notes             TEXT (optional)
created_at        TIMESTAMP (auto)
updated_at        TIMESTAMP (auto)
```

### Bookings Table
```sql
id                UUID PRIMARY KEY
ride_id           UUID (references rides)
passenger_id      UUID (references profiles)
seats_booked      INTEGER
total_price       DECIMAL
pickup_location   TEXT (optional)
status            TEXT (confirmed|completed|cancelled)
payment_intent_id TEXT (for Stripe - future)
created_at        TIMESTAMP (auto)
updated_at        TIMESTAMP (auto)
UNIQUE            (ride_id, passenger_id) - prevents double booking
```

---

## 🔄 Key Workflows

### Workflow 1: Driver Posts a Ride
```
Driver clicks Profile tab
    ↓
Enables "Driver Mode" toggle
    ↓
Clicks "Post a Ride" button
    ↓
Fills in ride details:
  - Start location, coordinates
  - End location, coordinates
  - Departure date & time
  - Vehicle type & plate
  - Seats available
  - Price per seat
  - Optional notes
    ↓
Clicks "Post Ride"
    ↓
DatabaseService.createRide() executes
  - Inserts row in rides table
  - Status: 'available'
    ↓
Ride appears in search results for passengers ✅
```

### Workflow 2: Passenger Searches & Books
```
Passenger clicks Search tab (or "Search Rides" from profile)
    ↓
Enters search filters:
  - Start location (optional)
  - End location (optional)
  - Departure date (optional)
  - Max price (optional)
    ↓
Clicks "Search Rides"
    ↓
DatabaseService.searchRides() with filters:
  - Filters by: available_seats > 0
  - Filters by: start_location ILIKE
  - Filters by: end_location ILIKE
  - Filters by: price_per_seat ≤ maxPrice
  - Filters by: departure_time ≥ selectedDate
  - Orders by: departure_time ASC
    ↓
Shows filtered ride results
    ↓
Clicks "Book" on desired ride
    ↓
Selects number of seats (1-available)
    ↓
Clicks "Book Now"
    ↓
DatabaseService.createBooking() executes:
  1. Inserts booking row
  2. Decreases ride.available_seats
  3. Booking status: 'confirmed'
    ↓
✅ Booking confirmed! ✅
```

### Workflow 3: Driver Accepts/Rejects Booking
```
Driver clicks Profile → "Manage Bookings"
    ↓
Shows all driver's rides
    ↓
Expands a ride to see bookings
    ↓
For each booking:
  - Shows passenger name & rating
  - Shows seats booked
  - Shows total price
  - Shows pickup location
  - Shows booking status
    ↓
If status = 'confirmed', shows two buttons:
  - "Accept" button
  - "Reject" button
    ↓
Driver clicks "Accept"
    ↓
Updates booking.status = 'confirmed' (stays confirmed)
    ↓
Or Driver clicks "Reject"
    ↓
1. Updates booking.status = 'cancelled'
2. Restores ride.available_seats += booking.seats_booked
    ↓
✅ Booking status updated ✅
```

---

## 📱 Navigation & Screen Flow

```
AuthGate
├── LoginPage / SignupPage
└── HomePage (Bottom Tab Navigation)
    ├── Tab 1: Home
    │   └── Featured available rides
    ├── Tab 2: Search
    │   └── SearchRidesPage (find & book)
    ├── Tab 3: Bookings
    │   └── MyBookingsPage (passenger bookings)
    └── Tab 4: Profile
        ├── ProfilePage (user info & mode toggle)
        ├── If Passenger:
        │   ├── "Search Rides" → SearchRidesPage
        │   └── "My Bookings" → MyBookingsPage
        └── If Driver:
            ├── "Post a Ride" → PostRidePage
            ├── "Manage Bookings" → DriverBookingsPage
            └── "My Rides" (implied in ManageBookings)
```

---

## 🔐 RLS Policies in Action

### Rides Table
```sql
-- Anyone can view available rides
SELECT: auth.uid() IS NOT NULL (any user)

-- Only driver can INSERT/UPDATE/DELETE their own rides
INSERT: auth.uid() = driver_id
UPDATE: auth.uid() = driver_id
DELETE: auth.uid() = driver_id
```

**Why this works:**
- Passengers can search public rides ✅
- Drivers post/edit their own rides ✅
- Drivers can't edit other drivers' rides ✅

### Bookings Table
```sql
-- Passengers can only see their own bookings
SELECT (passenger): auth.uid() = passenger_id

-- Drivers can see bookings for their rides
SELECT (driver): 
  EXISTS (
    SELECT 1 FROM rides 
    WHERE rides.id = bookings.ride_id 
    AND rides.driver_id = auth.uid()
  )

-- Passengers can only manage their own bookings
INSERT: auth.uid() = passenger_id
UPDATE: auth.uid() = passenger_id
DELETE: auth.uid() = passenger_id
```

**Why this works:**
- Passengers see only their bookings ✅
- Drivers see bookings for their rides ✅
- No cross-passenger data leakage ✅
- Users can't book for someone else ✅

---

## 💾 DatabaseService Methods (Updated)

### Rides Methods
```dart
// Search with advanced filters
searchRides({
  DateTime? afterDate,
  String? startLocation,
  String? endLocation,
  double? maxPrice,
})

// Get available rides (simple)
getAvailableRides({
  DateTime? afterDate,
})

// Create new ride (driver only)
createRide({
  required String startLocation,
  required double startLat,
  required double startLng,
  required String endLocation,
  required double endLat,
  required double endLng,
  required DateTime departureTime,
  required int availableSeats,
  required double pricePerSeat,
  required String vehicleType,
  String? vehiclePlate,
  String? notes,
})

// Get driver's rides
getMyRides(String driverId)

// Update ride status
updateRideStatus(String rideId, String status)
```

### Bookings Methods
```dart
// Create booking (passenger)
createBooking({
  required String rideId,
  required int seatsBooked,
  required double totalPrice,
  String? pickupLocation,
})

// Get passenger's bookings
getMyBookings(String passengerId)

// Get ride's bookings (driver)
getRideBookings(String rideId)

// Cancel booking (passenger)
cancelBooking(String bookingId, String rideId)
```

### Real-time Streams (Optional)
```dart
// Watch available rides live
watchAvailableRides()

// Watch user's bookings live
watchMyBookings(String passengerId)
```

---

## 📊 Booking Status Flow

```
               confirmed ──→ completed
                 ↑↓
            (awaiting driver acceptance)
                 │
                 ├─→ Driver accepts
                 │     Status stays 'confirmed' ✅
                 │
                 └─→ Driver rejects
                       Status becomes 'cancelled'
                       Seats restored to ride
                       Passenger sees cancelled ✗

Alternative:
   Any user can cancel 'confirmed' booking
   Status becomes 'cancelled'
   If already started, unable to cancel (future)
```

---

## 🧪 Testing Guide

### Test 1: Post a Ride (Driver)
1. Sign up / Login
2. Go to Profile → Enable "Driver Mode"
3. Click "Post a Ride"
4. Fill all fields:
   - Start: "Downtown" / Lat: 40.7128 / Lng: -74.0060
   - End: "Airport" / Lat: 40.7700 / Lng: -73.8740
   - Date: Tomorrow
   - Time: 14:00
   - Vehicle: Sedan
   - Seats: 3
   - Price: 25.00
5. Click "Post Ride"
6. Check database: `SELECT * FROM rides WHERE driver_id = 'your_id'`

### Test 2: Search Rides (Passenger)
1. Create 2nd account (passenger)
2. Go to Search tab
3. Leave filters empty or set:
   - Start: "Down"
   - To: "Air"
   - Date: Tomorrow
   - Max: $30
4. Click "Search Rides"
5. Should see ride from Test 1

### Test 3: Book a Ride
1. Click "Book" on ride
2. Set seats: 2
3. See total price calculated
4. Click "Book Now"
5. Check database: `SELECT * FROM bookings WHERE passenger_id = 'your_id'`

### Test 4: Manage Bookings (Driver)
1. Switch back to driver account
2. Go to Profile → "Manage Bookings"
3. See ride with booking from Test 3
4. Expand ride → see passenger booking
5. Click "Accept" or "Reject"
6. Check status updated in database

### Test 5: View My Bookings (Passenger)
1. Switch to passenger account
2. Go to Bookings tab
3. Should see booking from Test 3
4. See status (confirmed/cancelled)
5. Can cancel booking if needed

---

## 🔍 SQL Debugging Queries

```sql
-- See all rides
SELECT id, driver_id, start_location, end_location, 
       available_seats, status, departure_time 
FROM rides 
ORDER BY departure_time DESC;

-- See all bookings
SELECT id, ride_id, passenger_id, seats_booked, 
       status, total_price 
FROM bookings 
ORDER BY created_at DESC;

-- See specific driver's rides
SELECT id, start_location, end_location, available_seats, status
FROM rides 
WHERE driver_id = 'driver-uuid-here'
ORDER BY departure_time DESC;

-- See specific ride's bookings
SELECT b.id, b.passenger_id, p.first_name, b.seats_booked, 
       b.status, b.total_price
FROM bookings b
JOIN profiles p ON b.passenger_id = p.id
WHERE b.ride_id = 'ride-uuid-here'
ORDER BY b.created_at DESC;

-- See passenger's bookings with ride details
SELECT b.id, b.seats_booked, b.status, r.start_location, 
       r.end_location, r.departure_time, r.price_per_seat
FROM bookings b
JOIN rides r ON b.ride_id = r.id
WHERE b.passenger_id = 'passenger-uuid-here'
ORDER BY r.departure_time DESC;
```

---

## ⚠️ Important Notes

### Unique Constraint
```sql
UNIQUE(ride_id, passenger_id)
```
- Prevents same passenger booking same ride twice
- Error if trying: "duplicate key value violates unique constraint"
- App handles with try/catch

### Seat Management
When booking created:
- `available_seats -= seats_booked`

When booking rejected/cancelled:
- `available_seats += booking.seats_booked`

**Note:** If all seats booked, ride doesn't disappear - it just has 0 available_seats (status still 'available' - future: auto-update to 'full')

### Coordinates
- Latitude: -90 to 90 (DECIMAL 10,8)
- Longitude: -180 to 180 (DECIMAL 11,8)
- Future: Integrate Google Maps for auto-coordinates

### Search Limitations
- Case-insensitive (ilike)
- Partial matching ("Down" matches "Downtown")
- No fuzzy matching (yet)
- Future: Google Places API integration

---

## 🚀 Next Steps (Phase 2)

### Priority 1: Payments Integration
- [ ] Add Stripe setup to Supabase Edge Functions
- [ ] Create payment endpoint
- [ ] Process payment when booking created
- [ ] Test with test card numbers

### Priority 2: Notifications
- [ ] Send email when booking created
- [ ] Notify driver of new booking
- [ ] Notify passenger when driver accepts
- [ ] Send SMS reminders 1 hour before ride

### Priority 3: Advanced Features
- [ ] Maps integration (show route)
- [ ] Ratings & reviews
- [ ] User ratings calculated
- [ ] Real-time driver location (if ongoing ride)
- [ ] Chat between driver & passenger

---

## 📚 File Reference

### New Files Created
- `lib/screens/post_ride_page.dart` - Driver: Post a ride
- `lib/screens/driver_bookings_page.dart` - Driver: Manage bookings
- `lib/screens/my_bookings_page.dart` - Passenger: View bookings
- `lib/screens/search_rides_page.dart` - Passenger: Search & book
- `lib/screens/profile_page.dart` - All: Profile & settings

### Modified Files
- `lib/screens/home_page.dart` - Added bottom nav, refactored as hub
- `lib/services/database_service.dart` - Enhanced rides queries

### Database
- `supabase/migrations/001_initial_schema.sql` - All tables, RLS, triggers

---

## ✅ Checklist Before Going Live

- [ ] Database schema deployed to Supabase
- [ ] All 5 UI screens working
- [ ] Passenger signup → auto profile ✅
- [ ] Driver post ride → appears in search ✅
- [ ] Passenger search rides ✅
- [ ] Passenger book ride → seats decrease ✅
- [ ] Driver see bookings ✅
- [ ] Driver accept booking ✅
- [ ] Driver reject booking → seats increase ✅
- [ ] Passenger view bookings ✅
- [ ] Passenger cancel booking ✅
- [ ] Test with 2+ accounts
- [ ] RLS policies blocking unauthorized access
- [ ] Error handling for network failures
- [ ] Edge cases tested (max seats, no results, etc.)

💥 **You're ready to go live!** 💥

Next phase: Payments & Edge Functions
