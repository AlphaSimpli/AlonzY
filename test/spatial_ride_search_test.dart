import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/maps/map_types.dart';
import 'package:supabase_flutter_app/screens/search_rides_page.dart';
import 'package:supabase_flutter_app/services/database_service.dart';
import 'package:supabase_flutter_app/widgets/location_autocomplete_field.dart';

// These tests mock HTTP only. They do not validate a live Supabase session,
// deployed RLS policies or PostGIS calculations.
Map<String, dynamic> rideRow({
  String id = 'ride-1',
  String destinationCity = 'Toronto',
  String destinationAddress = 'Toronto centre',
  String departureTime = '2026-11-17T22:00:00Z',
}) => {
  'id': id,
  'driver_id': 'driver-1',
  'origin_city': 'Ottawa',
  'origin_address': 'Selected origin address',
  'destination_city': destinationCity,
  'destination_address': destinationAddress,
  'origin_lat': 45.4208777,
  'origin_lng': -75.6901106,
  'destination_lat': 43.6534817,
  'destination_lng': -79.3839347,
  'departure_time': departureTime,
  'available_seats': 2,
  'price_per_seat': 10,
  'status': 'available',
  'vehicle_type': 'Sedan',
  'profiles': {
    'id': 'driver-1',
    'first_name': 'Test',
    'last_name': 'Driver',
    'rating': 4.5,
  },
};

