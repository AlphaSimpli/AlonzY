import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/l10n/app_locale_controller.dart';
import 'package:supabase_flutter_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Inspect MyApp's MaterialApp without mounting AuthGate or initializing Supabase.
Future<MaterialApp> readAppConfiguration(WidgetTester tester) async {
  late MaterialApp configuration;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final root =
            const MyApp().build(context) as ValueListenableBuilder<Locale>;
        configuration =
            root.builder(context, root.valueListenable.value, null)
                as MaterialApp;
        return const SizedBox.shrink();
      },
    ),
  );
  return configuration;
}

Future<void> pumpLocalizedProbe(
  WidgetTester tester,
  MaterialApp configuration,
  Locale locale,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: configuration.supportedLocales,
      localizationsDelegates: configuration.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLocaleController.current.value = const Locale('fr');
  });

  testWidgets('app defaults to French and supports French and English', (
    tester,
  ) async {
    final configuration = await readAppConfiguration(tester);

    expect(configuration.locale, const Locale('fr'));
    expect(configuration.supportedLocales, const [Locale('fr'), Locale('en')]);
    expect(configuration.home, isA<AuthGate>());
  });

  testWidgets('Material controls load French translations', (tester) async {
    final configuration = await readAppConfiguration(tester);
    await pumpLocalizedProbe(tester, configuration, const Locale('fr'));

    expect(find.text('Annuler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Material controls can still load English translations', (
    tester,
  ) async {
    final configuration = await readAppConfiguration(tester);
    await pumpLocalizedProbe(tester, configuration, const Locale('en'));

    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('language setting switches the application locale', (
    tester,
  ) async {
    await AppLocaleController.setLanguage('fr');
    final configuration = await readAppConfiguration(tester);
    await AppLocaleController.setLanguage('en');
    await tester.pumpWidget(
      MaterialApp(
        locale: AppLocaleController.current.value,
        supportedLocales: configuration.supportedLocales,
        localizationsDelegates: configuration.localizationsDelegates,
        home: const SizedBox.shrink(),
      ),
    );
    expect(AppLocaleController.current.value, const Locale('en'));
    expect(
      SharedPreferences.getInstance().then(
        (preferences) => preferences.getString('app_language'),
      ),
      completion('en'),
    );
    expect(tester.takeException(), isNull);
    await AppLocaleController.setLanguage('fr');
  });

  testWidgets('saved language is restored and first install defaults to French', (
    tester,
  ) async {
    await AppLocaleController.loadSavedLanguage();
    expect(AppLocaleController.current.value, const Locale('fr'));

    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    await AppLocaleController.loadSavedLanguage();
    expect(AppLocaleController.current.value, const Locale('en'));
  });
}
