BEGIN;

DROP FUNCTION IF EXISTS public.get_shared_position(TEXT);

CREATE FUNCTION public.get_shared_position(share_token TEXT)
RETURNS TABLE (
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ,
    origin_lat DOUBLE PRECISION,
    origin_lng DOUBLE PRECISION,
    destination_lat DOUBLE PRECISION,
    destination_lng DOUBLE PRECISION
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
    SELECT
        p.lat,
        p.lng,
        p.recorded_at,
        r.origin_lat,
        r.origin_lng,
        r.destination_lat,
        r.destination_lng
    FROM public.safety_shares s
    JOIN public.bookings b ON b.id = s.booking_id
    JOIN public.rides r ON r.id = b.ride_id
    JOIN LATERAL (
        SELECT rp.lat, rp.lng, rp.recorded_at
        FROM public.ride_positions rp
        WHERE rp.ride_id = r.id
          AND rp.user_id = s.shared_user_id
        ORDER BY rp.recorded_at DESC, rp.id DESC
        LIMIT 1
    ) p ON TRUE
    WHERE s.token = $1
      AND s.is_active
      AND s.expires_at > now()
      AND b.status IN ('confirmed', 'in_progress')
      AND r.status IN ('available', 'in_progress')
    LIMIT 1;
$function$;

REVOKE ALL ON FUNCTION public.get_shared_position(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_shared_position(TEXT) TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
