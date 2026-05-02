# Step 2️⃣: Profiles Table + Auto-Creation Trigger - Setup Checklist

## ✅ What's Included

### Database Schema
- ✅ **profiles** table with 10 columns
- ✅ **Automatic timestamps** (created_at, updated_at)
- ✅ **Auto-creation trigger** (on_auth_user_created)
- ✅ **Foreign key to auth.users** (cascading delete)
- ✅ **RLS policies** for security

### Code Updates
- ✅ Updated `AuthService.signUp()` - Now uses trigger
- ✅ Simplified signup flow - No manual profile insert
- ✅ Documentation - Comprehensive guides

---

## 🚀 Deployment (5 minutes)

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project
3. Click **SQL Editor** (left sidebar)
4. Click **+ New Query**

### Step 2: Copy & Run Migration
1. Open file: `supabase/migrations/001_initial_schema.sql`
2. Copy entire contents
3. Paste into SQL Editor
4. Click **Run** (or `Cmd+Enter`)

### Step 3: Verify Deployment
```sql
-- Check tables created
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check triggers created
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- Should see:
-- - profiles table
-- - rides table
-- - bookings table
-- - on_auth_user_created trigger
-- - update_profiles_updated_at trigger
-- - update_rides_updated_at trigger
-- - update_bookings_updated_at trigger
```

---

## 📱 Test the Trigger

### Test 1: Sign Up in App
```bash
cd /Users/ousmanediallo/dev_App/supabase_flutter_app
flutter run
```

1. Click "Create account"
2. Enter: `test@example.com` / `password123`
3. Check spam folder for verification email
4. Click verification link
5. Go back to app and login

### Test 2: Verify Profile Was Created
In Supabase SQL Editor:
```sql
SELECT * FROM public.profiles WHERE email = 'test@example.com';
```

Expected output:
```
id            | email          | is_passenger | is_driver | rating | created_at
--------------+----------------+--------------+-----------+--------+------------------
550e8400-...  | test@example   | true         | false     | 5.0    | 2026-04-05 ...
```

### Test 3: Check Trigger in Action
```sql
-- See all profiles created by trigger (ordered by newest)
SELECT id, email, is_passenger, is_driver, rating, created_at 
FROM public.profiles 
ORDER BY created_at DESC;
```

---

## 🎯 How the Trigger Works

### The Database Trigger
```sql
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, is_passenger, is_driver)
  VALUES (
    NEW.id,           -- User's UUID from auth.users
    NEW.email,        -- User's email
    TRUE,             -- Default: is passenger
    FALSE             -- Default: not driver (opt-in later)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users    -- Fires when user signs up
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();
```

### What It Does
1. **Listens** for new users in `auth.users`
2. **Extracts** user ID and email
3. **Automatically creates** corresponding profile row
4. **Sets defaults**: is_passenger=true, is_driver=false, rating=5.0
5. **No app logic needed** ✨

---

## 📊 Profiles Table Schema

```
Column        | Type          | Default    | Notes
--------------+---------------+------------+------------------
id            | UUID          | -          | Linked to auth.users
email         | TEXT UNIQUE   | -          | From user signup
first_name    | TEXT          | NULL       | Set by app later
last_name     | TEXT          | NULL       | Set by app later
phone         | TEXT          | NULL       | Optional
avatar_url    | TEXT          | NULL       | Profile picture URL
is_driver     | BOOLEAN       | FALSE      | User opts in
is_passenger  | BOOLEAN       | TRUE       | Default
rating        | DECIMAL(3,2)  | 5.0        | Out of 5 stars
created_at    | TIMESTAMP     | NOW()      | Auto-set
updated_at    | TIMESTAMP     | NOW()      | Auto-updated on change
```

---

## 🔐 RLS Policies (Already Configured)

```
Policy                              | Action | Who Can Do It
------------------------------------+--------+---------------------------
Users can view all profiles         | SELECT | Anyone (see driver ratings)
Users can view their own profile    | SELECT | Owner
Users can update their own profile  | UPDATE | Owner
Users can insert their own profile  | INSERT | (Blocked - trigger does it)
```

---

## 📱 App Integration

### Before (Manual Profile Creation)
```dart
// AuthService - Old way
Future<AuthResponse> signUp(...) async {
  final response = await supabase.auth.signUp(...);
  
  // Had to manually create profile
  await supabase.from('profiles').insert({
    'id': response.user!.id,
    'email': email,
    'first_name': firstName,
  });
}
```

