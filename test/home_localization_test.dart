import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/screens/home_page.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';

// Exercise the actual home content and navigation without mounting the other
// tabs, starting Supabase subscriptions, or performing database operations.
void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    String language = 'fr',
    Size size = const Size(1280, 1000),
    double textScale = 1,
    int currentIndex = 0,
    ValueChanged<int>? onNavigate,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    void navigate(int index) => onNavigate?.call(index);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: HomeTab(onNavigateToTab: navigate),
          bottomNavigationBar: HomeNavigationBar(
            currentIndex: currentIndex,
            onDestinationSelected: navigate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in ['fr', 'en']) {
    testWidgets('home cards and navigation labels are translated in $locale', (
      tester,
    ) async {
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await pumpHome(tester, language: locale);
      for (final label in [
        strings.homeDriveTitle,
        strings.homeDriveSubtitle,
        strings.homePostRide,
        strings.homeFindTitle,
        strings.homeFindSubtitle,
        strings.homeSearchRides,
        strings.navHome,
        strings.navSearch,
        strings.navPost,
        strings.navBookingsShort,
        strings.navChat,
        strings.navProfile,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byTooltip(strings.navBookings), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'home buttons keep their original destination indices in $locale',
      (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(locale));
        final destinations = <int>[];
        await pumpHome(tester, language: locale, onNavigate: destinations.add);
        for (final label in [strings.homePostRide, strings.homeSearchRides]) {
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        expect(destinations, [2, 1]);
      },
    );

    testWidgets(
      'all six navigation destinations retain order and selection in $locale',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          final strings = await AppLocalizations.delegate.load(Locale(locale));
          final destinations = <int>[];
          final labels = [
            strings.navHome,
            strings.navSearch,
            strings.navPost,
            strings.navBookings,
            strings.navChat,
            strings.navProfile,
          ];
          for (var index = 0; index < labels.length; index++) {
            await pumpHome(
              tester,
              language: locale,
              currentIndex: index,
              onNavigate: destinations.add,
            );
            final destination = find.bySemanticsLabel(labels[index]);
            expect(destination, findsOneWidget);
            expect(
              tester.getSemantics(destination),
              matchesSemantics(
                label: labels[index],
                isButton: true,
                hasSelectedState: true,
                isSelected: true,
                hasTapAction: true,
              ),
            );
            await tester.tap(destination);
            await tester.pumpAndSettle();
          }
          expect(destinations, [0, 1, 2, 3, 4, 5]);
        } finally {
          handle.dispose();
        }
      },
    );

    for (final width in [375.0, 1280.0]) {
      testWidgets('home fits $width px in $locale', (tester) async {
        await pumpHome(tester, language: locale, size: Size(width, 900));
        expect(tester.takeException(), isNull);
        final strings = await AppLocalizations.delegate.load(Locale(locale));
        await tester.ensureVisible(find.text(strings.homeSearchRides));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('home fits 375 px with 140 percent text in $locale', (
      tester,
    ) async {
      await pumpHome(
        tester,
        language: locale,
        size: const Size(375, 900),
        textScale: 1.4,
      );
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await tester.ensureVisible(find.text(strings.homeSearchRides));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('home text updates when the app locale changes', (tester) async {
    await pumpHome(tester);
    expect(find.text('Accueil'), findsOneWidget);
    await pumpHome(tester, language: 'en');
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Accueil'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
