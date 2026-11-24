// Routes are simulated. No Supabase, GPS or public OSRM calls are made here.
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/models/matching_models.dart';
import 'package:supabase_flutter_app/models/ride.dart';
import 'package:supabase_flutter_app/services/learned_matching_service.dart';
import 'package:supabase_flutter_app/services/matching_service.dart';
import 'package:supabase_flutter_app/services/osrm_service.dart';
import 'package:supabase_flutter_app/services/road_route_service.dart';

final departure = DateTime.utc(2026, 11, 23, 18);
const pickup = OsrmCoordinate(45.43, -75.68);
const dropoff = OsrmCoordinate(45.47, -75.71);

Ride ride(
  String id, {
  double price = 10,
  int seats = 3,
  String status = 'available',
  bool validCoordinates = true,
  DateTime? time,
}) => Ride(
  id: id,
  driverId: 'driver-$id',
  originLat: validCoordinates ? 45.42 : 0,
  originLng: validCoordinates ? -75.69 : 0,
  destinationLat: 45.48,
  destinationLng: -75.70,
  departureTime: time ?? departure,
  availableSeats: seats,
  pricePerSeat: price,
  vehicleType: 'sedan',
  status: status,
);

PassengerRequest passenger({bool pet = false}) => PassengerRequest(
  id: 'passenger',
  passengerName: 'Passenger',
  pickupLatitude: pickup.latitude,
  pickupLongitude: pickup.longitude,
  dropoffLatitude: dropoff.latitude,
  dropoffLongitude: dropoff.longitude,
  preferredTime: departure,
  isSmoker: false,
  hasPet: pet,
  hasLargeLuggage: false,
);

RoadRouteDetour detour(String id, {double km = 1, double minutes = 5}) =>
    RoadRouteDetour(
      rideId: id,
      extraDistanceMeters: km * 1000,
      extraDurationSeconds: minutes * 60,
    );

class FixedDetours extends RoadRouteService {
  FixedDetours(this.results);

  final List<RoadRouteDetour> results;
  List<Ride> receivedCandidates = [];
  int calls = 0;

  @override
  Future<List<RoadRouteDetour>> calculateDetours({
    required List<Ride> candidates,
    required OsrmCoordinate pickup,
    required OsrmCoordinate dropoff,
  }) async {
    calls++;
    receivedCandidates = List.of(candidates);
    return results;
  }
}

