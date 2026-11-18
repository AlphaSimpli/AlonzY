import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/ride.dart';
import 'osrm_service.dart';

class RoadRouteDetour {
  const RoadRouteDetour({
    required this.rideId,
    required this.extraDurationSeconds,
    required this.extraDistanceMeters,
  });

  final String rideId;
  final double extraDurationSeconds;
  final double extraDistanceMeters;

  double get extraDurationMinutes => extraDurationSeconds / 60;
  double get extraDistanceKm => extraDistanceMeters / 1000;
}

/// Calculates all candidate detours through one OSRM table request.
class RoadRouteService {
  RoadRouteService({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       baseUri = baseUri ?? Uri.https('router.project-osrm.org', '') {
    if (!['https', 'http'].contains(this.baseUri.scheme) ||
        this.baseUri.host.isEmpty ||
        this.baseUri.userInfo.isNotEmpty ||
        this.baseUri.hasQuery ||
        this.baseUri.hasFragment ||
        timeout <= Duration.zero) {
      throw ArgumentError('Invalid OSRM endpoint or timeout.');
    }
  }

  final http.Client _client;
  final bool _ownsClient;
  final Uri baseUri;
  final Duration timeout;
  static const int maxCandidates = 100;
  static const int maxCoordinatesPerRequest = 50;
  static const int maxCandidatesPerBatch =
      (maxCoordinatesPerRequest - 2) ~/ 2;
  bool _closed = false;

  Future<List<RoadRouteDetour>> calculateDetours({
    required List<Ride> candidates,
    required OsrmCoordinate pickup,
    required OsrmCoordinate dropoff,
  }) async {
    if (_closed) throw const OsrmException('closed');
    _validateCoordinate(pickup);
    _validateCoordinate(dropoff);

    final snapshot = List<Ride>.of(candidates);
    if (snapshot.isEmpty) return const [];
    if (snapshot.length > maxCandidates) {
      throw const OsrmException('tooManyCandidates');
    }

    for (final ride in snapshot) {
      _validateCoordinate(OsrmCoordinate(ride.originLat, ride.originLng));
      _validateCoordinate(
        OsrmCoordinate(ride.destinationLat, ride.destinationLng),
      );
      if (ride.originLat == 0 &&
          ride.originLng == 0 &&
          ride.destinationLat == 0 &&
          ride.destinationLng == 0) {
        throw ArgumentError('Candidate ride has no route coordinates.');
      }
    }

    final batches = <List<Ride>>[
      for (var start = 0;
          start < snapshot.length;
          start += maxCandidatesPerBatch)
        snapshot.sublist(
          start,
          math.min(start + maxCandidatesPerBatch, snapshot.length),
        ),
    ];
    final results = await Future.wait(
      batches.map(
        (batch) => _calculateBatch(
          candidates: batch,
          pickup: pickup,
          dropoff: dropoff,
        ),
      ),
    );
    return results.expand((batch) => batch).toList(growable: false);
  }

  Future<List<RoadRouteDetour>> _calculateBatch({
    required List<Ride> candidates,
    required OsrmCoordinate pickup,
    required OsrmCoordinate dropoff,
  }) async {
    final count = candidates.length;
    final points = <OsrmCoordinate>[
      ...candidates.map(
        (ride) => OsrmCoordinate(ride.originLat, ride.originLng),
      ),
      pickup,
      dropoff,
      ...candidates.map(
        (ride) => OsrmCoordinate(ride.destinationLat, ride.destinationLng),
      ),
    ];
    final coordinates = points
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final destinationIndices = [
      count,
      count + 1,
      ...List<int>.generate(count, (index) => count + 2 + index),
    ];
    final uri = baseUri.replace(
      path:
          '${baseUri.path.replaceAll(RegExp(r'/+$'), '')}/table/v1/driving/$coordinates',
      queryParameters: {
        'annotations': 'duration,distance',
        'sources': List<int>.generate(count + 2, (index) => index).join(';'),
        'destinations': destinationIndices.join(';'),
      },
    );

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const OsrmException('timeout');
    } catch (_) {
      throw const OsrmException('network');
    }
    if (_closed) throw const OsrmException('closed');

    Object? payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw OsrmException(
        response.statusCode == 200 ? 'invalidResponse' : 'http',
        httpStatus: response.statusCode,
      );
    }
    if (response.statusCode != 200) {
      throw OsrmException('http', httpStatus: response.statusCode);
    }
    if (payload is! Map || payload['code'] != 'Ok') {
      throw const OsrmException('invalidResponse');
    }

    final durations = _readMatrix(payload['durations'], count + 2, count + 2);
    final distances = _readMatrix(payload['distances'], count + 2, count + 2);
    final result = <RoadRouteDetour>[];
    for (var index = 0; index < count; index++) {
      try {
        final directDuration = _requiredMetric(durations[index][index + 2]);
        final sharedDuration =
            _requiredMetric(durations[index][0]) +
            _requiredMetric(durations[count][1]) +
            _requiredMetric(durations[count + 1][index + 2]);
        final directDistance = _requiredMetric(distances[index][index + 2]);
        final sharedDistance =
            _requiredMetric(distances[index][0]) +
            _requiredMetric(distances[count][1]) +
            _requiredMetric(distances[count + 1][index + 2]);
        result.add(
          RoadRouteDetour(
            rideId: candidates[index].id,
            extraDurationSeconds: math.max(0, sharedDuration - directDuration),
            extraDistanceMeters: math.max(0, sharedDistance - directDistance),
          ),
        );
      } on OsrmException catch (error) {
        if (error.code != 'NoRoute') rethrow;
      }
    }
    return result;
  }

  static double _requiredMetric(double? value) {
    if (value == null) throw const OsrmException('NoRoute');
    return value;
  }

  static List<List<double?>> _readMatrix(Object? value, int rows, int columns) {
    if (value is! List || value.length != rows) {
      throw const OsrmException('invalidResponse');
    }
    return value.map((row) {
      if (row is! List || row.length != columns) {
        throw const OsrmException('invalidResponse');
      }
      return row.map((metric) {
        if (metric == null) return null;
        if (metric is! num || !metric.isFinite || metric < 0) {
          throw const OsrmException('invalidResponse');
        }
        return metric.toDouble();
      }).toList();
    }).toList();
  }

  static void _validateCoordinate(OsrmCoordinate point) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      throw ArgumentError('Invalid routing coordinates.');
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close();
  }
}
