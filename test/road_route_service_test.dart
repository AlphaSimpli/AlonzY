import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter_app/models/matching_models.dart';
import 'package:supabase_flutter_app/models/ride.dart';
import 'package:supabase_flutter_app/services/matching_service.dart';
import 'package:supabase_flutter_app/services/osrm_service.dart';
import 'package:supabase_flutter_app/services/road_route_service.dart';

const pickup = OsrmCoordinate(45.42, -75.69);
const dropoff = OsrmCoordinate(45.48, -75.70);

Map<String, dynamic> matrixResponse() => {
  'code': 'Ok',
  'durations': [
    [100, 600, 900],
    [0, 400, 500],
    [300, 0, 500],
  ],
  'distances': [
    [1000, 6000, 10000],
    [0, 4000, 7000],
    [6000, 0, 6000],
  ],
};

Ride testRide({String id = 'ride-1'}) => Ride.fromJson({
  'id': id,
  'driver_id': 'driver-1',
  'origin_lat': 45.40,
  'origin_lng': -75.69,
  'destination_lat': 45.50,
  'destination_lng': -75.70,
  'departure_time': '2026-11-20T12:00:00Z',
  'available_seats': 2,
  'price_per_seat': 20,
  'vehicle_type': 'sedan',
  'status': 'available',
  'pets_allowed': true,
  'luggage_policy': 'large',
});

void main() {
  late List<http.Request> requests;
  late RoadRouteService service;

  setUp(() {
    requests = [];
    service = RoadRouteService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(matrixResponse()),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUri: Uri.parse('https://osrm.example.test'),
    );
  });

  tearDown(() => service.close());

  test('requests all candidate legs in one OSRM table matrix', () async {
    final result = await service.calculateDetours(
      candidates: [testRide()],
      pickup: pickup,
      dropoff: dropoff,
    );

    expect(requests, hasLength(1));
    expect(requests.single.url.path, contains('/table/v1/driving/'));
    expect(
      requests.single.url.queryParameters['annotations'],
      'duration,distance',
    );
    expect(requests.single.url.queryParameters['sources'], '0;1;2');
    expect(requests.single.url.queryParameters['destinations'], '1;2;3');
    expect(result.single.rideId, 'ride-1');
    expect(result.single.extraDurationSeconds, 100);
    expect(result.single.extraDurationMinutes, closeTo(1.6667, 0.001));
    expect(result.single.extraDistanceMeters, 1000);
  });

  test(
    'hybrid matching scores the matrix detour and returns a ranked offer',
    () async {
      final result = await const MatchingService().rankRides(
        candidates: [testRide()],
        request: PassengerRequest(
          id: 'passenger-1',
          passengerName: '',
          pickupLatitude: pickup.latitude,
          pickupLongitude: pickup.longitude,
          dropoffLatitude: dropoff.latitude,
          dropoffLongitude: dropoff.longitude,
          preferredTime: DateTime.utc(2026, 11, 20, 12),
          isSmoker: false,
          hasPet: true,
          hasLargeLuggage: true,
        ),
        pickup: pickup,
        dropoff: dropoff,
        routingService: service,
      );
      expect(result.matches.single.ride.id, 'ride-1');
      expect(result.matches.single.match.score, lessThan(100));
      expect(result.matches.single.preferenceScore, 15);
    },
  );

  test(
    'batches up to 100 offers within the 50-coordinate OSRM limit',
    () async {
      service.close();
      service = RoadRouteService(
        client: MockClient((request) async {
          requests.add(request);
          final sourceCount = request.url.queryParameters['sources']!
              .split(';')
              .length;
          final destinationCount = request.url.queryParameters['destinations']!
              .split(';')
              .length;
          final matrix = List<List<int>>.generate(
            sourceCount,
            (_) => List<int>.filled(destinationCount, 300),
          );
          return http.Response(
            jsonEncode({
              'code': 'Ok',
              'durations': matrix,
              'distances': matrix,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        baseUri: Uri.parse('https://osrm.example.test'),
      );

      final result = await service.calculateDetours(
        candidates: List.generate(100, (index) => testRide(id: 'ride-$index')),
        pickup: pickup,
        dropoff: dropoff,
      );

      expect(result, hasLength(100));
      expect(
        requests,
        hasLength((100 / RoadRouteService.maxCandidatesPerBatch).ceil()),
      );
      for (final request in requests) {
        final coordinates = Uri.decodeComponent(
          request.url.pathSegments.last,
        ).split(';');
        expect(
          coordinates.length,
          lessThanOrEqualTo(RoadRouteService.maxCoordinatesPerRequest),
        );
      }
    },
  );

  test(
    'rejects more than 100 candidates without making OSRM requests',
    () async {
      await expectLater(
        service.calculateDetours(
          candidates: List.generate(
            101,
            (index) => testRide(id: 'ride-$index'),
          ),
          pickup: pickup,
          dropoff: dropoff,
        ),
        throwsA(
          isA<OsrmException>().having(
            (error) => error.code,
            'code',
            'tooManyCandidates',
          ),
        ),
      );
      expect(requests, isEmpty);
    },
  );

  test('rejects malformed or dimensionally incomplete matrices', () async {
    service.close();
    service = RoadRouteService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'Ok', 'durations': [], 'distances': []}),
          200,
        ),
      ),
      baseUri: Uri.parse('https://osrm.example.test'),
    );
    await expectLater(
      service.calculateDetours(
        candidates: [testRide()],
        pickup: pickup,
        dropoff: dropoff,
      ),
      throwsA(
        isA<OsrmException>().having(
          (error) => error.code,
          'code',
          'invalidResponse',
        ),
      ),
    );
  });

  test(
    'excludes an unroutable candidate represented by null matrix cells',
    () async {
      service.close();
      final response = matrixResponse();
      response['durations'] = [
        [null, 600, 900],
        [0, 400, 500],
        [300, 0, 500],
      ];
      service = RoadRouteService(
        client: MockClient(
          (_) async => http.Response(jsonEncode(response), 200),
        ),
        baseUri: Uri.parse('https://osrm.example.test'),
      );
      final result = await service.calculateDetours(
        candidates: [testRide()],
        pickup: pickup,
        dropoff: dropoff,
      );
      expect(result, isEmpty);
    },
  );
}
