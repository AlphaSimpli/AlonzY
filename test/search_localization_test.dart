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
import 'package:supabase_flutter_app/screens/search_rides_page.dart';
import 'package:supabase_flutter_app/services/database_service.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';
import 'package:supabase_flutter_app/widgets/location_autocomplete_field.dart';

// HTTP and ride data are simulated. These tests do not authenticate a real user,
// query a deployed PostGIS database, or exercise the live geocoder.
void main() {
  late SupabaseClient client;
  late DatabaseService service;
  late List<http.Request> requests;
  late List<Map<String, dynamic>> rows;
  late int status;
  Completer<void>? pending;

  Map<String, dynamic> row({
    String id = 'ride-1',
    int seats = 2,
    Duration untilDeparture = const Duration(hours: 2, minutes: 31),
  }) => {
    'id': id,
    'driver_id': 'driver-1',
    'origin_city': '',
    'destination_city': '',
    'origin_address': 'Ottawa centre',
    'destination_address': 'Gatineau centre',
    'origin_lat': 45.42,
    'origin_lng': -75.69,
    'destination_lat': 45.48,
    'destination_lng': -75.7,
    'departure_time': DateTime.now().add(untilDeparture).toIso8601String(),
    'available_seats': seats,
    'price_per_seat': 10.5,
    'status': 'available',
    'vehicle_type': 'Sedan',
  };

  setUp(() {
    requests = [];
    rows = [];
    status = 200;
    pending = null;
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (pending != null) await pending!.future;
        return http.Response(
          jsonEncode(
            status == 200
                ? rows
                : {
                    'code': '42501',
                    'message': 'private diagnostic must not appear on screen',
                  },
          ),
          status,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    service = DatabaseService(client: client);
  });

  tearDown(() async {
    if (pending != null && !pending!.isCompleted) pending!.complete();
    await client.dispose();
  });

  Future<AppLocalizations> open(
    WidgetTester tester,
    String language, {
    Size size = const Size(1280, 1000),
    double scale = 1,
  }) async {
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
        home: SearchRidesPage(databaseService: service),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(Locale(language));
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

  TextField priceField(WidgetTester tester, AppLocalizations strings) =>
      tester.widget<TextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == strings.searchMaxPrice,
        ),
      );

  Future<void> chooseOriginAndDate(
    WidgetTester tester,
    AppLocalizations strings,
  ) async {
    final origin = tester.widget<LocationAutocompleteField>(
      find.byType(LocationAutocompleteField).first,
    );
    origin.controller.text = 'Ottawa centre';
    origin.onSelected!(
      const MapLocation(45.42, -75.69),
      'Ottawa centre',
      'Ottawa',
    );
    await tester.pump();
    await tester.ensureVisible(find.text(strings.searchAnyDate));
    await tester.tap(find.text(strings.searchAnyDate));
    await tester.pumpAndSettle();
    expect(find.text(strings.searchPickDate), findsOneWidget);
    final pickerContext = tester.element(find.byType(DatePickerDialog));
    final confirm = MaterialLocalizations.of(pickerContext).okButtonLabel;
    await tester.tap(find.text(confirm));
    await tester.pumpAndSettle();
  }

  for (final language in ['fr', 'en']) {
    testWidgets('search form and initial state in $language', (tester) async {
      final strings = await open(tester, language);
      for (final text in [
        strings.searchTitle,
        strings.searchHeading,
        strings.searchIntroduction,
        strings.searchFrom,
        strings.searchTo,
        strings.searchAnyDate,
        strings.searchSeats,
        strings.searchMaxPrice,
        strings.searchTextHint,
        strings.searchInitialTitle,
        strings.searchInitialMessage,
      ]) {
        expect(find.text(text), findsAtLeastNWidgets(1));
      }
      expect(find.byTooltip(strings.searchSwap), findsOneWidget);
      expect(find.byTooltip(strings.searchFewerSeats), findsOneWidget);
      expect(find.byTooltip(strings.searchMoreSeats), findsOneWidget);
      expect(requests, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty search in $language', (tester) async {
      final strings = await open(tester, language);
      await submit(tester, strings);
      expect(find.text(strings.searchEmptyTitle), findsOneWidget);
      expect(find.text(strings.searchEmptyMessage), findsOneWidget);
      expect(requests.single.url.path, '/rest/v1/rides');
    });

    testWidgets('results, CAD price and fallback driver in $language', (
      tester,
    ) async {
      rows = [row(seats: 1), row(id: 'ride-2', seats: 3)];
      final strings = await open(tester, language);
      await submit(tester, strings);
      expect(find.text(strings.searchAvailableSeats(1)), findsOneWidget);
      expect(find.text(strings.searchAvailableSeats(3)), findsOneWidget);
      expect(
        find.text(
          '${strings.searchUnknownCity} → ${strings.searchUnknownCity}',
        ),
        findsNWidgets(2),
      );
      expect(find.textContaining(strings.searchDriver), findsNWidgets(2));
      final price = NumberFormat.currency(
        locale: language == 'fr' ? 'fr_CA' : 'en_CA',
        name: 'CAD',
        symbol: '\$',
      ).format(10.5);
      expect(find.text(price), findsNWidgets(2));
      expect(
        find.textContaining(language == 'fr' ? 'Départ dans' : 'Departs in'),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('departed and upcoming minutes in $language', (tester) async {
      rows = [
        row(untilDeparture: const Duration(minutes: -5)),
        row(id: 'soon', untilDeparture: const Duration(minutes: 31)),
      ];
      final strings = await open(tester, language);
      await submit(tester, strings);
      expect(find.text(strings.searchDeparted), findsOneWidget);
      expect(
        find.textContaining(language == 'fr' ? 'Départ dans' : 'Departs in'),
        findsOneWidget,
      );
    });

    testWidgets('localized failure without exposing diagnostic in $language', (
      tester,
    ) async {
      status = 403;
      final strings = await open(tester, language);
      await submit(tester, strings);
      expect(find.text(strings.searchUnavailable), findsOneWidget);
      expect(find.text(strings.searchFailed), findsAtLeastNWidgets(1));
      expect(find.text(strings.searchEmptyTitle), findsNothing);
      expect(find.textContaining('private diagnostic'), findsNothing);
    });

    testWidgets('price validation and decimal comma in $language', (
      tester,
    ) async {
      final strings = await open(tester, language);
      priceField(tester, strings).controller!.text = '-1';
      await submit(tester, strings);
      expect(find.text(strings.searchInvalidPrice), findsOneWidget);
      expect(requests, isEmpty);
      priceField(tester, strings).controller!.text = '10,50';
      await submit(tester, strings);
      expect(requests.single.url.queryParameters['price_per_seat'], 'lte.10.5');
    });

    testWidgets(
      'calendar, localized date and unchanged spatial RPC in $language',
      (tester) async {
        final strings = await open(tester, language);
        await chooseOriginAndDate(tester, strings);
        final pageContext = tester.element(find.byType(SearchRidesPage));
        final today = MaterialLocalizations.of(
          pageContext,
        ).formatMediumDate(DateTime.now());
        expect(find.text(today), findsOneWidget);
        expect(find.text(strings.searchNearbyHint), findsOneWidget);
        await submit(tester, strings);
        expect(requests.single.url.path, '/rest/v1/rpc/search_ride_candidates');
        final params = jsonDecode(requests.single.body) as Map<String, dynamic>;
        expect(params['p_origin_lat'], 45.42);
        expect(params['p_origin_lng'], -75.69);
        expect(params['p_radius_m'], 10000);
        expect(params['p_min_seats'], 1);
      },
    );

    testWidgets('candidate overflow message in $language', (tester) async {
      // The service checks the sentinel count before parsing candidate fields.
      rows = List.generate(101, (index) => {'id': 'ride-$index'});
      final strings = await open(tester, language);
      await chooseOriginAndDate(tester, strings);
      await submit(tester, strings);
      expect(find.text(strings.searchTooMany), findsAtLeastNWidgets(1));
      expect(find.text(strings.searchUnavailable), findsOneWidget);
      expect(find.text(strings.searchEmptyTitle), findsNothing);
    });

    testWidgets('loading state blocks duplicate searches in $language', (
      tester,
    ) async {
      pending = Completer<void>();
      final strings = await open(tester, language);
      await submit(tester, strings, settle: false);
      expect(find.text(strings.searchLoading), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, strings.searchLoading),
      );
      expect(button.onPressed, isNull);
      pending!.complete();
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(find.text(strings.searchEmptyTitle), findsOneWidget);
    });

    for (final scale in [1.0, 1.4]) {
      testWidgets('375px layout at ${scale}x in $language', (tester) async {
        rows = [row()];
        final strings = await open(
          tester,
          language,
          size: const Size(375, 900),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        await submit(tester, strings);
        await tester.scrollUntilVisible(
          find.text(strings.searchAvailableSeats(2)),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('seat plural forms in both languages', () async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(fr.searchAvailableSeats(0), '0 place');
    expect(fr.searchAvailableSeats(1), '1 place');
    expect(fr.searchAvailableSeats(2), '2 places');
    expect(en.searchAvailableSeats(0), '0 seats');
    expect(en.searchAvailableSeats(1), '1 seat');
    expect(en.searchAvailableSeats(2), '2 seats');
  });
}