void main() {
  late List<http.Request> requests;
  late List<Map<String, dynamic>> rows;
  late SupabaseClient client;
  late DatabaseService service;
  int responseStatus = 200;

  setUp(() {
    requests = [];
    rows = [rideRow()];
    responseStatus = 200;
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(
            responseStatus == 200
                ? rows
                : {
                    'code': '42501',
                    'message': 'permission denied',
                    'details': null,
                    'hint': null,
                  },
          ),
          responseStatus,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    service = DatabaseService(client: client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('Spatial search with mocked HTTP', () {
    test(
      'uses RPC with coordinates, filters and an overflow sentinel',
      () async {
        final date = DateTime(2026, 11, 17);
        final rides = await service.searchRides(
          afterDate: date,
          startLocation: 'Different nearby street',
          endLocation: 'Toronto',
          originLatitude: 45.4208777,
          originLongitude: -75.6901106,
          minSeats: 2,
          maxPrice: 10,
        );

        expect(requests, hasLength(1));
        final request = requests.single;
        expect(request.method, 'POST');
        expect(request.url.path, '/rest/v1/rpc/search_ride_candidates');
        final params = jsonDecode(request.body) as Map<String, dynamic>;
        expect(params['p_origin_lat'], 45.4208777);
        expect(params['p_origin_lng'], -75.6901106);
        expect(
          params['p_departure_from'],
          DateTime(2026, 11, 17).toUtc().toIso8601String(),
        );
        expect(
          params['p_departure_until'],
          DateTime(2026, 11, 18).toUtc().toIso8601String(),
        );
        expect(params['p_radius_m'], 10000);
        expect(params['p_min_seats'], 2);
        expect(params['p_max_price'], 10);
        expect(params['p_limit'], 101);
        // Do not require an exact origin street once proximity search is active.
        expect(request.url.queryParameters['or'], isNull);
        expect(rides, hasLength(1));
      },
    );

    test('keeps the embedded driver preview', () async {
      final rides = await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
      );
      expect(
        requests.single.url.queryParameters['select'],
        contains('profiles!driver_id('),
      );
      expect(rides.single.driver?.firstName, 'Test');
      expect(rides.single.driver?.rating, 4.5);
    });

    test('matches destination city without case sensitivity', () async {
      rows = [
        rideRow(),
        rideRow(
          id: 'other',
          destinationCity: 'Montreal',
          destinationAddress: 'Other destination',
        ),
      ];
      final rides = await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
        endLocation: 'tOrOnTo, Ontario, Canada',
      );
      expect(rides.map((ride) => ride.id), ['ride-1']);
    });

    test('also matches destination address', () async {
      rows = [
        rideRow(
          destinationCity: 'Another city',
          destinationAddress: 'Union Station',
        ),
      ];
      final rides = await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
        endLocation: 'union',
      );
      expect(rides, hasLength(1));
    });

    test('returns empty when no destination matches', () async {
      final rides = await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
        endLocation: 'Montreal',
      );
      expect(rides, isEmpty);
    });

    test('sorts results by departure, not by RPC proximity order', () async {
      rows = [
        rideRow(id: 'late', departureTime: '2026-11-17T23:00:00Z'),
        rideRow(id: 'early', departureTime: '2026-11-17T21:00:00Z'),
      ];
      final rides = await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
      );
      expect(rides.map((ride) => ride.id), ['early', 'late']);
    });

    test('accepts coordinates equal to zero', () async {
      await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 0,
        originLongitude: 0,
      );
      expect(requests.single.url.path, contains('/rpc/'));
      final params = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(params['p_origin_lat'], 0);
      expect(params['p_origin_lng'], 0);
      expect(params['p_min_seats'], 1);
      expect(params['p_max_price'], isNull);
    });

    test('accepts a configurable radius', () async {
      await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
        radiusMeters: 5000,
      );
      final params = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(params['p_radius_m'], 5000);
    });

    test('rejects overflow before filtering by destination', () async {
      rows = List.generate(101, (index) => rideRow(id: 'ride-$index'));
      await expectLater(
        service.searchRides(
          afterDate: DateTime(2026, 11, 17),
          originLatitude: 45.4208777,
          originLongitude: -75.6901106,
          endLocation: 'No matching destination',
        ),
        throwsA(isA<StateError>()),
      );
      expect(requests, hasLength(1));
    });

    test('allows exactly 100 candidates', () async {
      rows = List.generate(100, (index) => rideRow(id: 'ride-$index'));
      final rides = await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
      );
      expect(rides, hasLength(100));
    });

    test('propagates RPC errors without a silent text fallback', () async {
      responseStatus = 403;
      await expectLater(
        service.searchRides(
          afterDate: DateTime(2026, 11, 17),
          originLatitude: 45.4208777,
          originLongitude: -75.6901106,
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(1));
    });

    test('supports a successful empty RPC result', () async {
      rows = [];
      final rides = await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
      );
      expect(rides, isEmpty);
    });

    test('uses consecutive calendar midnights across a clock change', () async {
      await service.searchRides(
        afterDate: DateTime(2026, 11, 1),
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
      );
      final params = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(
        params['p_departure_from'],
        DateTime(2026, 11, 1).toUtc().toIso8601String(),
      );
      expect(
        params['p_departure_until'],
        DateTime(2026, 11, 2).toUtc().toIso8601String(),
      );
    });
  });

  group('Text search compatibility', () {
    test('uses text mode when coordinates are absent', () async {
      await service.searchRides(
        afterDate: DateTime(2026, 11, 17),
        startLocation: 'Ottawa',
        endLocation: 'Toronto',
        maxPrice: 10,
        minSeats: 2,
      );
      final request = requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/rides');
      expect(request.url.queryParameters['status'], 'eq.available');
      expect(request.url.queryParameters['price_per_seat'], 'lte.10.0');
      final originAndDestination = request.url.queryParametersAll['or']!.join();
      expect(originAndDestination, contains('origin_city.ilike.%Ottawa%'));
      expect(
        originAndDestination,
        contains('destination_city.ilike.%Toronto%'),
      );
      expect(
        request.url.queryParametersAll['departure_time'],
        containsAll([
          'gte.${DateTime(2026, 11, 17).toUtc().toIso8601String()}',
          'lt.${DateTime(2026, 11, 18).toUtc().toIso8601String()}',
        ]),
      );
    });

    test('preserves Any date by using text mode without a date', () async {
      await service.searchRides(
        startLocation: 'Ottawa',
        originLatitude: 45.4208777,
        originLongitude: -75.6901106,
      );
      expect(requests.single.url.path, '/rest/v1/rides');
      expect(requests.single.url.queryParameters['departure_time'], isNull);
      expect(requests.single.url.queryParameters['status'], 'eq.available');
    });

    test(
      'propagates text query errors instead of returning an empty list',
      () async {
        responseStatus = 403;
        await expectLater(
          service.searchRides(startLocation: 'Ottawa'),
          throwsA(isA<PostgrestException>()),
        );
      },
    );
  });

  group('Input validation before HTTP', () {
    test('requires both coordinates', () async {
      await expectLater(
        service.searchRides(originLatitude: 45),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
    });

    test('rejects invalid or non-finite coordinates', () async {
      for (final latitude in [91.0, -91.0, double.nan, double.infinity]) {
        await expectLater(
          service.searchRides(originLatitude: latitude, originLongitude: 0),
          throwsArgumentError,
        );
      }
      for (final longitude in [181.0, -181.0, double.nan, double.infinity]) {
        await expectLater(
          service.searchRides(originLatitude: 0, originLongitude: longitude),
          throwsArgumentError,
        );
      }
      expect(requests, isEmpty);
    });

    test('rejects invalid maximum prices', () async {
      for (final price in [-1.0, double.nan, double.infinity]) {
        await expectLater(
          service.searchRides(maxPrice: price),
          throwsArgumentError,
        );
      }
      expect(requests, isEmpty);
    });

    test('rejects zero requested seats', () async {
      await expectLater(service.searchRides(minSeats: 0), throwsArgumentError);
      expect(requests, isEmpty);
    });

    test('rejects invalid radii', () async {
      for (final radius in [0.0, -1.0, 100001.0, double.nan, double.infinity]) {
        await expectLater(
          service.searchRides(radiusMeters: radius),
          throwsArgumentError,
        );
      }
      expect(requests, isEmpty);
    });
  });

  group('Search screen with mocked HTTP', () {
    Future<void> openSearch(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SearchRidesPage(databaseService: service),
        ),
      );
    }

    // Exercise the parent's selection callback without calling a live geocoder.
    void selectOrigin(WidgetTester tester) {
      final field = tester.widget<LocationAutocompleteField>(
        find.byType(LocationAutocompleteField).first,
      );
      field.controller.text = 'Selected origin address';
      field.onSelected!(
        const MapLocation(45.4208777, -75.6901106),
        field.controller.text,
        'Ottawa',
      );
    }

    Future<void> selectToday(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Any date'));
      await tester.tap(find.text('Any date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    Future<void> search(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Search rides'));
      // The optional OSRM controls make the form taller. Finish scrolling and
      // relayout before computing the tap position; keep all assertions intact.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search rides'));
      await tester.pumpAndSettle();
    }

    testWidgets('passes selected coordinates and date to RPC', (tester) async {
      await openSearch(tester);
      selectOrigin(tester);
      await tester.pump();
      await selectToday(tester);
      await search(tester);

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/rest/v1/rpc/search_ride_candidates');
      expect(find.textContaining('Test Driver'), findsOneWidget);
      expect(find.text('No rides found'), findsNothing);
    });

    testWidgets('editing a selected origin prevents stale coordinate use', (
      tester,
    ) async {
      await openSearch(tester);
      selectOrigin(tester);
      await tester.pump();
      await selectToday(tester);
      final field = tester.widget<LocationAutocompleteField>(
        find.byType(LocationAutocompleteField).first,
      );
      field.controller.text = 'A different origin';
      await search(tester);
      expect(requests.single.url.path, '/rest/v1/rides');
    });

    testWidgets('shows a query error instead of No rides found', (
      tester,
    ) async {
      responseStatus = 403;
      await openSearch(tester);
      await search(tester);
      expect(find.text('Search unavailable'), findsOneWidget);
      expect(find.text('No rides found'), findsNothing);
    });

    testWidgets('rejects an invalid price before sending a request', (
      tester,
    ) async {
      await openSearch(tester);
      final field = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Max price per seat (optional)',
        ),
      );
      field.controller!.text = '-1';
      await search(tester);
      expect(requests, isEmpty);
      expect(
        find.text('Enter a valid, non-negative maximum price.'),
        findsOneWidget,
      );
    });

    testWidgets('accepts a decimal comma in the maximum price', (tester) async {
      await openSearch(tester);
      selectOrigin(tester);
      await tester.pump();
      await selectToday(tester);
      final field = tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Max price per seat (optional)',
        ),
      );
      field.controller!.text = '10,50';
      await search(tester);
      final params = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(params['p_max_price'], 10.5);
    });

    testWidgets('swapping and editing does not reuse the swapped coordinates', (
      tester,
    ) async {
      await openSearch(tester);
      selectOrigin(tester);
      final destinationField = tester.widget<LocationAutocompleteField>(
        find.byType(LocationAutocompleteField).last,
      );
      destinationField.controller.text = 'Selected destination address';
      destinationField.onSelected!(
        const MapLocation(43.6534817, -79.3839347),
        destinationField.controller.text,
        'Toronto',
      );
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Swap pickup and drop-off'));
      await tester.tap(find.byTooltip('Swap pickup and drop-off'));
      await tester.pump();
      await selectToday(tester);
      final originField = tester.widget<LocationAutocompleteField>(
        find.byType(LocationAutocompleteField).first,
      );
      originField.controller.text = 'Edited after swap';
      await search(tester);
      expect(requests.single.url.path, '/rest/v1/rides');
    });
  });
}