### After (Automatic with Trigger)
```dart
// AuthService - New way
Future<AuthResponse> signUp(...) async {
  final response = await supabase.auth.signUp(...);
  
  // Profile auto-created by trigger! ✨
  // Optional: just update if additional info provided
  if (firstName != null) {
    await supabase.from('profiles').update({
      'first_name': firstName
    }).eq('id', response.user!.id);
  }
}
```

---

## ✨ Benefits of Auto-Creation Trigger

| Benefit | Details |
|---------|---------|
| **Consistency** | Profile always exists when user exists |
| **Reliability** | No race conditions from concurrent signups |
| **Simplicity** | Less app code to maintain |
| **Performance** | Trigger runs in same transaction as auth |
| **Safety** | No orphaned users without profiles |
| **Defaults** | Sensible defaults (passenger by default) |

---

## 🔄 What Happens at Each Step

### Step 1: User Clicks "Sign Up"
```
SignupPage → AuthService.signUp()
```

### Step 2: Supabase Auth Creates User
```
supabase.auth.signUp() → auth.users table INSERT
```

### Step 3: ⚡ Trigger Fires
```
PostgreSQL trigger on_auth_user_created executes
→ Automatically INSERT into profiles table
```

### Step 4: App Gets Response
```
← AuthResponse with new user
← Profile already created!
```

### Step 5: User Verifies Email
```
Check email → Click verification link
```

### Step 6: User Logs In
```
LoginPage → AuthService.signIn()
→ AuthGate sees session
→ Navigate to HomePage
→ Can query profile ✅
```

---

## 📝 File Changes

### Modified Files
- `supabase/migrations/001_initial_schema.sql` 
  - Added `create_profile_for_new_user()` function
  - Added `on_auth_user_created()` trigger

- `lib/services/auth_service.dart`
  - Removed manual profile creation
  - Added optional profile update with first/last name
  - Simplified signup flow

### New Documentation
- `PROFILES_AUTO_CREATION.md` - Detailed guide
- `SETUP_CHECKLIST_STEP2.md` - This file

---

## ⚠️ Important Notes

### Why SECURITY DEFINER?
The trigger function runs with elevated privileges so it can INSERT into `profiles` table even though RLS policies normally prevent INSERT:

```sql
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

This is intentional and safe because:
- Only the trigger can do it (not regular users)
- RLS still protects against unauthorized access
- User can't INSERT directly, only trigger can

### Cascade Delete
If a user deletes their auth account:
```sql
( id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE )
```

- Profile automatically deleted
- Maintains referential integrity
- No broken foreign keys

---

## 🧪 Testing Checklist

- [ ] Deploy SQL migration
- [ ] Check tables created in Supabase
- [ ] Sign up new user in app
- [ ] Verify profile auto-created (SQL query)
- [ ] Log in with same user
- [ ] See profile data in app
- [ ] Update profile with first/last name
- [ ] Verify update persisted
- [ ] Check timestamps (created_at vs updated_at)

---

## 🆘 Troubleshooting

### "Trigger not found" in Dashboard
**Problem:** SQL migration not deployed
**Solution:** Copy entire `001_initial_schema.sql` and run in SQL Editor

### "Duplicate key value violates unique constraint"
**Problem:** Trying to signup with same email twice
**Solution:** Use a different email address

### "Permission denied" on profile INSERT
**Problem:** Trigger not running or not SECURITY DEFINER
**Solution:** Redeploy migration, check function has SECURITY DEFINER

### Profile name fields are NULL
**Problem:** Didn't provide firstName/lastName in signup
**Solution:** Call profile update to set them later, or pass them to signUp()

---

## 📚 Next Steps

✅ **This Step (2️⃣):** Profiles + Auto-Creation Trigger
- Deploy SQL migration
- Test signup flow
- Verify trigger works

📌 **Next Step (3️⃣):** Rides Table & Queries
- Create "Post Ride" screen (for drivers)
- Query available rides
- Update ride status after booking

---

## 💡 Pro Tips

1. **Always verify in SQL Editor** after deployment
2. **Use `ORDER BY created_at DESC` to see newest profiles**
3. **Check constraints with** `SELECT constraint_name FROM information_schema.constraint_column_usage`
4. **Monitor trigger performance** in Production (rarely an issue)
5. **Keep trigger functions simple** (query-only or direct inserts)

---

Ready to deploy? Let's go! 🚀
