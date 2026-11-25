import 'dart:math';

import '../models/matching_models.dart';
import '../models/ride.dart';
import 'road_route_service.dart';
import 'osrm_service.dart';

/// Optional predictor, independent from model loading and Flutter assets.
typedef LearnedMatchPredictor =
    double Function({
      required double detourMinutes,
      required int timeGapMinutes,
      required double preferenceScore,
      required double price,
    });

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

  MatchingResult calculateMatchScoreWithDetour(
    RideOffer offer,
    PassengerRequest request, {
    required double detourKm,
  }) {
    if (!detourKm.isFinite || detourKm < 0) {
      throw ArgumentError.value(detourKm, 'detourKm');
    }
    if (offer.availableSeats < 1) {
      return calculateMatchScore(offer, request);
    }
    return _scoreWithDetour(offer, request, detourKm);
  }

  double calculatePreferenceScore(RideOffer offer, PassengerRequest request) =>
      _calculatePreferenceScore(offer, request);

  /// Performs database-prefiltered candidate matching with OSRM table requests.
  /// Rules always determine eligibility and remain the default ranking.
  /// An explicit predictor can change ranking without overwriting rule scores.
  Future<HybridRideSearch> rankRides({
    required List<Ride> candidates,
    required PassengerRequest request,
    required OsrmCoordinate pickup,
    required OsrmCoordinate dropoff,
    required RoadRouteService routingService,
    LearnedMatchPredictor? learnedPredictor,
  }) async {
    final snapshot = List<Ride>.of(candidates);
    if (snapshot.isEmpty) {
      return const HybridRideSearch(matches: [], excludedCount: 0);
    }

    final routable = snapshot
        .where(
          (ride) =>
              ride.status == 'available' &&
              ride.availableSeats > 0 &&
              _validCoordinate(ride.originLat, ride.originLng) &&
              _validCoordinate(ride.destinationLat, ride.destinationLng),
        )
        .toList();
    final detours = await routingService.calculateDetours(
      candidates: routable,
      pickup: pickup,
      dropoff: dropoff,
    );
    final byRideId = {for (final detour in detours) detour.rideId: detour};
    final matches = <HybridRideMatch>[];
    for (final ride in routable) {
      final detour = byRideId[ride.id];
      if (detour == null || detour.extraDistanceKm > 15) continue;
      final offer = _rideOffer(ride);
      final result = calculateMatchScoreWithDetour(
        offer,
        request,
        detourKm: detour.extraDistanceKm,
      );
      if (result.isEligible) {
        final preferenceScore = calculatePreferenceScore(offer, request);
        final learnedProbability = learnedPredictor?.call(
          detourMinutes: detour.extraDurationMinutes,
          timeGapMinutes: result.timeDifferenceMinutes,
          preferenceScore: preferenceScore,
          price: ride.pricePerSeat,
        );
        if (learnedProbability != null &&
            (!learnedProbability.isFinite ||
                learnedProbability < 0 ||
                learnedProbability > 1)) {
          throw StateError(
            'The learned predictor must return a value in [0, 1].',
          );
        }
        matches.add(
          HybridRideMatch(
            ride: ride,
            detour: detour,
            match: result,
            preferenceScore: preferenceScore,
            learnedProbability: learnedProbability,
          ),
        );
      }
    }
    matches.sort((a, b) {
      final byScore = b.rankingScore.compareTo(a.rankingScore);
      if (byScore != 0) return byScore;
      final byDetour = a.detour.extraDurationSeconds.compareTo(
        b.detour.extraDurationSeconds,
      );
      if (byDetour != 0) return byDetour;
      final byDeparture = a.ride.departureTime.compareTo(b.ride.departureTime);
      return byDeparture != 0 ? byDeparture : a.ride.id.compareTo(b.ride.id);
    });
    return HybridRideSearch(
      matches: matches,
      excludedCount: snapshot.length - matches.length,
    );
  }

  static bool _validCoordinate(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  static RideOffer _rideOffer(Ride ride) => RideOffer(
    id: ride.id,
    driverName: ride.driver?.displayName ?? '',
    startLatitude: ride.originLat,
    startLongitude: ride.originLng,
    endLatitude: ride.destinationLat,
    endLongitude: ride.destinationLng,
    departureTime: ride.departureTime,
    availableSeats: ride.availableSeats,
    allowsSmoking: false,
    acceptsPets: ride.petsAllowed,
    hasLargeTrunk: ride.luggagePolicy == 'large',
  );

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

class HybridRideMatch {
  const HybridRideMatch({
    required this.ride,
    required this.detour,
    required this.match,
    required this.preferenceScore,
    this.learnedProbability,
  });

  final Ride ride;
  final RoadRouteDetour detour;
  final MatchingResult match;
  final double preferenceScore;

  /// Optional logistic output, not a calibrated real-user acceptance rate.
  final double? learnedProbability;

  /// Both ranking modes use a 0..100 scale; [match.score] stays the rule score.
  double get rankingScore =>
      learnedProbability == null ? match.score : learnedProbability! * 100.0;

  bool get usesLearnedScore => learnedProbability != null;
}

class HybridRideSearch {
  const HybridRideSearch({required this.matches, required this.excludedCount});
  final List<HybridRideMatch> matches;
  final int excludedCount;
}
