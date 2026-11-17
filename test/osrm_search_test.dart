// Simulated HTTP throughout. No real Supabase, geocoder or OSRM is contacted.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/maps/map_types.dart';
import 'package:supabase_flutter_app/models/ride.dart';
import 'package:supabase_flutter_app/screens/search_rides_page.dart';
import 'package:supabase_flutter_app/services/database_service.dart';
import 'package:supabase_flutter_app/services/osrm_service.dart';
import 'package:supabase_flutter_app/services/ride_routing_service.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';
import 'package:supabase_flutter_app/widgets/location_autocomplete_field.dart';

Map<String, dynamic> rideRow(
  int index, {
  int seats = 3,
  double? latitude,
  DateTime? departure,
}) => {
  'id': 'ride-$index',
  'driver_id': 'driver-$index',
  'origin_city': 'Ottawa',
  'destination_city': 'Gatineau',
  'origin_address': 'Origin $index',
  'destination_address': 'Destination $index',
  'origin_lat': latitude ?? 45.40 + index * .01,
  'origin_lng': -75.69,
  'destination_lat': 45.48,
  'destination_lng': -75.70,
  'departure_time':
      (departure ?? DateTime.now().add(Duration(hours: index + 1)))
          .toIso8601String(),
  'available_seats': seats,
  'price_per_seat': 10.5,
  'status': 'available',
  'vehicle_type': 'Sedan',
};

