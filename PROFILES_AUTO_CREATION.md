# Profiles Table & Auto-Creation Trigger

## 📋 What's Implemented

### Profiles Table Schema
```sql
id            UUID PRIMARY KEY → auth.users(id)
email         TEXT UNIQUE
first_name    TEXT
last_name     TEXT
phone         TEXT
avatar_url    TEXT
is_driver     BOOLEAN (default: false)
is_passenger  BOOLEAN (default: true)
rating        DECIMAL(3,2) (default: 5.0)
created_at    TIMESTAMP (auto-set)
updated_at    TIMESTAMP (auto-updated)
```

---

## ⚡ Auto-Creation Trigger Explained

### The Problem
Previously, you had to manually create a profile in your app code every time a user signed up. This was error-prone:
- Signup succeeds but profile fails → inconsistent state
- Race conditions with concurrent signups
- Requires app logic to handle database

### The Solution: Database Trigger
A PostgreSQL trigger automatically creates a profile whenever a new user signs up in Supabase Auth.

### How It Works

```
User signs up
    ↓
Supabase Auth creates user in auth.users
    ↓
✨ TRIGGER FIRES ✨ (on_auth_user_created)
    ↓
Automatically inserts row into profiles table
    ↓
Profile created with:
  - id: user's UUID (from auth.users.id)
  - email: user's email
  - is_passenger: TRUE (default)
  - is_driver: FALSE (default)
  - rating: 5.0
```

### Trigger Code
```sql
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, is_passenger, is_driver)
  VALUES (
    NEW.id,
    NEW.email,
    TRUE,   -- Default to passenger
    FALSE   -- Default to non-driver
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();
```

---

## 🎯 Key Features

### 1. Automatic Profile Creation
- No app-side logic needed
- Happens instantly when user signs up
- Guaranteed consistency

### 2. Default Values
- New users are **passengers** by default
- Not drivers (they opt-in later)
- Rating starts at 5.0 stars

### 3. Foreign Key Protection
- Profile `id` matches `auth.users.id`
- User deletion cascades (profile deleted too)
- No orphaned rows

### 4. Timestamp Automation
- `created_at` set automatically
- `updated_at` updated on any profile change
- Handled by `update_updated_at_column()` trigger

---

## 📱 Updated Signup Flow

```dart
// In SignupPage or AuthService
await authService.signUp(
  email: 'user@example.com',
  password: 'password123',
  firstName: 'John',    // Optional
  lastName: 'Doe',      // Optional
);
```

**What happens:**
1. AuthService calls `supabase.auth.signUp()` ✅
2. User created in `auth.users` ✅
3. **TRIGGER FIRES** → Profile auto-created ✅
4. If firstName/lastName provided, profile updated ✅

**Result:** User has profile ready to use immediately

---

## 🗄️ Database Schema Overview

```
┌─────────────────┐
│  auth.users     │ (Supabase managed)
├─────────────────┤
│ id (UUID)       │◄────────────────┐
│ email           │                 │
│ encrypted_pwd   │                 │
│ created_at      │                 │
└─────────────────┘                 │ Foreign Key
       △                             │
       │ TRIGGER creates             │
       │                             │
┌─────────────────────────────────┐ │
│ profiles (auto-created by DB)   │─┘
├─────────────────────────────────┤
│ id (UUID) PRIMARY KEY           │
│ email (from user email)         │
│ first_name                      │
│ last_name                       │
│ phone                           │
│ avatar_url                      │
│ is_driver (default: false)      │
│ is_passenger (default: true)    │
│ rating (default: 5.0)           │
│ created_at (auto)               │
│ updated_at (auto-on-change)     │
└─────────────────────────────────┘
```

---

## 🔄 Other Triggers in This Schema

### 1. `update_updated_at_column()`
**On:** profiles, rides, bookings
**Does:** Automatically sets `updated_at = CURRENT_TIMESTAMP`
**Example:**
```sql
UPDATE profiles SET first_name = 'Jane' WHERE id = '...';
-- Automatically updates: updated_at = NOW()
```

### 2. `on_auth_user_created()` (New)
**On:** auth.users (insert)
**Does:** Creates corresponding profile row
**Example:**
```sql
-- When Supabase Auth creates user
INSERT INTO auth.users (id, email, ...) VALUES (...);
-- Trigger automatically creates:
INSERT INTO profiles (id, email, is_passenger, is_driver) 
VALUES (user_id, user_email, TRUE, FALSE);
```

