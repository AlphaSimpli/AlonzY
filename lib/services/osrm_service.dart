import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Pure Dart coordinates: this service remains usable outside Flutter.
class OsrmCoordinate {
  const OsrmCoordinate(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Estimates for OSRM's recommended driving route, not live-traffic measurements.
class OsrmRouteEstimate {
  const OsrmRouteEstimate({
    required this.distanceMeters,
    required this.durationSeconds,
    this.geometry = const [],
  });
  final double distanceMeters;
  final double durationSeconds;
  final List<OsrmCoordinate> geometry;
}

class OsrmDetourEstimate {
  const OsrmDetourEstimate({
    required this.directRoute,
    required this.sharedRoute,
  });
  final OsrmRouteEstimate directRoute;
  final OsrmRouteEstimate sharedRoute;

  // Routes optimize driving weight, not necessarily distance. Negative
  // differences mean no additional cost for this metric; never a bonus.
  double get extraDistanceMeters =>
      math.max(0.0, sharedRoute.distanceMeters - directRoute.distanceMeters);
  double get extraDurationSeconds =>
      math.max(0.0, sharedRoute.durationSeconds - directRoute.durationSeconds);
  double get extraDistanceKm => extraDistanceMeters / 1000;
  double get extraDurationMinutes => extraDurationSeconds / 60;
}

/// Codes are diagnostic, not translated user-facing messages.
class OsrmException implements Exception {
  const OsrmException(this.code, {this.httpStatus});
  final String code;
  final int? httpStatus;
  @override
  String toString() => 'OsrmException($code, httpStatus: $httpStatus)';
}

class _CachedRoute {
  const _CachedRoute(this.route, this.expiresAt);
  final OsrmRouteEstimate route;
  final DateTime expiresAt;
}

/// Small routing client for the first OSRM integration stage.
///
/// API: https://project-osrm.org/docs/v5.24.0/api/
/// Public demo policy: https://routing.openstreetmap.de/about.html
///
/// The demo is for light prototyping, not load testing or a production SLA.
/// Coordinates are transmitted to the selected server and can enter its logs.
/// Reuse one instance: requests are serialized and spaced by at least 1.1 s
/// by default; cached and already-in-flight identical requests are reused.
/// Configure a dedicated endpoint before realistic load/performance testing.
/// No automatic Haversine fallback: callers must disclose unavailable routing.
class OsrmService {
  OsrmService({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 8),
    this.minimumInterval = const Duration(milliseconds: 1100),
    this.cacheTtl = const Duration(minutes: 5),
    this.maxCacheEntries = 64,
    this.maxSnapDistanceMeters = 1000,
    DateTime Function()? clock,
  }) : baseUri = baseUri ?? Uri.https('router.project-osrm.org', ''),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _clock = clock ?? DateTime.now {
    if (!['https', 'http'].contains(this.baseUri.scheme) ||
        this.baseUri.host.isEmpty ||
        this.baseUri.userInfo.isNotEmpty ||
        this.baseUri.hasQuery ||
        this.baseUri.hasFragment) {
      throw ArgumentError(
        'OSRM base URI must be an HTTP(S) server without credentials, query or fragment.',
      );
    }
    if (timeout <= Duration.zero ||
        minimumInterval.isNegative ||
        cacheTtl.isNegative ||
        maxCacheEntries < 0 ||
        !maxSnapDistanceMeters.isFinite ||
        maxSnapDistanceMeters <= 0) {
      throw ArgumentError(
        'Invalid OSRM timeout, interval, cache or snap radius.',
      );
    }
  }

  final Uri baseUri;
  final Duration timeout;
  final Duration minimumInterval;
  final Duration cacheTtl;
  final int maxCacheEntries;
  final double maxSnapDistanceMeters;
  final http.Client _client;
  final bool _ownsClient;
  final DateTime Function() _clock;
  // Dart map literals preserve insertion order, used here for LRU eviction.
  final _cache = <String, _CachedRoute>{};
  final _inFlight = <String, Future<OsrmRouteEstimate>>{};
  final _sinceLastStart = Stopwatch();
  Future<void> _queue = Future<void>.value();
  bool _closed = false;

  Future<OsrmDetourEstimate> getDetour({
    required OsrmCoordinate driverStart,
    required OsrmCoordinate driverEnd,
    required OsrmCoordinate pickup,
    required OsrmCoordinate dropoff,
  }) async {
    // Validate every point before sending even the first request.
    _validatePoints([driverStart, pickup, dropoff, driverEnd]);
    final direct = await getRoute([driverStart, driverEnd]);
    final shared = await getRoute([driverStart, pickup, dropoff, driverEnd]);
    return OsrmDetourEstimate(directRoute: direct, sharedRoute: shared);
  }

  Future<OsrmRouteEstimate> getRoute(
    List<OsrmCoordinate> points, {
    bool includeGeometry = false,
  }) {
    if (_closed) return Future.error(const OsrmException('closed'));
    try {
      _validatePoints(points);
    } on ArgumentError catch (error) {
      return Future.error(error);
    }
    final coordinates = points
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    final prefix = baseUri.path.replaceAll(RegExp(r'/+$'), '');
    final uri = baseUri.replace(
      path: '$prefix/route/v1/driving/$coordinates',
      queryParameters: {
        'overview': includeGeometry ? 'full' : 'false',
        'steps': 'false',
        'alternatives': 'false',
        'continue_straight': 'false',
        if (includeGeometry) 'geometries': 'geojson',
        'radiuses': List.filled(
          points.length,
          '$maxSnapDistanceMeters',
        ).join(';'),
      },
    );
    final key = uri.toString();
    final cached = _cache.remove(key);
    if (cached != null && _clock().isBefore(cached.expiresAt)) {
      _cache[key] = cached;
      return Future.value(cached.route);
    }
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final completer = Completer<OsrmRouteEstimate>();
    final count = points.length;
    _inFlight[key] = completer.future;
    _queue = _queue.then((_) async {
      try {
        if (_closed) throw const OsrmException('closed');
        if (_sinceLastStart.isRunning) {
          final remaining = minimumInterval - _sinceLastStart.elapsed;
          if (remaining > Duration.zero) await Future<void>.delayed(remaining);
        }
        if (_closed) throw const OsrmException('closed');
        _sinceLastStart.reset();
        _sinceLastStart.start();
        final route = await _request(
          uri,
          count,
          includeGeometry: includeGeometry,
        );
        if (_closed) throw const OsrmException('closed');
        if (maxCacheEntries > 0 && cacheTtl > Duration.zero) {
          // Bound memory and remove expired entries before keeping a response.
          final now = _clock();
          _cache.removeWhere((_, value) => !now.isBefore(value.expiresAt));
          _cache[key] = _CachedRoute(route, now.add(cacheTtl));
          while (_cache.length > maxCacheEntries) {
            _cache.remove(_cache.keys.first);
          }
        }
        completer.complete(route);
      } catch (error, stack) {
        completer.completeError(error, stack);
      } finally {
        _inFlight.remove(key);
      }
    });
    return completer.future;
  }

  Future<OsrmRouteEstimate> _request(
    Uri uri,
    int pointCount, {
    required bool includeGeometry,
  }) async {
    late http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              // Browsers set their own User-Agent/Referer and forbid overriding UA.
              if (!const bool.fromEnvironment('dart.library.js_interop') &&
                  !const bool.fromEnvironment('dart.library.js'))
                'User-Agent': 'AlonzY/1.0 (university carpool prototype)',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const OsrmException('timeout');
    } catch (_) {
      throw const OsrmException('network');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw OsrmException(
        response.statusCode == 200 ? 'invalidResponse' : 'http',
        httpStatus: response.statusCode,
      );
    }
    final code = decoded is Map ? decoded['code'] : null;
    if (code == 'NoRoute' || code == 'NoSegment') {
      throw OsrmException(code as String, httpStatus: response.statusCode);
    }
    if (response.statusCode != 200) {
      throw OsrmException('http', httpStatus: response.statusCode);
    }
    if (decoded is! Map || code != 'Ok') {
      throw const OsrmException('invalidResponse');
    }
    final routes = decoded['routes'];
    final waypoints = decoded['waypoints'];
    if (routes is! List ||
        routes.isEmpty ||
        routes.first is! Map ||
        waypoints is! List ||
        waypoints.length != pointCount) {
      throw const OsrmException('invalidResponse');
    }
    for (final waypoint in waypoints) {
      if (waypoint is! Map ||
          !_validMetric(waypoint['distance']) ||
          (waypoint['distance'] as num) > maxSnapDistanceMeters) {
        throw const OsrmException('invalidSnap');
      }
    }
    final route = routes.first as Map;
    if (!_validMetric(route['distance']) || !_validMetric(route['duration'])) {
      throw const OsrmException('invalidResponse');
    }
    final geometry = <OsrmCoordinate>[];
    if (includeGeometry) {
      final rawGeometry = route['geometry'];
      final coordinates = rawGeometry is Map ? rawGeometry['coordinates'] : null;
      if (rawGeometry is! Map ||
          rawGeometry['type'] != 'LineString' ||
          coordinates is! List ||
          coordinates.length < 2) {
        throw const OsrmException('invalidResponse');
      }
      for (final coordinate in coordinates) {
        if (coordinate is! List ||
            coordinate.length < 2 ||
            coordinate[0] is! num ||
            coordinate[1] is! num) {
          throw const OsrmException('invalidResponse');
        }
        final longitude = (coordinate[0] as num).toDouble();
        final latitude = (coordinate[1] as num).toDouble();
        if (!latitude.isFinite ||
            !longitude.isFinite ||
            latitude.abs() > 90 ||
            longitude.abs() > 180) {
          throw const OsrmException('invalidResponse');
        }
        geometry.add(OsrmCoordinate(latitude, longitude));
      }
    }
    return OsrmRouteEstimate(
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
      geometry: List.unmodifiable(geometry),
    );
  }

  static bool _validMetric(Object? value) =>
      value is num && value.isFinite && value >= 0;

  static void _validatePoints(List<OsrmCoordinate> points) {
    if (points.length < 2 || points.length > 4) {
      throw ArgumentError('OSRM routing expects two to four points.');
    }
    for (final point in points) {
      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude.abs() > 90 ||
          point.longitude.abs() > 180) {
        throw ArgumentError('Invalid routing coordinates.');
      }
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _cache.clear();
    if (_ownsClient) _client.close();
  }
}