LearnedMatchingService priceOnlyModel() => LearnedMatchingService.fromJson({
  'source': 'synthetic',
  'features': ['detour_min', 'time_gap_min', 'pref_score', 'price'],
  'feature_units': {
    'detour_min': 'minutes',
    'time_gap_min': 'whole minutes',
    'pref_score': 'points from 0 to 15',
    'price': 'CAD',
  },
  'coefficients': {
    'detour_min': 0,
    'time_gap_min': 0,
    'pref_score': 0,
    'price': -0.1,
  },
  'intercept': 0,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const matching = MatchingService();

  FixedDetours routing(List<RoadRouteDetour> results) {
    final service = FixedDetours(results);
    addTearDown(service.close);
    return service;
  }

  Future<HybridRideSearch> rank(
    List<Ride> candidates,
    FixedDetours service, {
    LearnedMatchPredictor? predictor,
    PassengerRequest? request,
  }) => matching.rankRides(
    candidates: candidates,
    request: request ?? passenger(),
    pickup: pickup,
    dropoff: dropoff,
    routingService: service,
    learnedPredictor: predictor,
  );

  test('keeps rule ranking unchanged when no predictor is supplied', () async {
    final result = await rank([
      ride('expensive', price: 50),
      ride('cheap', price: 5),
    ], routing([detour('expensive', km: 1), detour('cheap', km: 5)]));
    expect(result.matches.map((item) => item.ride.id), ['expensive', 'cheap']);
    expect(result.matches.map((item) => item.match.score), [96.7, 83.3]);
    for (final item in result.matches) {
      expect(item.rankingScore, item.match.score);
      expect(item.learnedProbability, isNull);
      expect(item.usesLearnedScore, isFalse);
    }
  });

  test(
    'can rank by the learned model without overwriting rule scores',
    () async {
      final model = priceOnlyModel();
      final result = await rank(
        [ride('expensive', price: 50), ride('cheap', price: 5)],
        routing([detour('expensive', km: 1), detour('cheap', km: 5)]),
        predictor: model.predictProbability,
      );
      expect(result.matches.map((item) => item.ride.id), [
        'cheap',
        'expensive',
      ]);
      expect(result.matches.map((item) => item.match.score), [83.3, 96.7]);
      for (final item in result.matches) {
        expect(item.usesLearnedScore, isTrue);
        expect(item.rankingScore, item.learnedProbability! * 100);
      }
      expect(
        result.matches.first.learnedProbability,
        closeTo(0.3775406687981454, 1e-12),
      );
    },
  );

  test(
    'passes minutes, whole-minute gap, preference points and price',
    () async {
      final received = <Map<String, num>>[];
      final result = await rank(
        [
          ride(
            'offer',
            price: 27.5,
            time: departure.add(const Duration(minutes: 19, seconds: 59)),
          ),
        ],
        routing([detour('offer', km: 2, minutes: 7.5)]),
        request: passenger(pet: true),
        predictor:
            ({
              required double detourMinutes,
              required int timeGapMinutes,
              required double preferenceScore,
              required double price,
            }) {
              received.add({
                'detour': detourMinutes,
                'time': timeGapMinutes,
                'preferences': preferenceScore,
                'price': price,
              });
              return 0.6;
            },
      );
      expect(result.matches, hasLength(1));
      expect(received, [
        {'detour': 7.5, 'time': 19, 'preferences': 10.0, 'price': 27.5},
      ]);
    },
  );

  test('applies the same exclusions before invoking the predictor', () async {
    var predictions = 0;
    final service = routing([
      detour('valid', km: 2),
      detour('far', km: 15.01),
      detour('zero', km: 15),
    ]);
    final result = await rank(
      [
        ride('valid'),
        ride('sold', seats: 0),
        ride('cancelled', status: 'cancelled'),
        ride('no-coordinates', validCoordinates: false),
        ride('far'),
        ride('zero', time: departure.add(const Duration(hours: 2))),
        ride('no-route'),
      ],
      service,
      request: passenger(pet: true),
      predictor:
          ({
            required double detourMinutes,
            required int timeGapMinutes,
            required double preferenceScore,
            required double price,
          }) {
            predictions++;
            return 0.99;
          },
    );
    expect(result.matches.map((item) => item.ride.id), ['valid']);
    expect(result.excludedCount, 6);
    expect(predictions, 1);
    expect(service.receivedCandidates.map((item) => item.id), [
      'valid',
      'far',
      'zero',
      'no-route',
    ]);
  });

  test('keeps the inclusive 15 km boundary in learned mode', () async {
    final model = priceOnlyModel();
    final result = await rank(
      [ride('boundary'), ride('outside')],
      routing([detour('boundary', km: 15), detour('outside', km: 15.001)]),
      predictor: model.predictProbability,
    );
    expect(result.matches.map((item) => item.ride.id), ['boundary']);
    expect(result.excludedCount, 1);
  });

  test(
    'keeps duration, departure and ID tie breakers for equal outputs',
    () async {
      final modelJson = {
        'source': 'synthetic',
        'features': ['detour_min', 'time_gap_min', 'pref_score', 'price'],
        'feature_units': {
          'detour_min': 'minutes',
          'time_gap_min': 'whole minutes',
          'pref_score': 'points from 0 to 15',
          'price': 'CAD',
        },
        'coefficients': {
          'detour_min': 0,
          'time_gap_min': 0,
          'pref_score': 0,
          'price': 0,
        },
        'intercept': 0,
      };
      final model = LearnedMatchingService.fromJson(modelJson);
      final result = await rank(
        [
          ride('c', time: departure.add(const Duration(minutes: 20))),
          ride('b', time: departure.add(const Duration(minutes: 10))),
          ride('d'),
          ride('a', time: departure.add(const Duration(minutes: 10))),
        ],
        routing([
          detour('c'),
          detour('b'),
          detour('d', minutes: 6),
          detour('a'),
        ]),
        predictor: model.predictProbability,
      );
      expect(result.matches.map((item) => item.ride.id), ['a', 'b', 'c', 'd']);
    },
  );

  test(
    'rejects invalid predictor outputs rather than silently ranking them',
    () async {
      for (final invalid in [-0.1, 1.1, double.nan, double.infinity]) {
        await expectLater(
          rank(
            [ride('offer')],
            routing([detour('offer')]),
            predictor:
                ({
                  required double detourMinutes,
                  required int timeGapMinutes,
                  required double preferenceScore,
                  required double price,
                }) => invalid,
          ),
          throwsStateError,
        );
      }
    },
  );

  test('does not route or predict an empty candidate list', () async {
    final service = routing([]);
    final result = await rank(
      [],
      service,
      predictor:
          ({
            required double detourMinutes,
            required int timeGapMinutes,
            required double preferenceScore,
            required double price,
          }) => throw StateError('The predictor should not be called.'),
    );
    expect(result.matches, isEmpty);
    expect(result.excludedCount, 0);
    expect(service.calls, 0);
  });

  test(
    'propagates predictor failures instead of pretending rules are learned',
    () async {
      await expectLater(
        rank(
          [ride('offer')],
          routing([detour('offer')]),
          predictor:
              ({
                required double detourMinutes,
                required int timeGapMinutes,
                required double preferenceScore,
                required double price,
              }) => throw StateError('Model unavailable.'),
        ),
        throwsStateError,
      );
    },
  );
}
