-- AlonzY : creation ciblee de la table des retours d'appariement.
-- Reprend la structure match_feedback de :
-- 20261117000100_postgis_matching_safety.sql

BEGIN;

CREATE TABLE IF NOT EXISTS public.match_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
    passenger_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    detour_min DOUBLE PRECISION NOT NULL CHECK (detour_min >= 0),
    time_gap_min INTEGER NOT NULL CHECK (time_gap_min >= 0),
    pref_score DOUBLE PRECISION NOT NULL CHECK (pref_score BETWEEN 0 AND 100),
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    rule_score DOUBLE PRECISION NOT NULL CHECK (rule_score BETWEEN 0 AND 100),
    accepted BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.match_feedback
    ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ADD COLUMN IF NOT EXISTS ride_id UUID NOT NULL
        REFERENCES public.rides(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS passenger_id UUID NOT NULL
        REFERENCES public.profiles(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS detour_min DOUBLE PRECISION NOT NULL
        CHECK (detour_min >= 0),
    ADD COLUMN IF NOT EXISTS time_gap_min INTEGER NOT NULL
        CHECK (time_gap_min >= 0),
    ADD COLUMN IF NOT EXISTS pref_score DOUBLE PRECISION NOT NULL
        CHECK (pref_score BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS price NUMERIC(10, 2) NOT NULL
        CHECK (price >= 0),
    ADD COLUMN IF NOT EXISTS rule_score DOUBLE PRECISION NOT NULL
        CHECK (rule_score BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS accepted BOOLEAN,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS match_feedback_passenger_created_idx
    ON public.match_feedback (passenger_id, created_at DESC);

ALTER TABLE public.match_feedback ENABLE ROW LEVEL SECURITY;

-- Retire les droits par defaut eventuels sur cette nouvelle table uniquement,
-- puis accorde les droits necessaires a l'application.
REVOKE ALL PRIVILEGES ON TABLE public.match_feedback FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.match_feedback TO authenticated;
GRANT UPDATE (accepted) ON TABLE public.match_feedback TO authenticated;

DROP POLICY IF EXISTS match_feedback_select_own
    ON public.match_feedback;
CREATE POLICY match_feedback_select_own
    ON public.match_feedback FOR SELECT TO authenticated
    USING (passenger_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS match_feedback_insert_own
    ON public.match_feedback;
CREATE POLICY match_feedback_insert_own
    ON public.match_feedback FOR INSERT TO authenticated
    WITH CHECK (
        passenger_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.rides AS r
            WHERE r.id = match_feedback.ride_id
              AND r.status = 'available'
        )
    );

DROP POLICY IF EXISTS match_feedback_update_own
    ON public.match_feedback;
CREATE POLICY match_feedback_update_own
    ON public.match_feedback FOR UPDATE TO authenticated
    USING (passenger_id = (SELECT auth.uid()))
    WITH CHECK (passenger_id = (SELECT auth.uid()));

COMMIT;

NOTIFY pgrst, 'reload schema';