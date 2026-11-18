import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/screens/my_bookings_page.dart';

void main() {
  const sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          sharedPreferencesChannel,
          (_) async => <String, Object>{},
        );
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-public-key',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: const EmptyLocalStorage(),
      ),
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, null);
    await Supabase.instance.dispose();
  });

  Future<void> pumpBookings(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const MyBookingsPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('French bookings title, tabs and empty state are translated', (
    tester,
  ) async {
    await pumpBookings(tester, const Locale('fr'));

    expect(find.text('Mes réservations'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Passés'), findsOneWidget);
    expect(find.text('Aucune réservation à venir'), findsOneWidget);
    expect(
      find.text('Explorez les trajets disponibles et réservez !'),
      findsOneWidget,
    );
    expect(find.text('My Bookings'), findsNothing);
    expect(find.text('Upcoming'), findsNothing);
    expect(find.text('No upcoming bookings'), findsNothing);

    await tester.tap(find.text('Passés'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune réservation passée'), findsOneWidget);
    expect(
      find.text('L’historique de vos trajets apparaîtra ici.'),
      findsOneWidget,
    );
  });

  testWidgets('English bookings labels remain available', (tester) async {
    await pumpBookings(tester, const Locale('en'));

    expect(find.text('My bookings'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.text('No upcoming bookings'), findsOneWidget);
    expect(find.text('Browse available rides and book one!'), findsOneWidget);
  });
}
