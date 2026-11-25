// Simulated database, routing and model fixtures only. These tests do not
// validate deployed Supabase/OSRM or the model's real-world performance.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/maps/map_types.dart';
import 'package:supabase_flutter_app/models/ride.dart';
import 'package:supabase_flutter_app/screens/search_rides_page.dart';
import 'package:supabase_flutter_app/services/database_service.dart';
import 'package:supabase_flutter_app/services/learned_matching_service.dart';
import 'package:supabase_flutter_app/services/osrm_service.dart';
import 'package:supabase_flutter_app/services/road_route_service.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';
import 'package:supabase_flutter_app/widgets/location_autocomplete_field.dart';

class _Database extends DatabaseService {
  _Database(SupabaseClient client) : super(client: client);

  int searches = 0;
  final drafts = <MatchFeedbackDraft>[];
  final updates = <String, bool>{};
  bool empty = false;

  @override
  Future<List<Ride>> searchRides({
    DateTime? afterDate,
    String? startLocation,
    String? endLocation,
    double? maxPrice,
    int? minSeats,
    double? originLatitude,
    double? originLongitude,
    double radiusMeters = 10000,
  }) async {
    searches++;
    if (empty) return [];
    final date = afterDate ?? DateTime.now();
    return [
      for (final id in ['expensive', 'cheap'])
        Ride(
          id: id,
          driverId: 'driver-$id',
          originCity: id,
          destinationCity: 'Gatineau',
          originAddress: 'Ottawa centre',
          destinationAddress: 'Gatineau centre',
          originLat: 45.42,
          originLng: -75.69,
          destinationLat: 45.48,
          destinationLng: -75.70,
          departureTime: DateTime(date.year, date.month, date.day, 12),
          availableSeats: 3,
          pricePerSeat: id == 'cheap' ? 5 : 50,
          vehicleType: 'sedan',
        ),
    ];
  }

  @override
  Future<Map<String, String>> recordMatchFeedback(
    List<MatchFeedbackDraft> entries,
  ) async {
    drafts
      ..clear()
      ..addAll(entries);
    return {
      for (final entry in entries) entry.rideId: 'feedback-${entry.rideId}',
    };
  }

  @override
  Future<void> updateMatchFeedback({
    required String feedbackId,
    required bool accepted,
  }) async {
    updates[feedbackId] = accepted;
  }
}

class _Routes extends RoadRouteService {
  int calls = 0;

  @override
  Future<List<RoadRouteDetour>> calculateDetours({
    required List<Ride> candidates,
    required OsrmCoordinate pickup,
    required OsrmCoordinate dropoff,
  }) async {
    calls++;
    return [
      for (final ride in candidates)
        RoadRouteDetour(
          rideId: ride.id,
          extraDurationSeconds: 300,
          extraDistanceMeters: ride.id == 'cheap' ? 5000 : 1000,
        ),
    ];
  }
}

