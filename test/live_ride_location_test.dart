import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/models/live_ride_location.dart';

void main() {
  test('round trips a live ride location payload', () {
    final capturedAt = DateTime.utc(2026, 10, 27, 12);
    final location = LiveRideLocation(
      rideId: 'ride-id',
      userId: 'user-id',
      latitude: 45.5017,
      longitude: -73.5673,
      speedMetersPerSecond: 8.5,
      headingDegrees: 120,
      capturedAt: capturedAt,
    );

    final parsed = LiveRideLocation.fromJson(location.toJson());

    expect(parsed.rideId, location.rideId);
    expect(parsed.userId, location.userId);
    expect(parsed.latitude, location.latitude);
    expect(parsed.longitude, location.longitude);
    expect(parsed.speedMetersPerSecond, location.speedMetersPerSecond);
    expect(parsed.headingDegrees, location.headingDegrees);
    expect(parsed.capturedAt, capturedAt.toLocal());
  });

  test('rejects malformed realtime payloads', () {
    expect(() => LiveRideLocation.fromJson(const {}), throwsFormatException);
  });
}
