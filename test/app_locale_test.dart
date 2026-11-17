import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/main.dart';

// Inspect MyApp's MaterialApp without mounting AuthGate or initializing Supabase.
Future<MaterialApp> readAppConfiguration(WidgetTester tester) async {
  late MaterialApp configuration;
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        configuration = const MyApp().build(context) as MaterialApp;
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
}
