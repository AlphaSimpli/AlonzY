import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/models/app_user.dart';
import 'package:supabase_flutter_app/screens/chat_list_page.dart';
import 'package:supabase_flutter_app/screens/edit_profile_page.dart';

void main() {
  const preferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          preferencesChannel,
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
        .setMockMethodCallHandler(preferencesChannel, null);
    await Supabase.instance.dispose();
  });

  Future<void> pumpFrench(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('messages list uses French labels and empty state', (
    tester,
  ) async {
    await pumpFrench(tester, const ChatListPage());

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Aucune conversation pour le moment'), findsOneWidget);
    expect(
      find.text(
        'Écrivez au conducteur d’un trajet ou à un passager de vos réservations '
        'pour commencer à discuter.',
      ),
      findsOneWidget,
    );
    expect(find.text('No conversations yet'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile editor uses French labels', (tester) async {
    await pumpFrench(
      tester,
      const EditProfilePage(
        user: AppUser(
          id: 'profile-1',
          firstName: 'Camille',
          lastName: 'Roy',
          isDriver: true,
        ),
      ),
    );

    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Renseignements personnels'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Téléphone'), findsOneWidget);
    expect(find.text('Moyen de contact préféré'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Enregistrer les modifications'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Enregistrer les modifications'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
    expect(find.text('First name'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
