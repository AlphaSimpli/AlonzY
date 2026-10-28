CREATE TABLE IF NOT EXISTS public.ride_live_locations (
	ride_id UUID NOT NULL REFERENCES public.rides(id) ON DELETE CASCADE,
	user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
	latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
	longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
	speed_mps DOUBLE PRECISION CHECK (speed_mps IS NULL OR speed_mps >= 0),
	heading_degrees DOUBLE PRECISION
		CHECK (heading_degrees IS NULL OR heading_degrees BETWEEN 0 AND 360),
	captured_at TIMESTAMPTZ NOT NULL,
	PRIMARY KEY (ride_id, user_id)
);

ALTER TABLE public.ride_live_locations ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE
	ON public.ride_live_locations TO authenticated;

CREATE OR REPLACE FUNCTION public.can_access_live_ride(p_ride_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
	SELECT EXISTS (
		SELECT 1
		FROM public.rides r
		WHERE r.id = p_ride_id
			AND r.status = 'in_progress'
			AND (
				r.driver_id = auth.uid()
				OR EXISTS (
					SELECT 1
					FROM public.bookings b
					WHERE b.ride_id = r.id
						AND b.passenger_id = auth.uid()
						AND b.status IN ('confirmed', 'accepted')
				)
			)
	);
$$;

REVOKE ALL ON FUNCTION public.can_access_live_ride(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_access_live_ride(UUID) TO authenticated;

DROP POLICY IF EXISTS ride_live_locations_select_participants
	ON public.ride_live_locations;
CREATE POLICY ride_live_locations_select_participants
	ON public.ride_live_locations FOR SELECT TO authenticated
	USING (public.can_access_live_ride(ride_id));

DROP POLICY IF EXISTS ride_live_locations_insert_self
	ON public.ride_live_locations;
CREATE POLICY ride_live_locations_insert_self
	ON public.ride_live_locations FOR INSERT TO authenticated
	WITH CHECK (
		user_id = auth.uid()
		AND public.can_access_live_ride(ride_id)
	);

DROP POLICY IF EXISTS ride_live_locations_update_self
	ON public.ride_live_locations;
CREATE POLICY ride_live_locations_update_self
	ON public.ride_live_locations FOR UPDATE TO authenticated
	USING (
		user_id = auth.uid()
		AND public.can_access_live_ride(ride_id)
	)
	WITH CHECK (
		user_id = auth.uid()
		AND public.can_access_live_ride(ride_id)
	);

DROP POLICY IF EXISTS ride_live_locations_delete_self
	ON public.ride_live_locations;
CREATE POLICY ride_live_locations_delete_self
	ON public.ride_live_locations FOR DELETE TO authenticated
	USING (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.clear_ended_ride_live_locations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
	IF OLD.status = 'in_progress' AND NEW.status <> 'in_progress' THEN
		DELETE FROM public.ride_live_locations WHERE ride_id = NEW.id;
	END IF;
	RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.clear_ended_ride_live_locations() FROM PUBLIC;

DROP TRIGGER IF EXISTS clear_ended_ride_live_locations
	ON public.rides;
CREATE TRIGGER clear_ended_ride_live_locations
	AFTER UPDATE OF status ON public.rides
	FOR EACH ROW
	EXECUTE FUNCTION public.clear_ended_ride_live_locations();

DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_publication_tables
		WHERE pubname = 'supabase_realtime'
			AND schemaname = 'public'
			AND tablename = 'ride_live_locations'
	) THEN
		ALTER PUBLICATION supabase_realtime
			ADD TABLE public.ride_live_locations;
	END IF;
END;
$$;

NOTIFY pgrst, 'reload schema';