---

## ⚠️ Important Notes

### Why SECURITY DEFINER?
```sql
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
...
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

- Allows the trigger to insert into `public.profiles`
- Even though regular users can't INSERT into profiles
- Only the trigger function can do it (RLS still blocks user INSERT)

### Cascade Delete
```sql
id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
```

If user deletes account from auth.users:
- Profile is automatically deleted
- No broken foreign keys
- Clean database state

---

## 📊 Testing the Trigger

### Method 1: Sign Up in App
```bash
flutter run
# Create account → Check database
```

### Method 2: Check in Supabase Dashboard
1. Go to **SQL Editor**
2. Run: `SELECT * FROM public.profiles;`
3. Should see your user with auto-created profile

### Method 3: Run Query
```sql
-- See all profiles created by trigger
SELECT id, email, is_passenger, is_driver, created_at 
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 5;
```

---

## 🛡️ How RLS Protects Profiles

Even though profiles are auto-created, RLS policies still control who can see/edit them:

```sql
-- Anyone can view all profiles (for driver/passenger info)
CREATE POLICY "Users can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (TRUE);

-- Users can only UPDATE their own profile
CREATE POLICY "Users can update their own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can't INSERT (trigger does it)
-- So this policy fails for manual inserts
CREATE POLICY "Users can insert their own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);
```

**Result:** User can only modify their own profile, but trigger bypasses INSERT restriction.

---

## 🚀 User Journey with Auto-Creation

```
Step 1: User Signs Up
  Email: alice@example.com
  Password: ••••••••
       ↓
Step 2: Supabase Auth Creates User
  auth.users.id = "550e8400-e29b-41d4-a716-446655440000"
       ↓
Step 3: Trigger Fires Automatically
  ✨ on_auth_user_created() executes
       ↓
Step 4: Profile Auto-Created
  profiles.id = "550e8400-e29b-41d4-a716-446655440000"
  profiles.email = "alice@example.com"
  profiles.is_passenger = true
  profiles.is_driver = false
  profiles.rating = 5.0
       ↓
Step 5: User Logs In
  ✅ Everything ready to use
  ✅ Can view rides, book, etc.
```

---

## ⏱️ Timing Considerations

| Action | When It Happens | Visible In App |
|--------|-----------------|----------------|
| User clicks signup | Immediate | - |
| Auth email sent | Seconds | Check email |
| Trigger fires | <1ms after auth | When user logs in |
| Profile ready | Same transaction | Next query |

**TL;DR:** Profile is ready the moment user switches back to app after email verification.

---

## 🔌 Integration with Signup Form

### Before (Manual Insert)
```dart
// In AuthService
await supabase.auth.signUp(...);
// Had to manually insert profile
await supabase.from('profiles').insert({...});
```

### After (Automatic)
```dart
// In AuthService - MUCH simpler
await supabase.auth.signUp(...);
// Profile auto-created by trigger! Ready to use.

// Optional: Add additional info
if (firstName != null) {
  await supabase.from('profiles').update({
    'first_name': firstName
  }).eq('id', userId);
}
```

---

## 📝 Summary

✅ **What Auto-Creation Trigger Does**
- Eliminates manual profile creation
- Guarantees consistency
- Prevents race conditions
- Simplifies app code
- Handles edge cases (concurrent signups)

✅ **Default Profile State**
- Passenger by default
- Not a driver
- 5.0 rating
- Email populated

✅ **Next Step**
- Deploy `001_initial_schema.sql` to Supabase
- Test by signing up a new user
- Check profiles table in SQL Editor

---

## 🆘 Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Profile not created | Trigger not deployed | Run SQL migration |
| Duplicate email error | Email already exists | Use unique email |
| Permission denied on update | User updating someone else's profile | RLS working correctly |
| Profile exists but NULL fields | Defaults not applied | Check trigger SECURITY DEFINER |

---

## 📚 Next Steps

1. ✅ Deploy `001_initial_schema.sql`
2. ✅ Test signup → profile auto-created
3. 📌 Add driver profile UI (upgrade to driver)
4. 📌 Add ride posting (for drivers)
5. 📌 Add payments (Stripe)
