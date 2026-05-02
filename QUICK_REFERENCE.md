# Quick Reference Guide

## 📱 User Flows

### 1. New User Registration
```
Tap "Create account" → SignupPage → Enter email/password → AuthService.signUp()
→ Profile auto-created → Email verification → Login with email → HomePage
```

### 2. Book a Ride
```
HomePage (loaded with available rides) → Tap "Book" → Select seats
→ DatabaseService.createBooking() → Booking confirmed → Refresh list
```

### 3. Post a Ride (Driver)
```
[To be implemented] → DatabaseService.createRide() → Ride appears in available list
```

---

## 🗂️ File Changes Summary

### New Files Created
- `supabase/migrations/001_initial_schema.sql` - Database schema
- `lib/services/database_service.dart` - Database service
- `DATABASE_SETUP.md` - Setup instructions
- `IMPLEMENTATION.md` - Full implementation guide

### Modified Files
- `lib/main.dart` - Fixed AuthGate with StreamBuilder
- `lib/screens/login_page.dart` - Consolidate with AuthService
- `lib/screens/signup_page.dart` - Better error handling
- `lib/screens/home_page.dart` - Ride listing with booking UI
- `lib/services/auth_service.dart` - Profile creation on signup

---

## 🔑 Key Code Examples

### Check Current User
```dart
final user = supabase.auth.currentUser;
print(user?.email);
```

### Query Available Rides
```dart
final db = DatabaseService();
final rides = await db.getAvailableRides();
```

### Create Booking
```dart
final bookingId = await db.createBooking(
  rideId: ride['id'],
  seatsBooked: 2,
  totalPrice: 50.00,
);
```

### Cancel Booking  
```dart
await db.cancelBooking(bookingId, rideId);
```

---

## 🔐 RLS Policies Quick Lookup

| Table | Action | Who | Allowed |
|-------|--------|-----|---------|
| profiles | SELECT | Anyone | ✅ All profiles public |
| profiles | INSERT | Self | ✅ Own profile only |
| profiles | UPDATE | Self | ✅ Own profile only |
| rides | SELECT | Anyone | ✅ All available rides |
| rides | INSERT | Driver | ✅ Own rides |
| rides | UPDATE | Driver | ✅ Own rides |
| rides | DELETE | Driver | ✅ Own rides |
| bookings | SELECT | Passenger | ✅ Own bookings |
| bookings | SELECT | Driver | ✅ Bookings for their rides |
| bookings | INSERT | Passenger | ✅ Own bookings |
| bookings | UPDATE | Passenger | ✅ Own bookings |
| bookings | DELETE | Passenger | ✅ Own bookings |

---

## 🚀 Deploy Checklist

- [ ] Deploy database schema (SQL migrations)
- [ ] Test authentication (signup → email → login)
- [ ] Create test ride via SQL
- [ ] Test ride listing in app
- [ ] Test booking flow
- [ ] Check RLS policies work correctly
- [ ] Test logout redirects to login

---

## 📞 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Can't see rides | Check `status = 'available'` and `departure_time > NOW()` |
| Booking fails | Verify enough seats available |
| Auth loops forever | Check email verified in Supabase Auth settings |
| RLS permission denied | Verify user is logged in, check policies allow action |
| Profile not created | Check Supabase Profile table has no required fields issue |

---

## 💾 State Management Summary

Currently using simple `setState()` pattern. For larger apps consider:
- Provider
- Riverpod  
- GetX
- Bloc

---

## 📊 Database Stats

- **Tables**: 3 (profiles, rides, bookings)
- **Published columns**: 40+
- **Indexes**: 9 for performance
- **RLS Policies**: 13 for security
- **Triggers**: 3 auto-timestamp functions

All data is encrypted in transit (HTTPS) and at rest (Supabase encryption).
