import '../models/ride.dart';
import 'osrm_service.dart';

class RoutedRide {
  const RoutedRide({required this.ride, required this.detour});
  final Ride ride;
  final OsrmDetourEstimate detour;
}

class RoutedRideSearch {
  RoutedRideSearch({
    required List<RoutedRide> rides,
    required this.excludedCount,
  }) : rides = List.unmodifiable(rides);
  final List<RoutedRide> rides;
  final int excludedCount;
}

/// Routing-only ranking after database preselection. Not a trained model or a
/// full matching score: the current form has no preferred time or preferences.
///
/// Uses one shared OSRM instance, preserving its rate limiter and route cache.
/// The candidate limit is enforced before any HTTP request; never silently
/// truncate the database shortlist or fabricate a fallback.
class RideRoutingService {
  RideRoutingService({OsrmService? routingService})
    : _osrm = routingService ?? OsrmService(),
      _ownsOsrm = routingService == null;

  static const maxCandidates = 5;
  static const maxExtraDistanceKm = 15;

  final OsrmService _osrm;
  final bool _ownsOsrm;
  bool _closed = false;

  Future<RoutedRideSearch> rank({
    required List<Ride> candidates,
    required OsrmCoordinate pickup,
    required OsrmCoordinate dropoff,
    bool Function()? isCancelled,
  }) async {
    void checkCancelled() {
      if (_closed || (isCancelled?.call() ?? false)) {
        throw const OsrmException('cancelled');
      }
    }

    checkCancelled();
    if (!_valid(pickup) || !_valid(dropoff)) {
      throw ArgumentError('Invalid passenger coordinates.');
    }
    if (candidates.length > maxCandidates) {
      throw const OsrmException('tooManyCandidates');
    }
    // A snapshot prevents a caller from changing the list during awaits.
    final snapshot = List<Ride>.of(candidates);
    final ranked = <RoutedRide>[];
    for (final ride in snapshot) {
      checkCancelled();
      final start = OsrmCoordinate(ride.originLat, ride.originLng);
      final end = OsrmCoordinate(ride.destinationLat, ride.destinationLng);
      if (ride.availableSeats < 1 ||
          ride.status != 'available' ||
          !_validOffer(start) ||
          !_validOffer(end)) {
        continue;
      }
      try {
        final direct = await _osrm.getRoute([start, end]);
        checkCancelled(); // Do not start a second request after leaving the page.
        final shared = await _osrm.getRoute([start, pickup, dropoff, end]);
        checkCancelled();
        final detour = OsrmDetourEstimate(
          directRoute: direct,
          sharedRoute: shared,
        );
        if (detour.extraDistanceKm <= maxExtraDistanceKm) {
          ranked.add(RoutedRide(ride: ride, detour: detour));
        }
      } on OsrmException catch (error) {
        // An unroutable offer is different from a server/network outage.
        if (error.code != 'NoRoute' && error.code != 'NoSegment') rethrow;
      }
    }
    checkCancelled();
    ranked.sort((a, b) {
      var comparison = a.detour.extraDistanceMeters.compareTo(
        b.detour.extraDistanceMeters,
      );
      if (comparison != 0) return comparison;
      comparison = a.detour.extraDurationSeconds.compareTo(
        b.detour.extraDurationSeconds,
      );
      if (comparison != 0) return comparison;
      comparison = a.ride.departureTime.compareTo(b.ride.departureTime);
      return comparison != 0 ? comparison : a.ride.id.compareTo(b.ride.id);
    });
    return RoutedRideSearch(
      rides: ranked,
      excludedCount: snapshot.length - ranked.length,
    );
  }

  static bool _valid(OsrmCoordinate point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;

  // Ride.fromJson uses (0,0) as its fallback for absent/bad coordinate fields.
  // Do not send this missing-location sentinel to the public routing server.
  static bool _validOffer(OsrmCoordinate point) =>
      _valid(point) && !(point.latitude == 0 && point.longitude == 0);

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsOsrm) _osrm.close();
  }
}
