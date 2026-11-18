import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/l10n/app_formatters.dart';

void main() {
  testWidgets(
    'CAD formatting follows the selected French and English locales',
    (tester) async {
      String? formatted;

      Future<void> readMoney(Locale locale) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('fr'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                formatted = formatCadMoney(context, 15);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();
      }

      await readMoney(const Locale('fr'));
      expect(formatted?.replaceAll('\u00a0', ' '), '15,00 \$');

      await readMoney(const Locale('en'));
      expect(formatted, '\$15.00');
    },
  );
}
