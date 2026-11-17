// All HTTP responses in this suite are simulated. These tests neither query a
// real routing server nor establish real driving accuracy or search latency.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter_app/models/matching_models.dart';
import 'package:supabase_flutter_app/services/matching_service.dart';
import 'package:supabase_flutter_app/services/osrm_service.dart';

const a = OsrmCoordinate(45.42, -75.69);
const b = OsrmCoordinate(45.48, -75.70);
const pickup = OsrmCoordinate(45.43, -75.68);
const dropoff = OsrmCoordinate(45.47, -75.71);

Map<String, dynamic> response({
  int points = 2,
  Object? distance = 10000,
  Object? duration = 900,
  Object? snap = 5,
}) => {
  'code': 'Ok',
  'routes': [
    {'distance': distance, 'duration': duration},
  ],
  'waypoints': List.generate(points, (_) => {'distance': snap}),
};

http.Response jsonResponse(Object? body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class TrackingClient extends http.BaseClient {
  final _delegate = MockClient((_) async => jsonResponse(response()));
  int closeCalls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _delegate.send(request);

  @override
  void close() {
    closeCalls++;
    _delegate.close();
  }
}

RideOffer offer({int seats = 3, bool pets = true, bool trunk = true}) =>
    RideOffer(
      id: 'offer-test',
      driverName: 'Driver',
      startLatitude: a.latitude,
      startLongitude: a.longitude,
      endLatitude: b.latitude,
      endLongitude: b.longitude,
      departureTime: DateTime.utc(2026, 11, 20, 18),
      availableSeats: seats,
      allowsSmoking: false,
      acceptsPets: pets,
      hasLargeTrunk: trunk,
    );

PassengerRequest passenger({
  int minutes = 0,
  bool pet = false,
  bool luggage = false,
}) => PassengerRequest(
  id: 'passenger-test',
  passengerName: 'Passenger',
  pickupLatitude: a.latitude,
  pickupLongitude: a.longitude,
  dropoffLatitude: b.latitude,
  dropoffLongitude: b.longitude,
  preferredTime: DateTime.utc(2026, 11, 20, 18, minutes),
  isSmoker: false,
  hasPet: pet,
  hasLargeLuggage: luggage,
);

void main() {
  late OsrmService service;
  final requests = <http.Request>[];
  late Future<http.Response> Function(http.Request) reply;

  OsrmService create({
    Uri? uri,
    Duration timeout = const Duration(seconds: 1),
    Duration interval = Duration.zero,
    Duration ttl = const Duration(minutes: 5),
    int capacity = 64,
    DateTime Function()? clock,
    http.Client? client,
  }) => OsrmService(
    client:
        client ??
        MockClient((request) {
          requests.add(request);
          return reply(request);
        }),
    baseUri: uri ?? Uri.parse('https://osrm.example.test'),
    timeout: timeout,
    minimumInterval: interval,
    cacheTtl: ttl,
    maxCacheEntries: capacity,
    clock: clock,
  );

  Matcher failsWith(String code) =>
      throwsA(isA<OsrmException>().having((e) => e.code, 'code', code));

  Future<OsrmDetourEstimate> detour() => service.getDetour(
    driverStart: a,
    driverEnd: b,
    pickup: pickup,
    dropoff: dropoff,
  );

  setUp(() {
    requests.clear();
    reply = (_) async => jsonResponse(response());
    service = create();
  });
  tearDown(() => service.close());

  test(
    'route uses longitude then latitude, driving and bounded snapping',
    () async {
      final result = await service.getRoute([a, b]);
      final request = requests.single;
      expect(request.url.path, '/route/v1/driving/-75.69,45.42;-75.7,45.48');
      expect(request.url.queryParameters['overview'], 'false');
      expect(request.url.queryParameters['steps'], 'false');
      expect(request.url.queryParameters['alternatives'], 'false');
      expect(request.url.queryParameters['continue_straight'], 'false');
      expect(request.url.queryParameters['radiuses'], '1000.0;1000.0');
      expect(request.headers['user-agent'], contains('AlonzY'));
      expect(result.distanceMeters, 10000);
      expect(result.durationSeconds, 900);
    },
  );

  test('supports an endpoint with a path prefix', () async {
    service.close();
    service = create(uri: Uri.parse('https://osrm.example.test/routed-car/'));
    await service.getRoute([a, b]);
    expect(
      requests.single.url.path,
      startsWith('/routed-car/route/v1/driving/'),
    );
  });

  test(
    'detour compares direct trip against ordered pickup then dropoff',
    () async {
      reply = (request) async {
        final count = request.url.path.split(';').length;
        return jsonResponse(
          response(
            points: count,
            distance: count == 2 ? 10000 : 12500,
            duration: count == 2 ? 900 : 1200,
          ),
        );
      };
      final estimate = await detour();
      expect(requests.length, 2);
      expect(
        requests.last.url.path,
        '/route/v1/driving/-75.69,45.42;-75.68,45.43;-75.71,45.47;-75.7,45.48',
      );
      expect(estimate.extraDistanceMeters, 2500);
      expect(estimate.extraDistanceKm, 2.5);
      expect(estimate.extraDurationSeconds, 300);
      expect(estimate.extraDurationMinutes, 5);
      expect(estimate.directRoute.distanceMeters, 10000);
      expect(estimate.sharedRoute.distanceMeters, 12500);
    },
  );

  test('negative metric differences never produce a scoring bonus', () {
    const estimate = OsrmDetourEstimate(
      directRoute: OsrmRouteEstimate(
        distanceMeters: 10000,
        durationSeconds: 900,
      ),
      sharedRoute: OsrmRouteEstimate(
        distanceMeters: 9900,
        durationSeconds: 890,
      ),
    );
    expect(estimate.extraDistanceMeters, 0);
    expect(estimate.extraDurationSeconds, 0);
  });

  test('zero-length successful route is valid', () async {
    reply = (_) async =>
        jsonResponse(response(distance: 0, duration: 0, snap: 0));
    final result = await service.getRoute([a, a]);
    expect(result.distanceMeters, 0);
    expect(result.durationSeconds, 0);
  });

  for (final points in <List<OsrmCoordinate>>[
    [],
    [a],
    [a, b, a, b, a],
    [const OsrmCoordinate(91, 0), b],
    [const OsrmCoordinate(0, -181), b],
    [const OsrmCoordinate(double.nan, 0), b],
    [a, const OsrmCoordinate(0, double.infinity)],
  ]) {
    test('invalid coordinates rejected without HTTP: $points', () async {
      await expectLater(service.getRoute(points), throwsArgumentError);
      expect(requests, isEmpty);
    });
  }

  test(
    'invalid passenger coordinate prevents even the direct route request',
    () async {
      await expectLater(
        service.getDetour(
          driverStart: a,
          driverEnd: b,
          pickup: pickup,
          dropoff: const OsrmCoordinate(200, 0),
        ),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
    },
  );

  for (final code in ['NoRoute', 'NoSegment']) {
    test('$code is explicit, not a zero detour', () async {
      reply = (_) async => jsonResponse({'code': code}, status: 400);
      await expectLater(service.getRoute([a, b]), failsWith(code));
    });
  }
  for (final status in [429, 503]) {
    test('HTTP $status is not treated as a successful route', () async {
      reply = (_) async =>
          jsonResponse({'message': 'private diagnostic'}, status: status);
      await expectLater(
        service.getRoute([a, b]),
        throwsA(
          isA<OsrmException>()
              .having((e) => e.code, 'code', 'http')
              .having((e) => e.httpStatus, 'status', status),
        ),
      );
      expect(requests.length, 1); // No hidden retries against the public demo.
    });
  }

  test('HTML instead of JSON is rejected', () async {
    reply = (_) async => http.Response('<html>gateway problem</html>', 502);
    await expectLater(service.getRoute([a, b]), failsWith('http'));
  });
  test('malformed successful JSON is rejected', () async {
    reply = (_) async => http.Response('{not-json', 200);
    await expectLater(service.getRoute([a, b]), failsWith('invalidResponse'));
  });

  for (final entry in <String, Object?>{
    'missing code': {'routes': []},
    'unknown code': {'code': 'InvalidValue'},
    'JSON array': [],
    'empty routes': {'code': 'Ok', 'routes': [], 'waypoints': []},
    'invalid distance': response(distance: '10000'),
    'negative duration': response(duration: -1),
    'missing duration': response(duration: null),
    'negative distance': response(distance: -1),
    'wrong waypoint count': response(points: 4),
  }.entries) {
    test('invalid payload: ${entry.key}', () async {
      reply = (_) async => jsonResponse(entry.value);
      await expectLater(service.getRoute([a, b]), failsWith('invalidResponse'));
    });
  }

  for (final snap in <Object?>[1001, -1, '5', null]) {
    test('invalid or distant snap is rejected: $snap', () async {
      reply = (_) async => jsonResponse(response(snap: snap));
      await expectLater(service.getRoute([a, b]), failsWith('invalidSnap'));
    });
  }

  test('network errors do not leak coordinates or raw diagnostics', () async {
    reply = (_) async =>
        throw http.ClientException('private URL and diagnostic');
    await expectLater(service.getRoute([a, b]), failsWith('network'));
    try {
      await service.getRoute([a, b]);
    } catch (e) {
      expect(e.toString(), isNot(contains('private')));
      expect(e.toString(), isNot(contains('-75.69')));
    }
  });

  test('timeout terminates the wait and the queue remains usable', () async {
    service.close();
    service = create(timeout: const Duration(milliseconds: 15));
    final pending = Completer<http.Response>();
    reply = (_) => pending.future;
    await expectLater(service.getRoute([a, b]), failsWith('timeout'));
    pending.complete(jsonResponse(response()));
    reply = (_) async => jsonResponse(response());
    expect((await service.getRoute([a, b])).distanceMeters, 10000);
  });

  test('identical successful route is cached', () async {
    final first = await service.getRoute([a, b]);
    final second = await service.getRoute([a, b]);
    expect(identical(first, second), isTrue);
    expect(requests.length, 1);
  });

  test('in-flight identical calls share one request', () async {
    final pending = Completer<http.Response>();
    reply = (_) => pending.future;
    final first = service.getRoute([a, b]);
    final second = service.getRoute([a, b]);
    pending.complete(jsonResponse(response()));
    final results = await Future.wait([first, second]);
    expect(identical(results.first, results.last), isTrue);
    expect(requests.length, 1);
  });

  test('expired cache entry is fetched again', () async {
    var now = DateTime.utc(2026, 11, 20);
    service.close();
    service = create(clock: () => now, ttl: const Duration(minutes: 1));
    await service.getRoute([a, b]);
    now = now.add(const Duration(minutes: 1));
    await service.getRoute([a, b]);
    expect(requests.length, 2);
  });

  test(
    'cache capacity is bounded and evicts least recently used route',
    () async {
      service.close();
      service = create(capacity: 2);
      await service.getRoute([a, b]);
      await service.getRoute([b, a]);
      await service.getRoute([a, b]); // This one becomes most recently used.
      await service.getRoute([pickup, dropoff]);
      await service.getRoute([a, b]);
      expect(requests.length, 3);
      await service.getRoute([b, a]);
      expect(requests.length, 4);
    },
  );

  test('an OSRM error is not cached and does not poison the queue', () async {
    reply = (_) async => jsonResponse({'code': 'NoRoute'}, status: 400);
    await expectLater(service.getRoute([a, b]), failsWith('NoRoute'));
    reply = (_) async => jsonResponse(response());
    await service.getRoute([a, b]);
    expect(requests.length, 2);
  });

  test('different requests respect the configured minimum interval', () async {
    service.close();
    service = create(interval: const Duration(milliseconds: 25));
    final elapsed = Stopwatch()..start();
    final starts = <int>[];
    reply = (_) async {
      starts.add(elapsed.elapsedMilliseconds);
      return jsonResponse(response());
    };
    await Future.wait([
      service.getRoute([a, b]),
      service.getRoute([b, a]),
    ]);
    expect(starts.last - starts.first, greaterThanOrEqualTo(24));
  });

  test('close rejects subsequent requests without network', () async {
    service.close();
    service.close();
    await expectLater(service.getRoute([a, b]), failsWith('closed'));
    expect(requests, isEmpty);
  });

  test('close leaves an externally supplied HTTP client usable', () async {
    final client = TrackingClient();
    service.close();
    expect(client.closeCalls, 0);
    service = create(client: client);
    service.close();
    expect((await client.get(Uri.https('example.test', ''))).statusCode, 200);
    client.close();
    expect(client.closeCalls, 1);
  });

  test('close before queued work starts prevents all HTTP calls', () async {
    final first = service.getRoute([a, b]);
    final second = service.getRoute([b, a]);
    final checks = Future.wait([
      expectLater(first, failsWith('closed')),
      expectLater(second, failsWith('closed')),
    ]);
    service.close();
    await checks;
    expect(requests, isEmpty);
  });

  test('close during a request discards its result and queued work', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    reply = (_) {
      started.complete();
      return pending.future;
    };
    final first = service.getRoute([a, b]);
    final second = service.getRoute([b, a]);
    final checks = Future.wait([
      expectLater(first, failsWith('closed')),
      expectLater(second, failsWith('closed')),
    ]);
    await started.future;
    service.close();
    pending.complete(jsonResponse(response()));
    await checks;
    expect(requests.length, 1);
  });

  test('configuration rejects invalid endpoint or limits', () {
    for (final uri in [
      'file:///tmp/osrm',
      'https://user:secret@example.test',
      'https://example.test?token=test',
      'https://example.test#fragment',
    ]) {
      expect(() => create(uri: Uri.parse(uri)), throwsArgumentError);
    }
    expect(() => create(timeout: Duration.zero), throwsArgumentError);
    expect(() => create(capacity: -1), throwsArgumentError);
    expect(
      () => create(interval: const Duration(seconds: -1)),
      throwsArgumentError,
    );
  });

  test('original score remains synchronous with its original rules', () {
    const matching = MatchingService();
    expect(matching.calculateMatchScore(offer(), passenger()).score, 100);
    expect(
      matching.calculateMatchScore(offer(), passenger(minutes: 30)).score,
      86,
    );
    expect(
      matching
          .calculateMatchScore(offer(pets: false), passenger(pet: true))
          .score,
      75,
    );
    expect(
      matching
          .calculateMatchScore(
            offer(pets: false, trunk: false),
            passenger(pet: true, luggage: true),
          )
          .score,
      70,
    );
    expect(
      matching.calculateMatchScore(offer(seats: 0), passenger()).isEligible,
      isFalse,
    );
    expect(requests, isEmpty);
  });

  test(
    'road score actually uses additional distance, not total route length',
    () async {
      reply = (request) async {
        final count = request.url.path.split(';').length;
        return jsonResponse(
          response(
            points: count,
            distance: count == 2 ? 10000 : 16000,
            duration: count == 2 ? 900 : 1500,
          ),
        );
      };
      final result = await const MatchingService().calculateRoadMatchScore(
        offer(),
        passenger(),
        routingService: service,
      );
      expect(result.match.detourKm, 6);
      expect(result.match.score, 80); // 50*(1-6/15) + 35 + 15
      expect(
        result.match.timeDifferenceMinutes,
        0,
      ); // Departure gap, not extra drive time.
      expect(result.detour!.extraDurationMinutes, 10);
      expect(
        const MatchingService().calculateMatchScore(offer(), passenger()).score,
        100,
      );
    },
  );

  test(
    'road scoring preserves preference penalties and departure gap',
    () async {
      reply = (request) async =>
          jsonResponse(response(points: request.url.path.split(';').length));
      final result = await const MatchingService().calculateRoadMatchScore(
        offer(pets: false),
        passenger(pet: true, minutes: 30),
        routingService: service,
      );
      expect(result.match.score, 61); // 50 + 21 + 10 - 20
      expect(result.match.timeDifferenceMinutes, 30);
    },
  );

  test(
    'no seats skips both OSRM calls and has no fabricated road estimate',
    () async {
      final result = await const MatchingService().calculateRoadMatchScore(
        offer(seats: 0),
        passenger(),
        routingService: service,
      );
      expect(result.match.score, 0);
      expect(result.match.isEligible, isFalse);
      expect(result.detour, isNull);
      expect(requests, isEmpty);
    },
  );

  test(
    'road scoring does not silently fall back to a Haversine score',
    () async {
      reply = (_) async => jsonResponse({'code': 'NoRoute'}, status: 400);
      await expectLater(
        const MatchingService().calculateRoadMatchScore(
          offer(),
          passenger(),
          routingService: service,
        ),
        failsWith('NoRoute'),
      );
      expect(requests.length, 1);
    },
  );
}
