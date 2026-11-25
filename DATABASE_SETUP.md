# Supabase Database Setup

AlonzY uses Supabase PostgreSQL for application data and authentication,
PostGIS for spatial ride discovery, and Realtime for chat and trip updates.
Database changes are versioned in [`supabase/migrations/`](supabase/migrations/).

## Apply migrations to a development project

Install the [Supabase CLI](https://supabase.com/docs/guides/cli), authenticate,
and link a development project:

```sh
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase migration list --linked
supabase db push --dry-run --linked
```

Review every pending migration before applying it. Then run:

```sh
supabase db push --linked
supabase migration list --linked
```

Do not use `db push` against production until the migration plan has been
reviewed and tested in a separate environment. Migrations are ordered and
incremental; do not apply only `001_initial_schema.sql` or rerun SQL manually
from an already-applied migration.

## Schema areas

- **Accounts and rides:** profiles, ride listings, bookings, chat, and reviews.
- **Spatial search:** PostGIS geography columns, GiST indexes, and the
  authenticated `search_ride_candidates` RPC.
- **Matching feedback:** owner-scoped records used for optional model
  evaluation and training.
- **Safety sharing:** participant-protected live locations, consented
  token-based sharing, expiry, revocation, and token-scoped route lookup.
- **Access control:** migrations define grants and Row-Level Security (RLS)
  policies; review those policies whenever a table, RPC, or role changes.

The migrations are the source of truth for table definitions, constraints,
indexes, triggers, RPC signatures, and RLS. Use the Supabase SQL editor to
inspect a deployed schema without replacing the migration history.

## Flutter configuration

Copy `.env.example` to `.env` at the repository root and set:

```dotenv
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
SAFETY_TRACKER_URL=https://YOUR_PAGES_SITE/track.html
```

The app uses only the public client key; authorization is enforced by Supabase
Auth and RLS. Never place a `service_role` key in the Flutter app or `.env`.
The `.env` file is bundled for client runtime configuration and is not secret
storage.

## Troubleshooting spatial search

If PostgREST reports `PGRST202` for `search_ride_candidates`:

1. Check `supabase migration list --linked` and apply reviewed pending
   migrations.
2. Verify the RPC signature and authenticated-role grant in the Supabase SQL
   editor.
3. Confirm the app request uses an authenticated session; the spatial search
   RPC is not intended for the anonymous role.
4. Confirm the origin coordinates and departure date are valid. Without both,
   the app uses its text-search path rather than PostGIS preselection.

For safety-link deployment and privacy behavior, see
[`LIVE_SAFETY_TRACK.md`](LIVE_SAFETY_TRACK.md). For security reporting and
credential handling, see [`SECURITY.md`](SECURITY.md).