http.Response routeReply(
  http.Request request, {
  double extraMeters = 2000,
  double extraSeconds = 300,
}) {
  final points = request.url.path.split(';').length;
  return http.Response(
    jsonEncode({
      'code': 'Ok',
      'routes': [
        {
          'distance': 10000 + (points == 4 ? extraMeters : 0),
          'duration': 900 + (points == 4 ? extraSeconds : 0),
        },
      ],
      'waypoints': List.generate(points, (_) => {'distance': 2}),
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  late OsrmService osrm;
  late RideRoutingService router;
  final routeRequests = <http.Request>[];
  late Future<http.Response> Function(http.Request) routingReply;
  const pickup = OsrmCoordinate(45.42, -75.69);
  const dropoff = OsrmCoordinate(45.48, -75.70);

  void initializeRouting() {
    osrm = OsrmService(
      client: MockClient((request) {
        routeRequests.add(request);
        return routingReply(request);
      }),
      baseUri: Uri.https('routing.example.test', ''),
      minimumInterval: Duration.zero,
    );
    router = RideRoutingService(routingService: osrm);
  }

  setUp(() {
    routeRequests.clear();
    routingReply = (request) async => routeReply(request);
    initializeRouting();
  });
  tearDown(() {
    router.close();
    osrm.close();
  });

  Future<RoutedRideSearch> rank(
    List<Ride> rides, {
    bool Function()? cancelled,
  }) => router.rank(
    candidates: rides,
    pickup: pickup,
    dropoff: dropoff,
    isCancelled: cancelled,
  );

  group('routing shortlist', () {
    test('empty shortlist makes no HTTP call', () async {
      final result = await rank([]);
      expect(result.rides, isEmpty);
      expect(result.excludedCount, 0);
      expect(routeRequests, isEmpty);
    });
    test(
      'too many candidates rejected before HTTP, without truncation',
      () async {
        await expectLater(
          rank(List.generate(6, (i) => Ride.fromJson(rideRow(i + 1)))),
          throwsA(
            isA<OsrmException>().having(
              (e) => e.code,
              'code',
              'tooManyCandidates',
            ),
          ),
        );
        expect(routeRequests, isEmpty);
      },
    );
    test('sorts by extra distance, not departure', () async {
      routingReply = (request) async {
        final lat = double.parse(
          request.url.path.split('/').last.split(';').first.split(',').last,
        );
        return routeReply(request, extraMeters: lat < 45.415 ? 4000 : 1000);
      };
      final result = await rank([
        Ride.fromJson(rideRow(1)),
        Ride.fromJson(rideRow(2)),
      ]);
      expect(result.rides.map((r) => r.ride.id), ['ride-2', 'ride-1']);
      expect(result.rides.first.detour.extraDistanceKm, 1);
      expect(routeRequests.length, 4);
    });
    test('equal distance breaks ties by additional duration', () async {
      routingReply = (request) async {
        final lat = double.parse(
          request.url.path.split('/').last.split(';').first.split(',').last,
        );
        return routeReply(request, extraSeconds: lat < 45.415 ? 600 : 60);
      };
      final result = await rank([
        Ride.fromJson(rideRow(1)),
        Ride.fromJson(rideRow(2)),
      ]);
      expect(result.rides.map((r) => r.ride.id), ['ride-2', 'ride-1']);
    });
    test('equal metrics break ties by departure, then id', () async {
      final sameTime = DateTime.utc(2026, 11, 20, 18);
      final rows = [
        rideRow(2, departure: sameTime),
        rideRow(1, departure: sameTime),
        rideRow(3, departure: sameTime.subtract(const Duration(hours: 1))),
      ];
      final result = await rank(rows.map(Ride.fromJson).toList());
      expect(result.rides.map((r) => r.ride.id), [
        'ride-3',
        'ride-1',
        'ride-2',
      ]);
    });
    for (final extra in [15000.0, 15000.1]) {
      test('explicit 15 km boundary: $extra meters', () async {
        routingReply = (request) async =>
            routeReply(request, extraMeters: extra);
        final result = await rank([Ride.fromJson(rideRow(1))]);
        expect(result.rides.length, extra <= 15000 ? 1 : 0);
        expect(result.excludedCount, extra <= 15000 ? 0 : 1);
      });
    }
    for (final code in ['NoRoute', 'NoSegment']) {
      test('$code excludes the offer and reports its count', () async {
        routingReply = (_) async =>
            http.Response(jsonEncode({'code': code}), 400);
        final result = await rank([Ride.fromJson(rideRow(1))]);
        expect(result.rides, isEmpty);
        expect(result.excludedCount, 1);
      });
    }
    test(
      'outage after success rejects entire ranking, not partial success',
      () async {
        routingReply = (request) async => routeRequests.length == 3
            ? http.Response('unavailable', 503)
            : routeReply(request);
        await expectLater(
          rank(List.generate(3, (i) => Ride.fromJson(rideRow(i + 1)))),
          throwsA(isA<OsrmException>().having((e) => e.code, 'code', 'http')),
        );
        expect(routeRequests.length, 3);
      },
    );
    for (final latitude in [91.0, double.nan, double.infinity]) {
      test('invalid offer latitude $latitude excluded before HTTP', () async {
        final result = await rank([
          Ride.fromJson(rideRow(1, latitude: latitude)),
        ]);
        expect(result.excludedCount, 1);
        expect(routeRequests, isEmpty);
      });
    }
    test(
      'missing-coordinate sentinel and unavailable offers do not call OSRM',
      () async {
        final missing = rideRow(1)
          ..['origin_lat'] = null
          ..['origin_lng'] = null;
        final result = await rank([
          Ride.fromJson(missing),
          Ride.fromJson(rideRow(2, seats: 0)),
          Ride.fromJson(rideRow(3)..['status'] = 'cancelled'),
        ]);
        expect(result.excludedCount, 3);
        expect(routeRequests, isEmpty);
      },
    );
    test('invalid passenger coordinates abort before HTTP', () async {
      await expectLater(
        router.rank(
          candidates: [Ride.fromJson(rideRow(1))],
          pickup: const OsrmCoordinate(91, 0),
          dropoff: dropoff,
        ),
        throwsArgumentError,
      );
      expect(routeRequests, isEmpty);
    });
    test('cache is reused between searches', () async {
      final rides = [Ride.fromJson(rideRow(1))];
      await rank(rides);
      await rank(rides);
      expect(routeRequests.length, 2);
    });
    test('cancellation between the two legs stops further requests', () async {
      var cancelled = false;
      routingReply = (request) async {
        cancelled = true;
        return routeReply(request);
      };
      await expectLater(
        rank([Ride.fromJson(rideRow(1))], cancelled: () => cancelled),
        throwsA(
          isA<OsrmException>().having((e) => e.code, 'code', 'cancelled'),
        ),
      );
      expect(routeRequests.length, 1);
    });
    test('closing wrapper does not close injected OSRM client', () async {
      router.close();
      router.close();
      expect((await osrm.getRoute([pickup, dropoff])).distanceMeters, 10000);
      await expectLater(rank([]), throwsA(isA<OsrmException>()));
    });
    test('caller list is not sorted and result list is immutable', () async {
      final input = [Ride.fromJson(rideRow(2)), Ride.fromJson(rideRow(1))];
      final result = await rank(input);
      expect(input.map((r) => r.id), ['ride-2', 'ride-1']);
      expect(() => result.rides.clear(), throwsUnsupportedError);
    });
  });

  group('search integration', () {
    late SupabaseClient client;
    late DatabaseService database;
    final databaseRequests = <http.Request>[];
    late List<Map<String, dynamic>> rows;
    Completer<http.Response>? pendingRoute;

    setUp(() {
      databaseRequests.clear();
      rows = [rideRow(1)];
      pendingRoute = null;
      client = SupabaseClient(
        'https://example.supabase.co',
        'test-public-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          databaseRequests.add(request);
          return http.Response(
            jsonEncode(rows),
            200,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      database = DatabaseService(client: client);
    });
    tearDown(() async {
      if (pendingRoute != null && !pendingRoute!.isCompleted) {
        pendingRoute!.complete(http.Response('closed', 503));
      }
      await client.dispose();
    });

    Future<AppLocalizations> open(
      WidgetTester tester, {
      String language = 'fr',
      Size size = const Size(1280, 1100),
      double scale = 1,
    }) async {
      // Construct the asynchronous queue inside testWidgets' FakeAsync zone.
      // A precompleted Future created by the outer (real-time) setUp cannot
      // reliably be advanced by the widget test's virtual microtask clock.
      router.close();
      osrm.close();
      initializeRouting();
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: SearchRidesPage(
            databaseService: database,
            routingService: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return AppLocalizations.delegate.load(Locale(language));
    }

    Future<void> enable(WidgetTester tester) async {
      final toggle = find.byType(SwitchListTile);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
    }

    Future<void> selectRoute(
      WidgetTester tester,
      AppLocalizations strings, {
      bool destination = true,
      bool date = true,
    }) async {
      final fields = tester
          .widgetList<LocationAutocompleteField>(
            find.byType(LocationAutocompleteField),
          )
          .toList();
      fields.first.controller.text = 'Ottawa centre';
      fields.first.onSelected!(
        const MapLocation(45.42, -75.69),
        'Ottawa centre',
        'Ottawa',
      );
      if (destination) {
        fields.last.controller.text = 'Gatineau centre';
        fields.last.onSelected!(
          const MapLocation(45.48, -75.70),
          'Gatineau centre',
          'Gatineau',
        );
      }
      await tester.pump();
      if (!date) return;
      await tester.ensureVisible(find.text(strings.searchAnyDate));
      await tester.tap(find.text(strings.searchAnyDate));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(DatePickerDialog));
      await tester.tap(find.text(MaterialLocalizations.of(ctx).okButtonLabel));
      await tester.pumpAndSettle();
    }

    Future<void> submit(
      WidgetTester tester,
      AppLocalizations strings, {
      bool settle = true,
    }) async {
      final button = find.widgetWithText(ElevatedButton, strings.searchSubmit);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }
    }

    for (final language in ['fr', 'en']) {
      testWidgets('normal mode makes no OSRM request in $language', (
        tester,
      ) async {
        final strings = await open(tester, language: language);
        await selectRoute(tester, strings);
        await submit(tester, strings);
        expect(
          databaseRequests.single.url.path,
          '/rest/v1/rpc/search_ride_candidates',
        );
        expect(routeRequests, isEmpty);
        expect(find.text(strings.searchRoadResults(1, 0)), findsNothing);
        expect(find.text(strings.searchEmptyTitle), findsOneWidget);
        expect(find.text(strings.searchNearbyHint), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
      testWidgets('OSRM requires addresses and date in $language', (
        tester,
      ) async {
        final strings = await open(tester, language: language);
        await enable(tester);
        await submit(tester, strings);
        expect(find.text(strings.searchRoadRequired), findsOneWidget);
        expect(databaseRequests, isEmpty);
        expect(routeRequests, isEmpty);
      });
      testWidgets(
        'database then OSRM displays estimate and attribution in $language',
        (tester) async {
          final strings = await open(tester, language: language);
          await selectRoute(tester, strings);
          await enable(tester);
          await submit(tester, strings);
          expect(
            databaseRequests.single.url.path,
            '/rest/v1/rpc/search_ride_candidates',
          );
          expect(routeRequests.length, 2);
          expect(find.text(strings.searchNearbyHint), findsNothing);
          expect(find.text(strings.searchRoadNearbyHint), findsOneWidget);
          expect(find.text(strings.searchRoadResults(1, 0)), findsOneWidget);
          // The returned destination is not the selected text: OSRM mode must
          // bypass only the old destination text filter.
          final badge = strings.searchRoadDetour(
            NumberFormat('0.0', language).format(2),
            5,
          );
          await tester.ensureVisible(find.text(badge));
          expect(find.text(badge), findsOneWidget);
          expect(find.text(strings.searchRoadAttribution), findsOneWidget);
          expect(find.textContaining('%'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets('cap refuses six offers without routing in $language', (
        tester,
      ) async {
        rows = List.generate(6, (i) => rideRow(i + 1));
        final strings = await open(tester, language: language);
        await selectRoute(tester, strings);
        await enable(tester);
        await submit(tester, strings);
        expect(
          find.text(strings.searchRoadTooMany(5)),
          findsAtLeastNWidgets(1),
        );
        expect(routeRequests, isEmpty);
      });
      testWidgets(
        'network failure has explicit error and no fallback in $language',
        (tester) async {
          routingReply = (_) async =>
              throw http.ClientException('private coordinate URL');
          final strings = await open(tester, language: language);
          await selectRoute(tester, strings);
          await enable(tester);
          await submit(tester, strings);
          expect(find.text(strings.searchRoadFailed), findsAtLeastNWidgets(1));
          expect(find.textContaining('private coordinate URL'), findsNothing);
          expect(find.text(strings.searchRoadResults(1, 0)), findsNothing);
          expect(find.text(strings.searchEmptyTitle), findsNothing);
          expect(find.text(strings.searchRoadNearbyHint), findsOneWidget);
          expect(find.text('Origin 1'), findsNothing);
        },
      );
      testWidgets('no route excluded, not reported as success in $language', (
        tester,
      ) async {
        routingReply = (_) async => http.Response('{"code":"NoRoute"}', 400);
        final strings = await open(tester, language: language);
        await selectRoute(tester, strings);
        await enable(tester);
        await submit(tester, strings);
        expect(find.text(strings.searchRoadResults(0, 1)), findsOneWidget);
        expect(find.text(strings.searchRoadEmpty), findsOneWidget);
      });
      testWidgets('small screen with enlarged text in $language', (
        tester,
      ) async {
        final strings = await open(
          tester,
          language: language,
          size: const Size(375, 900),
          scale: 1.4,
        );
        await selectRoute(tester, strings);
        await enable(tester);
        await submit(tester, strings);
        final badge = strings.searchRoadDetour(
          NumberFormat('0.0', language).format(2),
          5,
        );
        await tester.ensureVisible(find.text(badge));
        await tester.pumpAndSettle();
        expect(find.text(badge), findsOneWidget);
        await tester.ensureVisible(find.text(strings.searchRoadAttribution));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('editing selected destination invalidates OSRM eligibility', (
      tester,
    ) async {
      final strings = await open(tester);
      await selectRoute(tester, strings);
      await enable(tester);
      tester
              .widget<LocationAutocompleteField>(
                find.byType(LocationAutocompleteField).last,
              )
              .controller
              .text =
          'Edited manually';
      await submit(tester, strings);
      expect(find.text(strings.searchRoadRequired), findsOneWidget);
      expect(databaseRequests, isEmpty);
    });
    testWidgets('missing date blocks routing before the database', (
      tester,
    ) async {
      final strings = await open(tester);
      await selectRoute(tester, strings, date: false);
      await enable(tester);
      await submit(tester, strings);
      expect(find.text(strings.searchRoadRequired), findsOneWidget);
      expect(databaseRequests, isEmpty);
    });
    testWidgets('mode change clears badges and allows normal search', (
      tester,
    ) async {
      final strings = await open(tester);
      await selectRoute(tester, strings);
      await enable(tester);
      await submit(tester, strings);
      expect(routeRequests.length, 2);
      await enable(tester);
      expect(find.text(strings.searchRoadResults(1, 0)), findsNothing);
      await submit(tester, strings);
      expect(databaseRequests.length, 2);
      expect(routeRequests.length, 2);
    });
    testWidgets('price, date and seats remain in PostGIS prefilter', (
      tester,
    ) async {
      final strings = await open(tester);
      await selectRoute(tester, strings);
      await enable(tester);
      final price = find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.labelText == strings.searchMaxPrice,
      );
      await tester.ensureVisible(price);
      await tester.enterText(price, '12,50');
      await tester.ensureVisible(find.byTooltip(strings.searchMoreSeats));
      await tester.tap(find.byTooltip(strings.searchMoreSeats));
      await submit(tester, strings);
      final body = jsonDecode(databaseRequests.single.body) as Map;
      expect(body['p_max_price'], 12.5);
      expect(body['p_min_seats'], 2);
      expect(body['p_origin_lat'], 45.42);
      expect(body['p_departure_from'], isNotNull);
      expect(body['p_departure_until'], isNotNull);
    });
    testWidgets(
      'pending OSRM blocks repeat search; leaving cancels next request',
      (tester) async {
        pendingRoute = Completer<http.Response>();
        routingReply = (_) => pendingRoute!.future;
        final strings = await open(tester);
        await selectRoute(tester, strings);
        await enable(tester);
        await submit(tester, strings, settle: false);
        await tester.pump(const Duration(milliseconds: 30));
        expect(find.text(strings.searchRoadLoading), findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
          isNull,
        );
        expect(routeRequests.length, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        pendingRoute!.complete(routeReply(routeRequests.first));
        await tester.pump();
        await tester.pump();
        expect(routeRequests.length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
