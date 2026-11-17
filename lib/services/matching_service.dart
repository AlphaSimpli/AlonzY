import 'dart:math';

import '../models/matching_models.dart';
import 'osrm_service.dart';

/// Smart matching engine that evaluates an offer against a passenger request.
///
/// The synchronous method keeps the original pure-Dart Haversine baseline.
/// The separate asynchronous method explicitly requests OSRM road estimates.
class MatchingService {
  const MatchingService();

  MatchingResult calculateMatchScore(
    RideOffer offer,
    PassengerRequest request,
  ) {
    if (offer.availableSeats < 1) {
      return const MatchingResult(
        score: 0.0,
        badgeLabel: '0% • Not Eligible',
        detourKm: 0.0,
        timeDifferenceMinutes: 0,
        isEligible: false,
      );
    }

    final detourKm = _calculateTotalDetourKm(offer, request);
    return _scoreWithDetour(offer, request, detourKm);
  }

  /// First integration stage: preserve the score's weights and preferences,
  /// replacing only the geographic proxy with additional road distance.
  /// Routing errors propagate: never label a Haversine fallback as OSRM.
  /// The caller owns/reuses [routingService] and decides how to display failures.
  Future<RoutedMatchingResult> calculateRoadMatchScore(
    RideOffer offer,
    PassengerRequest request, {
    required OsrmService routingService,
  }) async {
    if (offer.availableSeats < 1) {
      return RoutedMatchingResult(
        match: calculateMatchScore(offer, request),
        detour: null,
      );
    }
    final detour = await routingService.getDetour(
      driverStart: OsrmCoordinate(offer.startLatitude, offer.startLongitude),
      driverEnd: OsrmCoordinate(offer.endLatitude, offer.endLongitude),
      pickup: OsrmCoordinate(request.pickupLatitude, request.pickupLongitude),
      dropoff: OsrmCoordinate(
        request.dropoffLatitude,
        request.dropoffLongitude,
      ),
    );
    return RoutedMatchingResult(
      match: _scoreWithDetour(offer, request, detour.extraDistanceKm),
      detour: detour,
    );
  }

  MatchingResult _scoreWithDetour(
    RideOffer offer,
    PassengerRequest request,
    double detourKm,
  ) {
    final geographicScore = _calculateGeographicScore(detourKm);
    final timeDifferenceMinutes = offer.departureTime
        .difference(request.preferredTime)
        .abs()
        .inMinutes;
    final timeScore = _calculateTimeScore(timeDifferenceMinutes);
    final preferenceScore = _calculatePreferenceScore(offer, request);

    double totalScore = geographicScore + timeScore + preferenceScore;

    final hasPreferenceMismatch =
        (request.hasPet && !offer.acceptsPets) ||
        (request.hasLargeLuggage && !offer.hasLargeTrunk);

    if (hasPreferenceMismatch) {
      totalScore -= 20.0;
    }

    totalScore = totalScore.clamp(0.0, 100.0);

    return MatchingResult(
      score: double.parse(totalScore.toStringAsFixed(1)),
      badgeLabel: _buildBadgeLabel(totalScore),
      detourKm: double.parse(detourKm.toStringAsFixed(1)),
      timeDifferenceMinutes: timeDifferenceMinutes,
      isEligible: totalScore > 0.0,
    );
  }

  double _calculateTotalDetourKm(RideOffer offer, PassengerRequest request) {
    final pickupDistanceKm = _haversineKm(
      offer.startLatitude,
      offer.startLongitude,
      request.pickupLatitude,
      request.pickupLongitude,
    );

    final dropoffDistanceKm = _haversineKm(
      offer.endLatitude,
      offer.endLongitude,
      request.dropoffLatitude,
      request.dropoffLongitude,
    );

    return pickupDistanceKm + dropoffDistanceKm;
  }

  double _calculateGeographicScore(double detourKm) {
    if (detourKm <= 0.0) {
      return 50.0;
    }
    if (detourKm > 15.0) {
      return 0.0;
    }
    return 50.0 * (1.0 - (detourKm / 15.0));
  }

  double _calculateTimeScore(int timeDifferenceMinutes) {
    if (timeDifferenceMinutes <= 10) {
      return 35.0;
    }
    if (timeDifferenceMinutes >= 60) {
      return 0.0;
    }

    final normalized = (timeDifferenceMinutes - 10) / 50.0;
    return 35.0 * (1.0 - normalized);
  }

  double _calculatePreferenceScore(RideOffer offer, PassengerRequest request) {
    double score = 0.0;

    if (!request.isSmoker || offer.allowsSmoking) {
      score += 5.0;
    }

    if (!request.hasPet || offer.acceptsPets) {
      score += 5.0;
    }

    if (!request.hasLargeLuggage || offer.hasLargeTrunk) {
      score += 5.0;
    }

    return score;
  }

  String _buildBadgeLabel(double score) {
    final roundedValue = score.round();

    if (score <= 0.0) {
      return '0% • Not Eligible';
    }
    if (score >= 90.0) {
      return '$roundedValue% • Ideal Match';
    }
    if (score >= 80.0) {
      return '$roundedValue% • Good Choice';
    }
    if (score >= 60.0) {
      return '$roundedValue% • Good Fit';
    }
    if (score >= 40.0) {
      return '$roundedValue% • Moderate Detour';
    }
    return '$roundedValue% • Low Match';
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final lat1Radians = lat1 * (pi / 180.0);
    final lat2Radians = lat2 * (pi / 180.0);
    final deltaLat = (lat2 - lat1) * (pi / 180.0);
    final deltaLon = (lon2 - lon1) * (pi / 180.0);

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Radians) *
            cos(lat2Radians) *
            sin(deltaLon / 2) *
            sin(deltaLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }
}

/// Separate result so the existing MatchingResult and its callers stay intact.
/// A null detour is only used for an offer rejected before any routing request.
class RoutedMatchingResult {
  const RoutedMatchingResult({required this.match, required this.detour});
  final MatchingResult match;
  final OsrmDetourEstimate? detour;
}
