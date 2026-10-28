/// Standalone, immutable data structures for the AlonzY smart matching engine.
///
/// This module is intentionally isolated from the rest of the application and
/// does not depend on Firebase, Supabase, or any mobile platform APIs.
class RideOffer {
  final String id;
  final String driverName;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final DateTime departureTime;
  final int availableSeats;
  final bool allowsSmoking;
  final bool acceptsPets;
  final bool hasLargeTrunk;

  const RideOffer({
    required this.id,
    required this.driverName,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.departureTime,
    required this.availableSeats,
    required this.allowsSmoking,
    required this.acceptsPets,
    required this.hasLargeTrunk,
  });
}

/// Passenger request used to evaluate route and preference compatibility.
class PassengerRequest {
  final String id;
  final String passengerName;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final DateTime preferredTime;
  final bool isSmoker;
  final bool hasPet;
  final bool hasLargeLuggage;

  const PassengerRequest({
    required this.id,
    required this.passengerName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.preferredTime,
    required this.isSmoker,
    required this.hasPet,
    required this.hasLargeLuggage,
  });
}

/// Final match output containing the score and the associated badge text.
class MatchingResult {
  final double score;
  final String badgeLabel;
  final double detourKm;
  final int timeDifferenceMinutes;
  final bool isEligible;

  const MatchingResult({
    required this.score,
    required this.badgeLabel,
    required this.detourKm,
    required this.timeDifferenceMinutes,
    required this.isEligible,
  });
}
