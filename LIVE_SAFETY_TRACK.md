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

The participant-only map above remains separate from the external contact link
described below. The external link is a bearer capability: anyone who obtains
it can view the passenger's latest position while the ride is active.

## External safety contact link

Apply `supabase/migrations/20261117000100_postgis_matching_safety.sql` after
the existing migrations. It creates `match_feedback`, `safety_shares`, and
`ride_positions`, adds owner-scoped RLS, and exposes
`get_shared_position(share_token text)`. Anonymous clients can call only that
RPC; the function returns at most the latest position for the passenger tied
to that confirmed booking, and only while the link is active, unexpired, and
the ride is in progress. Ending a ride deactivates shares and deletes stored
positions.

Apply `supabase/migrations/20261119000100_safety_purge_and_consent.sql` next.
It stores the immutable `consent_given_at` timestamp for each new share,
records when sharing is stopped, and purges positions when links expire or
15 minutes after sharing is stopped. When `pg_cron` is available, the
migration schedules the purge every 15 minutes. Otherwise, enable `pg_cron` or
schedule `SELECT public.purge_expired_ride_positions();` from a trusted
scheduled job. The purge preserves positions while another valid share for the
same ride remains active.

Apply `supabase/migrations/20261119000400_shared_route_coordinates.sql` to
extend `get_shared_position` with the ride's start and destination coordinates.
The anonymous RPC returns those endpoints only for a valid active share token.
`web_tracker/track.html` then requests the road geometry from OSRM and draws it
under the live position marker; if OSRM is unavailable, the page displays a
direct endpoint line instead.

`LiveSafetyTrackScreen` shows the ride route, endpoints, and the signed-in
participant's current GPS location. It requests full route geometry from OSRM
and falls back to a direct endpoint line if routing is unavailable. Starting
**Suivi & partage de sécurité**
asks for explicit consent (including a Loi 25 notice), starts participant-only
live location sharing, and creates a cryptographically random public token
valid for three hours. The screen displays the public link with actions to copy
it or send it through the native share sheet. Stopping sharing revokes both
the public token and the participant location stream. Public GPS fixes are
sent every 12 seconds while the app is in the foreground; participant-only
locations use the shorter interval documented below.

The `.github/workflows/deploy-tracker.yml` workflow copies `web_tracker/` to
the root of the GitHub Pages artifact and injects the public Supabase settings
into the tracker's meta tags. In the repository's **Settings → Secrets and
variables → Actions → Variables**, add:

- `SUPABASE_URL`: the project's public URL, for example
  `https://<project-ref>.supabase.co`.
- `SUPABASE_ANON_KEY`: the project's public anon/publishable key.

The workflow also accepts those names as Actions secrets, but repository
variables are appropriate because both values are intended to be public in
the deployed page. Never use a `service_role` key. In **Settings → Pages**,
set the build and deployment source to **GitHub Actions**. A push to `main` or
a manual workflow run deploys `web_tracker/` contents to the Pages site root,
making the tracker available at
`https://alphasimpli.github.io/AlonzY/track.html`.

Set `SAFETY_TRACKER_URL` in the ignored local `.env` to that exact tracker URL;
the app adds the share token as a `token` query parameter. Do not commit
project-specific values. The page polls the RPC every 12 seconds, reports an
invalid or expired link when the RPC has no active position, and does not
create an authenticated session.

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

Supabase configuration uses these `.env` keys:

```text
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SAFETY_TRACKER_URL=https://alphasimpli.github.io/AlonzY/track.html
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

The existing in-app participant sharing service continues to use its six
second location stream. External contact sharing uses foreground position
requests every twelve seconds and expires automatically after three hours.
