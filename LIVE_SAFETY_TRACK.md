# Live Safety Track

Live Safety Track shares a participant's current GPS fix with the driver and
confirmed passengers during a ride whose `rides.status` is `in_progress`.
Sharing is opt-in from the tracking page and can be stopped at any time.

## Backend setup

Apply `supabase/migrations/20261027000100_live_safety_track.sql` to the
Supabase project (`supabase db push`, or run the migration in the Dashboard SQL
Editor). It creates `public.ride_live_locations`, enables RLS, and adds the
table to the `supabase_realtime` publication.

Rows are keyed by ride and user and contain latitude, longitude, speed in
meters per second, heading in degrees, and the time the GPS fix was captured.
The RLS policies allow reads only to the driver and confirmed/accepted
passengers of an in-progress ride. A participant can write only their own
location. Stopping sharing deletes that participant's last shared row.
When the ride leaves `in_progress`, a database trigger removes all remaining
location rows for that ride.

This version does **not** share location with arbitrary trusted contacts.
That requires a separate trusted-contact relationship and explicit per-trip
sharing authorization before access can safely be granted.

## App usage

Open the page with the active ride's id and map center:

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => LiveSafetyTrackScreen(
      rideId: ride.id,
      initialCenter: ride.start,
    ),
  ),
);
```

The page subscribes to participant location changes and updates MapLibre
markers. The user must tap **Partager ma position** to start GPS collection.
Call `LiveSafetyService.stopSharing()` when the trip ends; the page also stops
the local GPS subscription when it is disposed.

Supabase configuration uses the existing `.env` keys:

```text
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

No separate Geolocator or MapLibre API key is required. Never ship a Supabase
`service_role` key in the Flutter app; authorization is enforced by RLS.

## Platform permissions and background limits

The app's platform configuration already includes the permissions needed by
the tracking service:

- Android: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
  `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, and `WAKE_LOCK` in
  `android/app/src/main/AndroidManifest.xml`. Android displays a foreground
  notification during tracking. Users may need to grant **Allow all the time**
  from app settings for background location, depending on Android version.
- iOS: `NSLocationWhenInUseUsageDescription`,
  `NSLocationAlwaysAndWhenInUseUsageDescription`,
  `NSLocationAlwaysUsageDescription`, and `UIBackgroundModes` with `location`
  in `ios/Runner/Info.plist`. Users must grant Always location access for
  background updates.

Background tracking is best-effort while the OS keeps the app process alive.
Geolocator's location stream does not relaunch the Flutter app after it has
been force-quit or terminated by the OS. Respect the user's platform-level
permission choice; do not start sharing before the user opts in.

The service requests Android GPS updates every six seconds by default (the
interval is configurable between five and ten seconds), and publishes only
fresh fixes. iOS controls the GPS callback cadence; the service ignores fixes
older than 30 seconds. The map's initial snapshot ignores rows whose GPS fix
is over two minutes old.