LearnedMatchingService _model({String source = 'synthetic'}) =>
    LearnedMatchingService.fromJson({
      'source': source,
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

const _roadToggle = Key('road-routing-toggle');
const _learnedToggle = Key('learned-model-toggle');

void main() {
  late SupabaseClient client;
  late _Database database;
  late _Routes routes;
  var loads = 0;
  late Future<LearnedMatchingService> Function() loadModel;

  setUp(() {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((_) async {
        throw StateError('Unexpected network request');
      }),
    );
    database = _Database(client);
    routes = _Routes();
    loads = 0;
    loadModel = () async {
      loads++;
      return _model();
    };
  });
  tearDown(() async {
    routes.close();
    await client.dispose();
  });

  Future<AppLocalizations> open(
    WidgetTester tester, {
    String language = 'fr',
    Size size = const Size(1280, 1800),
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
        home: SearchRidesPage(
          databaseService: database,
          roadRouteService: routes,
          learnedModelLoader: () => loadModel(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(Locale(language));
  }

  Future<void> toggle(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> selectRoute(
    WidgetTester tester,
    AppLocalizations strings,
  ) async {
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
    fields.last.controller.text = 'Gatineau centre';
    fields.last.onSelected!(
      const MapLocation(45.48, -75.70),
      'Gatineau centre',
      'Gatineau',
    );
    await tester.pump();
    await tester.ensureVisible(find.text(strings.searchAnyDate));
    await tester.tap(find.text(strings.searchAnyDate));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(DatePickerDialog));
    await tester.tap(
      find.text(MaterialLocalizations.of(context).okButtonLabel),
    );
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

  Future<void> prepare(WidgetTester tester, AppLocalizations strings) async {
    await selectRoute(tester, strings);
    await toggle(tester, _roadToggle);
    await toggle(tester, _learnedToggle);
  }

  List<String> order(WidgetTester tester) => tester
      .widgetList<Widget>(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'search-ride-',
              ),
        ),
      )
      .map((widget) => (widget.key! as ValueKey<String>).value)
      .toList();

  for (final language in ['fr', 'en']) {
    testWidgets('rules remain default and never load the model in $language', (
      tester,
    ) async {
      final strings = await open(tester, language: language);
      expect(find.byKey(_learnedToggle), findsNothing);
      await selectRoute(tester, strings);
      await toggle(tester, _roadToggle);
      expect(
        tester.widget<SwitchListTile>(find.byKey(_learnedToggle)).value,
        false,
      );
      await submit(tester, strings);
      expect(loads, 0);
      expect(order(tester), ['search-ride-expensive', 'search-ride-cheap']);
      expect(find.text(strings.searchLearnedSyntheticNotice), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('explicit model ranking and original feedback in $language', (
      tester,
    ) async {
      final strings = await open(tester, language: language);
      await prepare(tester, strings);
      expect(loads, 0);
      await submit(tester, strings);
      expect(loads, 1);
      expect(order(tester), ['search-ride-cheap', 'search-ride-expensive']);
      expect(find.text(strings.searchLearnedResults(2, 0)), findsOneWidget);
      expect(find.text(strings.searchLearnedSyntheticNotice), findsOneWidget);
      final score = strings.searchLearnedScore(
        NumberFormat('0.0', language).format(37.75406687981454),
      );
      expect(find.text(score), findsOneWidget);
      expect(database.drafts.map((entry) => entry.rideId), [
        'cheap',
        'expensive',
      ]);
      expect(database.drafts.map((entry) => entry.ruleScore), [83.3, 96.7]);
      expect(find.text(strings.searchRuleDetour(5, 83)), findsOneWidget);
      // Explicit rejection records false, not an invented acceptance label.
      final card = find.byKey(const ValueKey('search-ride-cheap'));
      final reject = find.descendant(
        of: card,
        matching: find.text(strings.searchRejectMatch),
      );
      await tester.ensureVisible(reject);
      await tester.tap(reject);
      await tester.pumpAndSettle();
      expect(database.updates, {'feedback-cheap': false});
      expect(find.byKey(const ValueKey('search-ride-cheap')), findsNothing);
      expect(find.text(strings.searchLearnedResults(1, 1)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading failure is explicit and retryable in $language', (
      tester,
    ) async {
      loadModel = () async {
        loads++;
        if (loads == 1) throw const FormatException('private diagnostic');
        return _model();
      };
      final strings = await open(tester, language: language);
      await prepare(tester, strings);
      await submit(tester, strings);
      expect(find.text(strings.searchLearnedFailed), findsWidgets);
      expect(find.textContaining('private diagnostic'), findsNothing);
      expect(database.searches, 0);
      expect(routes.calls, 0);
      expect(order(tester), isEmpty);
      await submit(tester, strings);
      expect(loads, 2);
      expect(database.searches, 1);
      expect(order(tester).first, 'search-ride-cheap');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pending model disables controls and prevents duplicate search', (
    tester,
  ) async {
    final pending = Completer<LearnedMatchingService>();
    loadModel = () {
      loads++;
      return pending.future;
    };
    final strings = await open(tester);
    await prepare(tester, strings);
    await submit(tester, strings, settle: false);
    expect(find.text(strings.searchLearnedLoading), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byKey(_roadToggle)).onChanged,
      isNull,
    );
    expect(
      tester.widget<SwitchListTile>(find.byKey(_learnedToggle)).onChanged,
      isNull,
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(database.searches, 0);
    expect(loads, 1);
    pending.complete(_model());
    await tester.pumpAndSettle();
    expect(database.searches, 1);
    expect(routes.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving during model loading does not query or update disposed UI',
    (tester) async {
      final pending = Completer<LearnedMatchingService>();
      loadModel = () => pending.future;
      final strings = await open(tester);
      await prepare(tester, strings);
      await submit(tester, strings, settle: false);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      pending.complete(_model());
      await tester.pumpAndSettle();
      expect(database.searches, 0);
      expect(routes.calls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mode changes clear stale results and reuse a successfully loaded model',
    (tester) async {
      final strings = await open(tester);
      await prepare(tester, strings);
      await submit(tester, strings);
      await toggle(tester, _learnedToggle);
      expect(order(tester), isEmpty);
      expect(find.text(strings.searchLearnedSyntheticNotice), findsNothing);
      await submit(tester, strings);
      expect(order(tester).first, 'search-ride-expensive');
      expect(loads, 1);
      await toggle(tester, _learnedToggle);
      await submit(tester, strings);
      expect(order(tester).first, 'search-ride-cheap');
      expect(loads, 1);
      await toggle(tester, _roadToggle);
      expect(find.byKey(_learnedToggle), findsNothing);
      expect(order(tester), isEmpty);
      await toggle(tester, _roadToggle);
      expect(
        tester.widget<SwitchListTile>(find.byKey(_learnedToggle)).value,
        false,
      );
    },
  );

  testWidgets('disabling a failed model explicitly returns to rules', (
    tester,
  ) async {
    loadModel = () async {
      loads++;
      throw const FormatException('unavailable');
    };
    final strings = await open(tester);
    await prepare(tester, strings);
    await submit(tester, strings);
    expect(database.searches, 0);
    await toggle(tester, _learnedToggle);
    expect(find.text(strings.searchUnavailable), findsNothing);
    await submit(tester, strings);
    expect(loads, 1);
    expect(database.searches, 1);
    expect(order(tester).first, 'search-ride-expensive');
    expect(find.text(strings.searchLearnedResults(2, 0)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty model results retain the model/source summary', (
    tester,
  ) async {
    database.empty = true;
    final strings = await open(tester);
    await prepare(tester, strings);
    await submit(tester, strings);
    expect(find.text(strings.searchLearnedResults(0, 0)), findsOneWidget);
    expect(find.text(strings.searchLearnedSyntheticNotice), findsOneWidget);
    expect(order(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-synthetic source does not acquire a synthetic notice', (
    tester,
  ) async {
    loadModel = () async => _model(source: 'feedback');
    final strings = await open(tester);
    await prepare(tester, strings);
    await submit(tester, strings);
    expect(find.text(strings.searchLearnedResults(2, 0)), findsOneWidget);
    expect(find.text(strings.searchLearnedSyntheticNotice), findsNothing);
    expect(find.text(strings.searchLearnedHelp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'experimental controls and results fit a narrow enlarged layout',
    (tester) async {
      final strings = await open(
        tester,
        size: const Size(375, 1000),
        scale: 1.3,
      );
      await prepare(tester, strings);
      await submit(tester, strings);
      await tester.ensureVisible(
        find.text(strings.searchLearnedSyntheticNotice),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final score = strings.searchLearnedScore(
        NumberFormat('0.0', 'fr').format(37.75406687981454),
      );
      await tester.scrollUntilVisible(find.text(score), 250);
      expect(tester.takeException(), isNull);
    },
  );
}
