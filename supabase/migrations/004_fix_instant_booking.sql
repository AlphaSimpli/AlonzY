-- ============================================================================
-- 004_FIX_INSTANT_BOOKING.sql
--
-- Standalone hotfix for PostgREST error PGRST204:
--   "Could not find the 'instant_booking' column of 'rides' in the schema cache"
--
-- Run this against Supabase if migration 003 has not been applied yet.
-- It is idempotent and can be run at any time. Afterwards PostgREST is
-- reloaded immediately via NOTIFY so no schema-cache warm-up wait is needed.
--
-- NOTE: migration 003 also provides chat tables, verification columns and the
-- booking approval lifecycle; apply it as well for full feature parity.
-- ============================================================================

-- 1. Add the column if it does not exist yet (safe to run repeatedly).
ALTER TABLE public.rides
  ADD COLUMN IF NOT EXISTS instant_booking BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Reload the PostgREST schema cache so the new column is visible without
--    restarting the API. (NOTIFY is deferred until commit, then delivered.)
NOTIFY pgrst, 'reload schema';
