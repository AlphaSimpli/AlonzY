// Widget tests only: session, profile, HTTP and map are simulated.
// Address selection uses the public autocomplete callbacks, not live Nominatim.
// No ride is inserted into a real Supabase database.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/maps/app_maps.dart';
import 'package:supabase_flutter_app/maps/map_controller.dart';
import 'package:supabase_flutter_app/maps/map_provider.dart';
import 'package:supabase_flutter_app/maps/map_types.dart';
import 'package:supabase_flutter_app/maps/map_view.dart';
import 'package:supabase_flutter_app/screens/post_ride_page.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';
import 'package:supabase_flutter_app/widgets/location_autocomplete_field.dart';

class _Storage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) async => null;
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<void> removeItem({required String key}) async {}
}

class _MapRecorder extends AppMapController {
  final markers = <MapMarkerData>[];
  final lines = <MapPolylineData>[];
  List<MapLocation>? bounds;
  double? padding;
  @override
  Future<void> clear() async => markers.clear();
  @override
  Future<void> addMarker(MapMarkerData marker) async => markers.add(marker);
  @override
  Future<void> addPolyline(MapPolylineData line) async => lines.add(line);
  @override
  Future<void> animateToBounds(
    List<MapLocation> points, {
    double padding = 100,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    bounds = points;
    this.padding = padding;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Provider extends MapProvider {
  const _Provider(this.controller);
  final _MapRecorder controller;
  @override
  MapView createView(MapViewConfig config) => _View(config, controller);
}

class _View extends MapView {
  const _View(MapViewConfig config, this.controller) : super(config: config);
  final _MapRecorder controller;
  @override
  Widget build({
    required void Function(AppMapController) onMapCreated,
    VoidCallback? onMapIdle,
  }) => _Surface(controller: controller, onReady: onMapCreated);
}

class _Surface extends StatefulWidget {
  const _Surface({required this.controller, required this.onReady});
  final _MapRecorder controller;
  final void Function(AppMapController) onReady;
  @override
  State<_Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<_Surface> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady(widget.controller);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand(
    child: ColoredBox(color: Colors.grey, child: Text('Simulated map')),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  const driverId = '00000000-0000-4000-8000-000000000001';
  final inserts = <Map<String, dynamic>>[];
  Map<String, dynamic> profile = {};
  bool fail = false;
  Completer<void>? pending;
  late _MapRecorder map;
  late MapProvider previousProvider;

  setUpAll(() async {
    previousProvider = AppMaps.provider;
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-public-key',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _Storage(),
      ),
      httpClient: MockClient((request) async {
        Object? body;
        var status = 200;
        if (request.url.path.endsWith('/token')) {
          final claims = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': driverId,
                    'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
                  }),
                ),
              )
              .replaceAll('=', '');
          body = {
            'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.test-signature',
            'refresh_token': 'simulated-refresh-token',
            'expires_in': 3600,
            'token_type': 'bearer',
            'user': {
              'id': driverId,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'driver@example.com',
              'created_at': '2026-11-17T12:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            },
          };
        } else if (request.url.path.endsWith('/profiles')) {
          body = {'id': driverId, ...profile};
        } else if (request.url.path.endsWith('/rides') &&
            request.method == 'POST') {
          inserts.add(
            Map<String, dynamic>.from(jsonDecode(request.body) as Map),
          );
          if (pending != null) await pending!.future;
          status = fail ? 403 : 200;
          body = fail
              ? {'code': '42501', 'message': 'private publication diagnostic'}
              : {'id': 'simulated-ride'};
        } else {
          throw StateError('Unexpected simulated HTTP request: ${request.url}');
        }
        return http.Response(
          jsonEncode(body),
          status,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await Supabase.instance.client.auth.signInWithPassword(
      email: 'driver@example.com',
      password: 'simulated-password',
    );
  });

  setUp(() {
    inserts.clear();
    profile = {};
    fail = false;
    pending = null;
    map = _MapRecorder();
    AppMaps.configure(_Provider(map));
  });
  tearDown(() {
    if (pending != null && !pending!.isCompleted) pending!.complete();
  });
  tearDownAll(() async {
    AppMaps.configure(previousProvider);
    await Supabase.instance.dispose();
  });

  Future<AppLocalizations> open(
    WidgetTester tester,
    String language, {
    Size size = const Size(1280, 1400),
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
        home: const PostRidePage(),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(PostRidePage)));
  }

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  Future<void> enter(WidgetTester tester, String label, String value) async {
    final target = field(label);
    await tester.ensureVisible(target);
    await tester.enterText(target, value);
    await tester.pump();
  }

  Future<void> dismissMessage(WidgetTester tester) async {
    if (find.byType(SnackBar).evaluate().isNotEmpty) {
      // Advance the widget clock through the snackbar's normal duration.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Finder seatButton(String tooltip) => find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == tooltip,
  );
  Future<void> next(WidgetTester tester, AppLocalizations s) async {
    await dismissMessage(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, s.postContinue));
    await tester.pumpAndSettle();
  }

  Future<void> route(WidgetTester tester, {bool missingCity = false}) async {
    final fields = tester
        .widgetList<LocationAutocompleteField>(
          find.byType(LocationAutocompleteField),
        )
        .toList();
    fields[0].controller.text = 'Ottawa centre';
    fields[0].onSelected!(
      const MapLocation(45.42, -75.69),
      'Ottawa centre',
      missingCity ? null : 'Ottawa',
    );
    fields[1].controller.text = 'Gatineau centre';
    fields[1].onSelected!(
      const MapLocation(45.48, -75.7),
      'Gatineau centre',
      'Gatineau',
    );
    await tester.pumpAndSettle();
  }

  Future<void> toPrice(WidgetTester tester, AppLocalizations s) async {
    await route(tester);
    await next(tester, s);
    await next(tester, s);
  }

  Future<void> toPolicies(
    WidgetTester tester,
    AppLocalizations s, {
    String price = '10.50',
  }) async {
    await toPrice(tester, s);
    await enter(tester, s.postPricePerSeat, price);
    await next(tester, s);
  }

  Future<void> publish(WidgetTester tester, AppLocalizations s) async {
    await dismissMessage(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, s.postPublish));
    // The original flow keeps its spinner active underneath the success dialog
    // until acknowledgement, so settling every animation here cannot terminate.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final language in ['fr', 'en']) {
    testWidgets('route labels, tooltip and validation in $language', (
      tester,
    ) async {
      final s = await open(tester, language);
      expect(
        find.text(language == 'fr' ? 'Publier un trajet' : 'Post a ride'),
        findsOneWidget,
      );
      for (final text in [
        s.postRouteTitle,
        s.postPickup,
        s.postDropoff,
        s.postMapHint,
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.byTooltip(s.searchSwap), findsOneWidget);
      await next(tester, s);
      expect(find.text(s.postInvalidLocations), findsOneWidget);
      expect(find.text(s.postRouteTitle), findsOneWidget);
      expect(inserts, isEmpty);
    });

    testWidgets('municipality is still required in $language', (tester) async {
      final s = await open(tester, language);
      await route(tester, missingCity: true);
      await next(tester, s);
      expect(find.text(s.postInvalidLocations), findsOneWidget);
      expect(find.text(s.postRouteTitle), findsOneWidget);
    });

    testWidgets('map contract, swapping and clearing in $language', (
      tester,
    ) async {
      final s = await open(tester, language);
      expect(find.text('Simulated map'), findsNothing);
      await route(tester);
      expect(map.markers.map((m) => m.label), [s.postPickup, s.postDropoff]);
      expect(map.lines.last.points.first.latitude, 45.42);
      expect(map.lines.last.points.last.latitude, 45.48);
      expect(map.bounds!.length, 2);
      expect(map.padding, 24);
      await tester.tap(find.byTooltip(s.searchSwap));
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<LocationAutocompleteField>(
            find.byType(LocationAutocompleteField),
          )
          .toList();
      expect(fields.first.controller.text, 'Gatineau centre');
      expect(fields.last.controller.text, 'Ottawa centre');
      expect(map.bounds!.first.latitude, 45.48);
      fields.first.controller.clear();
      fields.first.onCleared!();
      await tester.pumpAndSettle();
      expect(find.text('Simulated map'), findsNothing);
      await next(tester, s);
      expect(find.text(s.postInvalidLocations), findsOneWidget);
    });

    testWidgets(
      'date and time pickers, localized format and back in $language',
      (tester) async {
        final s = await open(tester, language);
        await route(tester);
        await next(tester, s);
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(
          find.text(DateFormat.yMMMd(language).format(tomorrow)),
          findsOneWidget,
        );
        await tester.tap(find.text(s.searchDate));
        await tester.pumpAndSettle();
        expect(find.text(s.searchPickDate), findsOneWidget);
        final dateContext = tester.element(find.byType(DatePickerDialog));
        await tester.tap(
          find.text(MaterialLocalizations.of(dateContext).okButtonLabel),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(s.postTime));
        await tester.pumpAndSettle();
        expect(find.text(s.postPickTime), findsOneWidget);
        final timeContext = tester.element(find.byType(TimePickerDialog));
        await tester.tap(
          find.text(MaterialLocalizations.of(timeContext).okButtonLabel),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(s.postBack));
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<LocationAutocompleteField>(
                find.byType(LocationAutocompleteField),
              )
              .first
              .controller
              .text,
          'Ottawa centre',
        );
        expect(inserts, isEmpty);
      },
    );

    testWidgets(
      'price validation, CAD suggestions and seat limits in $language',
      (tester) async {
        final s = await open(tester, language);
        await toPrice(tester, s);
        expect(
          find.text(language == 'fr' ? 'Berline' : 'Sedan'),
          findsOneWidget,
        );
        for (final invalid in ['', '0', '0,00']) {
          await enter(tester, s.postPricePerSeat, invalid);
          await next(tester, s);
          expect(find.text(s.postInvalidPrice), findsOneWidget);
          expect(find.text(s.postPriceTitle), findsOneWidget);
        }
        final suggestion = NumberFormat.simpleCurrency(
          locale: language,
          name: 'CAD',
          decimalDigits: 0,
        ).format(15);
        await tester.tap(find.widgetWithText(ActionChip, suggestion));
        expect(
          tester.widget<TextField>(field(s.postPricePerSeat)).controller!.text,
          '15',
        );
        for (var i = 0; i < 5; i++) {
          await tester.tap(seatButton(s.searchMoreSeats));
          await tester.pump();
        }
        expect(
          tester.widget<IconButton>(seatButton(s.searchMoreSeats)).onPressed,
          isNull,
        );
        for (var i = 0; i < 7; i++) {
          await tester.tap(seatButton(s.searchFewerSeats));
          await tester.pump();
        }
        expect(
          tester.widget<IconButton>(seatButton(s.searchFewerSeats)).onPressed,
          isNull,
        );
        expect(inserts, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'vehicle prefill, localized policies and publication payload in $language',
      (tester) async {
        profile = {
          'vehicle_make': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_color': 'Bleu personnel',
          'vehicle_plate': 'ABC 123',
          'vehicle_year': 2022,
        };
        final s = await open(tester, language);
        await toPrice(tester, s);
        expect(
          tester.widget<TextField>(field(s.postMake)).controller!.text,
          'Toyota',
        );
        expect(
          tester.widget<TextField>(field(s.postColor)).controller!.text,
          'Bleu personnel',
        );
        await enter(
          tester,
          s.postPricePerSeat,
          language == 'fr' ? '10,50' : '10.50',
        );
        await tester.tap(find.widgetWithText(ChoiceChip, s.detailsSuv));
        await next(tester, s);
        await tester.tap(
          find.widgetWithText(SwitchListTile, s.postInstantBooking),
        );
        await tester.tap(
          find.widgetWithText(SwitchListTile, s.postPetsAllowed),
        );
        await tester.tap(find.widgetWithText(ChoiceChip, s.postLuggageLarge));
        await enter(tester, s.postNotes, 'Notes personnelles à conserver');
        expect(
          find.textContaining('Notes personnelles à conserver'),
          findsWidgets,
        );
        await publish(tester, s);
        expect(
          find.text(language == 'fr' ? 'Trajet publié !' : 'Ride published!'),
          findsOneWidget,
        );
        expect(find.text(s.postPublishedMessage), findsOneWidget);
        final p = inserts.single;
        expect(p['driver_id'], driverId);
        expect(p['origin_city'], 'Ottawa');
        expect(p['destination_city'], 'Gatineau');
        expect(p['origin_address'], 'Ottawa centre');
        expect(p['destination_address'], 'Gatineau centre');
        expect(p['origin_lat'], 45.42);
        expect(p['origin_lng'], -75.69);
        expect(p['destination_lat'], 45.48);
        expect(p['destination_lng'], -75.7);
        expect(
          DateTime.parse(p['departure_time'] as String).isAfter(DateTime.now()),
          isTrue,
        );
        expect(p['price_per_seat'], 10.5);
        expect(p['available_seats'], 3);
        expect(p['vehicle_type'], 'suv');
        expect(p['vehicle_make'], 'Toyota');
        expect(p['vehicle_model'], 'Corolla');
        expect(p['vehicle_color'], 'Bleu personnel');
        expect(p['vehicle_plate'], 'ABC 123');
        expect(p['vehicle_year'], 2022);
        expect(p['pets_allowed'], true);
        expect(p['instant_booking'], true);
        expect(p['luggage_policy'], 'large');
        expect(p['status'], 'available');
        expect(p['notes'], 'Notes personnelles à conserver');
        await tester.tap(find.text(s.postGreat));
        await tester.pumpAndSettle();
        expect(find.text(s.postRouteTitle), findsOneWidget);
        expect(
          tester
              .widgetList<LocationAutocompleteField>(
                find.byType(LocationAutocompleteField),
              )
              .every((w) => w.controller.text.isEmpty),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('optional fields and default technical values in $language', (
      tester,
    ) async {
      final s = await open(tester, language);
      await toPolicies(tester, s);
      expect(
        find.textContaining(s.postSummaryBooking(s.postBookingApproval)),
        findsOneWidget,
      );
      await publish(tester, s);
      final p = inserts.single;
      for (final key in [
        'vehicle_make',
        'vehicle_model',
        'vehicle_color',
        'vehicle_plate',
        'vehicle_year',
        'notes',
      ]) {
        expect(p[key], isNull);
      }
      expect(p['instant_booking'], false);
      expect(p['pets_allowed'], false);
      expect(p['luggage_policy'], 'moderate');
      expect(p['vehicle_type'], 'sedan');
      expect(find.text(s.postPublished), findsOneWidget);
    });

    testWidgets('localized server error keeps values for retry in $language', (
      tester,
    ) async {
      fail = true;
      final s = await open(tester, language);
      await toPolicies(tester, s);
      await publish(tester, s);
      expect(find.text(s.postFailed), findsOneWidget);
      expect(
        find.textContaining('private publication diagnostic'),
        findsNothing,
      );
      expect(find.text(s.postPoliciesTitle), findsOneWidget);
      fail = false;
      await publish(tester, s);
      expect(inserts.length, 2);
      expect(find.text(s.postPublished), findsOneWidget);
    });

    testWidgets('publishing disables submit and back in $language', (
      tester,
    ) async {
      final s = await open(tester, language);
      await toPolicies(tester, s);
      pending = Completer<void>();
      await tester.tap(find.widgetWithText(ElevatedButton, s.postPublish));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(s.postPublishing), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, s.postPublishing),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, s.postBack),
            )
            .onPressed,
        isNull,
      );
      expect(inserts.length, 1);
      pending!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(s.postPublished), findsOneWidget);
    });

    for (final scale in [1.0, 1.4]) {
      testWidgets('all four steps at 375px ${scale}x in $language', (
        tester,
      ) async {
        final s = await open(
          tester,
          language,
          size: const Size(375, 900),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        await route(tester);
        await next(tester, s);
        expect(tester.takeException(), isNull);
        await next(tester, s);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(field(s.postMake)).width, greaterThan(250));
        // Check the allocated label width, not line counts: the widget test's
        // monospace Ahem font differs from the browser's real rendering font.
        for (final label in [s.postRoute, s.postPolicies]) {
          final column = find
              .ancestor(of: find.text(label), matching: find.byType(Column))
              .first;
          expect(tester.getSize(column).width, greaterThan(65));
        }
        await enter(tester, s.postPricePerSeat, '15');
        await next(tester, s);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text(s.postReady),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text(s.postReady), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(inserts, isEmpty);
      });
    }
  }
}
