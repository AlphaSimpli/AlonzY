import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/screens/profile_page.dart';

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

  Future<void> pumpProfile(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('profile labels are translated in French', (tester) async {
    await pumpProfile(tester, const Locale('fr'));

    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text('Pièce d’identité'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mode conducteur'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mode conducteur'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Raccourcis'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Raccourcis'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('Phone'), findsNothing);
    expect(find.text('Government ID'), findsNothing);
    expect(find.text('Driver Mode'), findsNothing);
    expect(find.text('Quick Actions'), findsNothing);
    expect(find.text('Logout'), findsNothing);
  });

  testWidgets('profile labels are translated in English', (tester) async {
    await pumpProfile(tester, const Locale('en'));

    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Government ID'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Driver mode'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Driver mode'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quick actions'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Quick actions'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Log out'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Log out'), findsOneWidget);
  });
}
