import 'app_user.dart';
import 'ride.dart';

/// A private driver-passenger conversation tied to a ride.
///
/// Parsed defensively so raw Supabase rows (dynamic-keyed maps) can never
/// throw a runtime cast error.
class Conversation {
  final String id;
  final String rideId;
  final String passengerId;
  final String driverId;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DateTime? passengerLastReadAt;
  final DateTime? driverLastReadAt;

  /// Other party's profile, embedded via `passenger:profiles!passenger_id(...)`.
  final AppUser? passenger;

  /// Driver's profile, embedded via `driver:profiles!driver_id(...)`.
  final AppUser? driver;

  /// The ride this conversation belongs to (route preview).
  final Ride? ride;

  const Conversation({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.driverId,
    this.lastMessage,
    this.lastSenderId,
    required this.lastMessageAt,
    required this.createdAt,
    this.passengerLastReadAt,
    this.driverLastReadAt,
    this.passenger,
    this.driver,
    this.ride,
  });

  /// The participant that is not [userId], used for list avatars/labels.
  AppUser? otherParty(String userId) {
    if (userId == passengerId) return driver;
    if (userId == driverId) return passenger;
    return null;
  }

  /// Whether [userId] has unread messages (a newer message from the other
  /// party that has not been read yet).
  bool hasUnread(String userId) {
    if (lastSenderId == userId) return false;
    final lastRead =
        userId == passengerId ? passengerLastReadAt : driverLastReadAt;
    return lastRead == null || lastMessageAt.isAfter(lastRead);
  }

  factory Conversation.fromJson(Map<String, dynamic>? json) {
    final data =
        json == null ? <String, dynamic>{} : Map<String, dynamic>.from(json);
    final rawPassenger = data['passenger'] is Map
        ? Map<String, dynamic>.from(data['passenger'] as Map)
        : null;
    final rawDriver = data['driver'] is Map
        ? Map<String, dynamic>.from(data['driver'] as Map)
        : null;
    final rawRide = data['rides'] is Map
        ? Map<String, dynamic>.from(data['rides'] as Map)
        : null;
    return Conversation(
      id: data['id']?.toString() ?? '',
      rideId: data['ride_id']?.toString() ?? '',
      passengerId: data['passenger_id']?.toString() ?? '',
      driverId: data['driver_id']?.toString() ?? '',
      lastMessage: data['last_message']?.toString(),
      lastSenderId: data['last_sender_id']?.toString(),
      lastMessageAt: DateTime.tryParse(
              data['last_message_at']?.toString() ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
              DateTime.now(),
      passengerLastReadAt: DateTime.tryParse(
          data['passenger_last_read_at']?.toString() ?? ''),
      driverLastReadAt:
          DateTime.tryParse(data['driver_last_read_at']?.toString() ?? ''),
      passenger: rawPassenger == null ? null : AppUser.fromJson(rawPassenger),
      driver: rawDriver == null ? null : AppUser.fromJson(rawDriver),
      ride: rawRide == null ? null : Ride.fromJson(rawRide),
    );
  }
}