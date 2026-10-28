/// Latest GPS fix shared by a participant during an active ride.
class LiveRideLocation {
  const LiveRideLocation({
    required this.rideId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.speedMetersPerSecond,
    this.headingDegrees,
  });

  final String rideId;
  final String userId;
  final double latitude;
  final double longitude;
  final double? speedMetersPerSecond;
  final double? headingDegrees;
  final DateTime capturedAt;

  factory LiveRideLocation.fromJson(Map<String, dynamic> json) {
    final latitude = _asDouble(json['latitude']);
    final longitude = _asDouble(json['longitude']);
    final capturedAt = DateTime.tryParse(json['captured_at']?.toString() ?? '');
    final rideId = json['ride_id']?.toString();
    final userId = json['user_id']?.toString();

    if (latitude == null ||
        longitude == null ||
        capturedAt == null ||
        rideId == null ||
        userId == null) {
      throw const FormatException('Invalid live ride location payload.');
    }

    return LiveRideLocation(
      rideId: rideId,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      speedMetersPerSecond: _asDouble(json['speed_mps']),
      headingDegrees: _asDouble(json['heading_degrees']),
      capturedAt: capturedAt.toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ride_id': rideId,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_mps': speedMetersPerSecond,
        'heading_degrees': headingDegrees,
        'captured_at': capturedAt.toUtc().toIso8601String(),
      };

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
