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
import 'package:supabase_flutter_app/models/app_user.dart';
import 'package:supabase_flutter_app/models/ride.dart';
import 'package:supabase_flutter_app/screens/ride_details_page.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';
import 'package:supabase_flutter_app/widgets/verification_badges.dart';

// All authentication, HTTP, ride data and map commands below are simulated.
// No real booking, live session, map tiles or deployed RLS policy is exercised.
class _PkceStorage extends GotrueAsyncStorage {
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
  int clears = 0;
  @override
  Future<void> clear() async => clears++;
  @override
  Future<void> addMarker(MapMarkerData marker) async => markers.add(marker);
  @override
  Future<void> addPolyline(MapPolylineData polyline) async =>
      lines.add(polyline);
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

class _MapProvider extends MapProvider {
  const _MapProvider(this.controller);
  final _MapRecorder controller;
  @override
  MapView createView(MapViewConfig config) => _MapView(config, controller);
}

class _MapView extends MapView {
  const _MapView(MapViewConfig config, this.controller) : super(config: config);
  final _MapRecorder controller;
  @override
  Widget build({
    required void Function(AppMapController) onMapCreated,
    VoidCallback? onMapIdle,
  }) => _MapSurface(controller: controller, onReady: onMapCreated);
}

class _MapSurface extends StatefulWidget {
  const _MapSurface({required this.controller, required this.onReady});
  final _MapRecorder controller;
  final void Function(AppMapController) onReady;
  @override
  State<_MapSurface> createState() => _MapSurfaceState();
}

class _MapSurfaceState extends State<_MapSurface> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady(widget.controller);
    });
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.grey,
    child: Center(child: Text('Fake map')),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const passengerId = '00000000-0000-4000-8000-000000000001';
  final requests = <http.Request>[];
  String? bookingError;
  bool chatError = false;
  Completer<void>? pendingBooking;
  late MapProvider previousMapProvider;
  late _MapRecorder map;
  bool? returnedFromBooking;

  Map<String, dynamic> session() {
    final user = {
      'id': passengerId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'passenger@example.com',
      'created_at': '2026-11-16T12:00:00Z',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
    };
    final claims = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': passengerId,
              'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            }),
          ),
        )
        .replaceAll('=', '');
    return {
      'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.test-signature',
      'refresh_token': 'simulated-refresh-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': user,
    };
  }

  setUpAll(() async {
    previousMapProvider = AppMaps.provider;
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-public-key',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _PkceStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        Object? body;
        var status = 200;
        if (request.url.path.endsWith('/token')) {
          body = session();
        } else if (request.url.path.endsWith('/create_booking_request')) {
          if (pendingBooking != null) await pendingBooking!.future;
          if (bookingError != null) {
            status = 400;
            body = {'code': 'P0001', 'message': bookingError};
          } else {
            body = 'booking-test';
          }
        } else if (request.url.path.endsWith('/conversations') && chatError) {
          status = 403;
          body = {'code': '42501', 'message': 'private chat diagnostic'};
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
      email: 'passenger@example.com',
      password: 'simulated-password',
    );
  });

  setUp(() {
    requests.clear();
    bookingError = null;
    chatError = false;
    pendingBooking = null;
    returnedFromBooking = null;
    map = _MapRecorder();
    AppMaps.configure(_MapProvider(map));
  });

  tearDown(() {
    if (pendingBooking != null && !pendingBooking!.isCompleted) {
      pendingBooking!.complete();
    }
  });
  tearDownAll(() async {
    AppMaps.configure(previousMapProvider);
    await Supabase.instance.dispose();
  });

  Ride ride({
    bool instant = false,
    bool pets = true,
    String luggage = 'moderate',
    String type = 'sedan',
    int seats = 3,
    int completed = 2,
    bool driver = true,
    bool vehicleDetails = true,
  }) => Ride(
    id: 'ride-test',
    driverId: 'driver-test',
    originCity: 'Ottawa',
    destinationCity: 'Gatineau',
    originAddress: 'Ottawa centre',
    destinationAddress: 'Gatineau centre',
    originLat: 45.42,
    originLng: -75.69,
    destinationLat: 45.48,
    destinationLng: -75.7,
    departureTime: DateTime(2026, 11, 20, 18, 30),
    availableSeats: seats,
    pricePerSeat: 10.5,
    vehicleType: type,
    vehicleMake: vehicleDetails ? 'Toyota' : null,
    vehicleModel: vehicleDetails ? 'Corolla' : null,
    vehicleColor: vehicleDetails ? 'Bleu personnel' : null,
    vehiclePlate: vehicleDetails ? 'ABC 123' : null,
    vehicleYear: vehicleDetails ? 2020 : null,
    instantBooking: instant,
    petsAllowed: pets,
    luggagePolicy: luggage,
    notes: 'Notes personnelles à conserver',
    driver: driver
        ? AppUser(
            id: 'driver-test',
            firstName: 'Camille',
            lastName: 'Exemple',
            rating: 4.5,
            verifiedRides: completed,
            emailVerified: true,
            phoneVerified: false,
            govtIdStatus: 'pending',
            bio: 'Biographie personnelle à conserver',
          )
        : null,
  );

  Future<AppLocalizations> open(
    WidgetTester tester,
    String language, {
    Ride? offer,
    Size size = const Size(1280, 1100),
    double scale = 1,
  }) async {
    await tester.pumpWidget(const SizedBox());
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
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                returnedFromBooking = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RideDetailsPage(ride: offer ?? ride()),
                  ),
                );
              },
              child: const Text('Open test ride'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open test ride'));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(Locale(language));
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Finder seatButton(String tooltip) => find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == tooltip,
  );

  Future<void> book(
    WidgetTester tester,
    AppLocalizations strings, {
    int count = 1,
    bool settle = true,
  }) async {
    final button = find.widgetWithText(
      ElevatedButton,
      strings.detailsBookSeats(count),
    );
    await reveal(tester, button);
    await tester.tap(button);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  String money(String locale, num value) => NumberFormat.currency(
    locale: locale == 'fr' ? 'fr_CA' : 'en_CA',
    name: 'CAD',
    symbol: '\$',
  ).format(value);

  for (final language in ['fr', 'en']) {
    testWidgets('driver, date and preserved personal text in $language', (
      tester,
    ) async {
      final strings = await open(tester, language);
      expect(find.text(strings.detailsTitle), findsOneWidget);
      expect(find.text('Ottawa centre'), findsOneWidget);
      expect(find.text('Gatineau centre'), findsOneWidget);
      expect(find.text('Camille Exemple'), findsOneWidget);
      expect(
        find.text(strings.detailsRating(language == 'fr' ? '4,5' : '4.5')),
        findsOneWidget,
      );
      expect(find.text(strings.detailsCompletedTrips(2)), findsOneWidget);
      expect(find.text('Biographie personnelle à conserver'), findsOneWidget);
      final context = tester.element(find.byType(RideDetailsPage));
      expect(
        find.text(
          strings.detailsDateTime(
            DateFormat.yMMMd(language).format(DateTime(2026, 11, 20)),
            MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(const TimeOfDay(hour: 18, minute: 30)),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(strings.verificationVerified(strings.verificationEmail)),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          strings.verificationPending(strings.verificationGovernmentId),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unchanged map commands and framing in $language', (
      tester,
    ) async {
      await open(tester, language);
      final offer = ride();
      expect(map.clears, 1);
      expect(map.markers.map((m) => m.id), ['pickup', 'dropoff']);
      expect(map.markers.map((m) => m.label), [
        'Ottawa centre',
        'Gatineau centre',
      ]);
      expect(map.markers.map((m) => m.location), [offer.start, offer.end]);
      expect(map.lines.single.points, [offer.start, offer.end]);
      expect(map.bounds, [offer.start, offer.end]);
      expect(map.padding, 24);
    });

    testWidgets('vehicle and luggage categories in $language', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      for (final entry in {
        'none': strings.detailsLuggageNone,
        'small': strings.detailsLuggageSmall,
        'moderate': strings.detailsLuggageStandard,
        'large': strings.detailsLuggageLarge,
      }.entries) {
        await open(tester, language, offer: ride(luggage: entry.key));
        await reveal(tester, find.text(strings.detailsVehicleHeading));
        expect(find.text(entry.value), findsOneWidget);
        expect(
          find.text(
            'Bleu personnel Toyota Corolla ${strings.detailsSedan} (2020) · ABC 123',
          ),
          findsOneWidget,
        );
        expect(find.text('Notes personnelles à conserver'), findsOneWidget);
      }
    });

    testWidgets('other vehicle types and empty driver fallback in $language', (
      tester,
    ) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      for (final entry in {
        'suv': strings.detailsSuv,
        'van': strings.detailsVan,
        'custom-category': 'custom-category',
        '': strings.detailsVehicleUnspecified,
      }.entries) {
        await open(
          tester,
          language,
          offer: ride(
            type: entry.key,
            driver: false,
            vehicleDetails: false,
            pets: false,
          ),
        );
        expect(find.text(strings.searchDriver), findsOneWidget);
        await reveal(tester, find.text(strings.detailsVehicleHeading));
        expect(find.text(entry.value), findsOneWidget);
        expect(find.text(strings.detailsPetsNotAllowed), findsOneWidget);
      }
    });

    testWidgets('seat limits, plural and total in $language', (tester) async {
      final strings = await open(tester, language);
      await reveal(tester, find.byTooltip(strings.searchMoreSeats));
      expect(
        tester
            .widget<IconButton>(seatButton(strings.searchFewerSeats))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip(strings.searchMoreSeats));
      await tester.pumpAndSettle();
      expect(find.text(strings.detailsBookSeats(2)), findsOneWidget);
      expect(find.text(money(language, 21)), findsOneWidget);
      await tester.tap(find.byTooltip(strings.searchMoreSeats));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(seatButton(strings.searchMoreSeats))
            .onPressed,
        isNull,
      );
      expect(find.text(money(language, 31.5)), findsOneWidget);
      expect(requests, isEmpty);
    });

    for (final instant in [false, true]) {
      testWidgets('booking success instant=$instant in $language', (
        tester,
      ) async {
        final strings = await open(
          tester,
          language,
          offer: ride(instant: instant),
        );
        await reveal(tester, find.byTooltip(strings.searchMoreSeats));
        await tester.tap(find.byTooltip(strings.searchMoreSeats));
        await tester.pumpAndSettle();
        await book(tester, strings, count: 2);
        final request = requests.singleWhere(
          (r) => r.url.path.endsWith('/create_booking_request'),
        );
        expect(jsonDecode(request.body), {
          'p_ride_id': 'ride-test',
          'p_seats_booked': 2,
          'p_total_price': 21.0,
          'p_pickup_location': null,
        });
        expect(returnedFromBooking, isTrue);
        expect(
          find.text(
            instant
                ? strings.detailsBookingConfirmed
                : strings.detailsBookingRequested,
          ),
          findsOneWidget,
        );
      });
    }

    for (final error in [
      'active booking',
      'Not enough seats',
      'private diagnostic',
    ]) {
      testWidgets('booking error $error in $language', (tester) async {
        bookingError = error;
        final strings = await open(tester, language);
        await book(tester, strings);
        final expected = error == 'active booking'
            ? strings.detailsAlreadyBooked
            : error == 'Not enough seats'
            ? strings.detailsNotEnoughSeats
            : strings.detailsBookingFailed;
        expect(find.text(expected), findsOneWidget);
        expect(find.textContaining('private diagnostic'), findsNothing);
        expect(returnedFromBooking, isNull);
        expect(requests.any((r) => r.url.path == '/rest/v1/rides'), isTrue);
      });
    }

    testWidgets('chat error is translated in $language', (tester) async {
      chatError = true;
      final strings = await open(tester, language);
      final button = find.widgetWithText(
        OutlinedButton,
        strings.detailsMessageDriver,
      );
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(strings.detailsChatFailed), findsOneWidget);
      expect(find.textContaining('private chat diagnostic'), findsNothing);
      expect(requests.single.url.path, '/rest/v1/conversations');
    });

    testWidgets('booking busy state disables controls in $language', (
      tester,
    ) async {
      pendingBooking = Completer<void>();
      final strings = await open(tester, language);
      await book(tester, strings, settle: false);
      expect(find.text(strings.detailsBookingLoading), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(
                ElevatedButton,
                strings.detailsBookingLoading,
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(seatButton(strings.searchMoreSeats))
            .onPressed,
        isNull,
      );
      pendingBooking!.complete();
      await tester.pumpAndSettle();
      expect(
        requests.where((r) => r.url.path.endsWith('/create_booking_request')),
        hasLength(1),
      );
    });

    for (final scale in [1.0, 1.4]) {
      testWidgets('375px layout ${scale}x in $language', (tester) async {
        final strings = await open(
          tester,
          language,
          size: const Size(375, 900),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        await reveal(tester, find.text(strings.detailsVehicleHeading));
        expect(tester.takeException(), isNull);
        await reveal(tester, find.text(strings.detailsBookSeats(1)));
        expect(tester.takeException(), isNull);
        expect(find.text(money(language, 10.5)), findsOneWidget);
      });
    }
  }

  testWidgets('full verification badges translate their pending status', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: VerificationBadges(
            user: AppUser(
              id: 'test',
              emailVerified: true,
              govtIdStatus: 'pending',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final strings = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(strings.verificationEmail), findsOneWidget);
    expect(
      find.text(strings.verificationPending(strings.verificationGovernmentId)),
      findsOneWidget,
    );
    expect(
      find.byTooltip(strings.verificationUnverified(strings.verificationPhone)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'booking, remaining seats and completed trips use correct plurals',
    () async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(fr.detailsBookSeats(1), 'Réserver 1 place');
      expect(fr.detailsBookSeats(2), 'Réserver 2 places');
      expect(fr.detailsSeatsLeft(1), 'Il ne reste qu’une place');
      expect(fr.detailsCompletedTrips(1), '1 trajet effectué');
      expect(fr.detailsCompletedTrips(2), '2 trajets effectués');
      expect(en.detailsBookSeats(1), 'Book 1 seat');
      expect(en.detailsBookSeats(2), 'Book 2 seats');
      expect(en.detailsSeatsLeft(1), 'Only 1 seat left');
    },
  );
}
