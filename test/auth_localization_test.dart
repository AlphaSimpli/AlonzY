import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter_app/l10n/auth_error_localization.dart';
import 'package:supabase_flutter_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter_app/screens/login_page.dart';
import 'package:supabase_flutter_app/screens/signup_page.dart';
import 'package:supabase_flutter_app/theme/app_theme.dart';

class _TestPkceStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> setItem({required String key, required String value}) async {}

  @override
  Future<void> removeItem({required String key}) async {}
}

// All HTTP is simulated. No real account, SMS or live session is created.
void main() {
  final requests = <http.Request>[];
  var rejectSignup = false;
  const user = {
    'id': '00000000-0000-4000-8000-000000000001',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'test@example.com',
    'created_at': '2026-11-16T12:00:00Z',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
  };

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-public-key',
      debug: false,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _TestPkceStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/otp')) {
          return http.Response('{}', 200);
        }
        if (path.endsWith('/signup') && !rejectSignup) {
          return http.Response(jsonEncode(user), 200);
        }
        if (path == '/rest/v1/profiles') {
          return http.Response('', 204, request: request);
        }
        return http.Response(
          jsonEncode({
            'code': path.endsWith('/verify')
                ? 'otp_expired'
                : 'invalid_credentials',
            'msg': path.endsWith('/verify')
                ? 'Token has expired or is invalid'
                : 'Invalid login credentials',
          }),
          400,
        );
      }),
    );
  });

  setUp(() {
    requests.clear();
    rejectSignup = false;
  });

  tearDownAll(() async => Supabase.instance.dispose());

  Future<void> pumpPage(
    WidgetTester tester, {
    String language = 'fr',
    Widget page = const LoginPage(),
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('French and English catalogues contain exactly the same messages', () {
    Set<String> keys(String locale) =>
        (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .where((key) => !key.startsWith('@'))
            .toSet();
    expect(keys('fr'), keys('en'));
  });

  for (final locale in ['fr', 'en']) {
    test('known and unknown auth errors are localized in $locale', () async {
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      for (final entry in {
        'Incorrect email or password': strings.authIncorrectCredentials,
        'An account with this email already exists': strings.authAccountExists,
        'Please verify your email before signing in':
            strings.authEmailNotConfirmed,
        'Invalid email': strings.authInvalidEmail,
        'Invalid phone number': strings.authInvalidPhone,
        'Token has expired or is invalid': strings.authInvalidCode,
        'Too many requests': strings.authRateLimited,
        'Weak password': strings.authWeakPassword,
      }.entries) {
        expect(
          localizedAuthError(
            Exception(entry.key),
            strings,
            fallback: strings.authLoginFailed,
          ),
          entry.value,
        );
      }
      expect(
        localizedAuthError(
          const AuthException('Opaque message', code: 'otp_expired'),
          strings,
          fallback: strings.authVerifyCodeFailed,
        ),
        strings.authInvalidCode,
      );
      expect(
        localizedAuthError(
          Exception('Private backend detail'),
          strings,
          fallback: strings.authLoginFailed,
        ),
        strings.authLoginFailed,
      );
    });

    testWidgets('login and signup render translated labels in $locale', (
      tester,
    ) async {
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await pumpPage(tester, language: locale);
      expect(find.text(strings.loginTitle), findsOneWidget);
      expect(field(strings.emailLabel), findsOneWidget);
      expect(field(strings.passwordLabel), findsOneWidget);
      await tapText(tester, strings.createAnAccount);
      expect(find.text(strings.signupTitle), findsOneWidget);
      expect(field(strings.firstNameLabel), findsOneWidget);
      expect(field(strings.lastNameLabel), findsOneWidget);
      expect(field(strings.optionalPhoneLabel), findsOneWidget);
      expect(find.text(strings.signupTermsNotice), findsOneWidget);
      expect(requests, isEmpty);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text(strings.loginTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty email and signup are rejected locally in $locale', (
      tester,
    ) async {
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await pumpPage(tester, language: locale);
      await tapText(tester, strings.signIn);
      expect(find.text(strings.enterEmailAndPassword), findsOneWidget);
      await tapText(tester, strings.createAnAccount);
      await tapText(tester, strings.createAccount);
      expect(find.text(strings.signupValidation), findsOneWidget);
      expect(requests, isEmpty);
    });

    testWidgets('phone flow and OTP errors are translated in $locale', (
      tester,
    ) async {
      final strings = await AppLocalizations.delegate.load(Locale(locale));
      await pumpPage(tester, language: locale);
      await tapText(tester, strings.phoneTab);
      expect(find.text(strings.phoneCodeExplanation), findsOneWidget);
      await tapText(tester, strings.sendCode);
      expect(find.text(strings.enterPhoneNumber), findsOneWidget);
      expect(requests, isEmpty);
      await tester.enterText(field(strings.phoneNumberLabel), '+15145550123');
      await tapText(tester, strings.sendCode);
      expect(field(strings.verificationCodeLabel), findsOneWidget);
      expect(requests, hasLength(1));
      expect(jsonDecode(requests.first.body)['phone'], '+15145550123');
      await tapText(tester, strings.verifyAndSignIn);
      expect(find.text(strings.enterReceivedCode), findsOneWidget);
      expect(requests, hasLength(1));
      await tester.enterText(field(strings.verificationCodeLabel), '123456');
      await tapText(tester, strings.verifyAndSignIn);
      expect(find.text(strings.authInvalidCode), findsOneWidget);
      expect(jsonDecode(requests.last.body)['token'], '123456');
      await tapText(tester, strings.changePhoneNumber);
      expect(field(strings.verificationCodeLabel), findsNothing);
      expect(
        tester
            .widget<TextField>(field(strings.phoneNumberLabel))
            .controller!
            .text,
        '+15145550123',
      );
    });

    testWidgets(
      'login sends unchanged credentials and translates refusal in $locale',
      (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(locale));
        await pumpPage(tester, language: locale);
        await tester.enterText(field(strings.emailLabel), 'test@example.com');
        await tester.enterText(field(strings.passwordLabel), 'secret123');
        await tester.tap(find.byTooltip(strings.showPassword));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field(strings.passwordLabel)).obscureText,
          isFalse,
        );
        await tester.tap(find.byTooltip(strings.hidePassword));
        await tester.pumpAndSettle();
        await tapText(tester, strings.signIn);
        expect(find.text(strings.authIncorrectCredentials), findsOneWidget);
        expect(requests, hasLength(1));
        final body = jsonDecode(requests.single.body);
        expect(body['email'], 'test@example.com');
        expect(body['password'], 'secret123');
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'signup success preserves payload and returns to login in $locale',
      (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(locale));
        await pumpPage(tester, language: locale);
        await tapText(tester, strings.createAnAccount);
        await tester.enterText(field(strings.firstNameLabel), 'Test');
        await tester.enterText(field(strings.lastNameLabel), 'User');
        await tester.enterText(
          field(strings.optionalPhoneLabel),
          '+15145550123',
        );
        await tester.enterText(field(strings.emailLabel), 'test@example.com');
        await tester.enterText(field(strings.passwordLabel), 'secret123');
        await tapText(tester, strings.createAccount);
        expect(find.text(strings.loginTitle), findsOneWidget);
        expect(find.text(strings.accountCreated), findsOneWidget);
        final signup = requests.firstWhere(
          (request) => request.url.path.endsWith('/signup'),
        );
        final body = jsonDecode(signup.body);
        expect(body['email'], 'test@example.com');
        expect(body['password'], 'secret123');
        expect(body['data'], {
          'first_name': 'Test',
          'last_name': 'User',
          'phone': '+15145550123',
        });
        expect(requests.last.url.path, '/rest/v1/profiles');
      },
    );
  }

  for (final size in [const Size(375, 812), const Size(1280, 900)]) {
    for (final page in [const LoginPage(), const SignupPage()]) {
      testWidgets('French ${page.runtimeType} fits ${size.width}px', (
        tester,
      ) async {
        await pumpPage(tester, page: page, size: size);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
