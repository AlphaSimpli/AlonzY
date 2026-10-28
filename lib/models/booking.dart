import 'app_user.dart';
import 'ride.dart';

/// Strongly-typed seat booking with an embedded ride and driver preview.
class Booking {
  final String id;
  final String rideId;
  final String passengerId;
  final int seatsBooked;
  final double totalPrice;
  final String? pickupLocation;
  final String status;
  final DateTime createdAt;
  final Ride? ride;

  /// Passenger profile, embedded when the query joins `profiles(...)`.
  final AppUser? passenger;

  const Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.totalPrice,
    this.pickupLocation,
    this.status = 'confirmed',
    required this.createdAt,
    this.ride,
    this.passenger,
  });

  factory Booking.fromJson(Map<String, dynamic>? json) {
    final data = json == null ? <String, dynamic>{} : Map<String, dynamic>.from(json);
    final rawRide = data['rides'] is Map
        ? Map<String, dynamic>.from(data['rides'] as Map)
        : null;
    final rawPassenger = data['profiles'] is Map
        ? Map<String, dynamic>.from(data['profiles'] as Map)
        : null;
    return Booking(
      id: data['id']?.toString() ?? '',
      rideId: data['ride_id']?.toString() ?? '',
      passengerId: data['passenger_id']?.toString() ?? '',
      seatsBooked: _asInt(data['seats_booked']) ?? 0,
      totalPrice: _asDouble(data['total_price']) ?? 0,
      pickupLocation: data['pickup_location']?.toString(),
      status: data['status']?.toString() ?? 'confirmed',
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
      ride: rawRide == null ? null : Ride.fromJson(rawRide),
      passenger: rawPassenger == null ? null : AppUser.fromJson(rawPassenger),
    );
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}