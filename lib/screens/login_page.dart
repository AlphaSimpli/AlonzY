import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/auth_error_localization.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';
import 'signup_page.dart';

/// Sign-in with email/password or phone (OTP).
///
/// Session changes are handled by the [AuthGate] in `main.dart` via the auth
/// stream; this screen never navigates on its own after a successful sign-in.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  int _mode = 0; // 0 = email, 1 = phone
  bool _codeSent = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(AppLocalizations.of(context).enterEmailAndPassword);
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.signIn(email: email, password: password);
      // Navigation handled by AuthGate via the auth stream.
    } catch (e) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      _showMessage(
        localizedAuthError(e, strings, fallback: strings.authLoginFailed),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage(AppLocalizations.of(context).enterPhoneNumber);
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.sendPhoneOtp(phone);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final strings = AppLocalizations.of(context);
      _showMessage(
        localizedAuthError(e, strings, fallback: strings.authSendCodeFailed),
      );
    }
  }

  Future<void> _verifyCode() async {
    final phone = _phoneController.text.trim();
    final token = _otpController.text.trim();
    if (token.isEmpty) {
      _showMessage(AppLocalizations.of(context).enterReceivedCode);
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.verifyPhoneOtp(phone, token);
      // Navigation handled by AuthGate via the auth stream.
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final strings = AppLocalizations.of(context);
      _showMessage(
        localizedAuthError(e, strings, fallback: strings.authVerifyCodeFailed),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AuthLayout(
      title: strings.loginTitle,
      subtitle: strings.loginSubtitle,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            strings.newToAlonzy,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupPage()),
                  ),
            child: Text(strings.createAnAccount),
          ),
        ],
      ),
      children: [
        SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              label: Text(strings.emailLabel),
              icon: const Icon(Icons.alternate_email, size: 18),
            ),
            ButtonSegment(
              value: 1,
              label: Text(strings.phoneTab),
              icon: const Icon(Icons.phone_android, size: 18),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: _loading
              ? null
              : (selection) => setState(() => _mode = selection.first),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _mode == 0 ? _buildEmailForm() : _buildPhoneForm(),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    final strings = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: strings.emailLabel,
            prefixIcon: const Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          enabled: !_loading,
          obscureText: _obscurePassword,
          onSubmitted: (_) => _signInWithEmail(),
          decoration: InputDecoration(
            labelText: strings.passwordLabel,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? strings.showPassword
                  : strings.hidePassword,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _signInWithEmail,
          child: _loading ? const _ButtonSpinner() : Text(strings.signIn),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    final strings = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          enabled: !_loading,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
          ],
          decoration: InputDecoration(
            labelText: strings.phoneNumberLabel,
            prefixIcon: const Icon(Icons.phone_android),
            hintText: strings.phoneNumberHint,
          ),
        ),
        if (!_codeSent) ...[
          const SizedBox(height: 14),
          Text(
            strings.phoneCodeExplanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _sendCode,
            child: _loading ? const _ButtonSpinner() : Text(strings.sendCode),
          ),
        ] else ...[
          const SizedBox(height: 14),
          TextField(
            controller: _otpController,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyCode(),
            decoration: InputDecoration(
              labelText: strings.verificationCodeLabel,
              prefixIcon: const Icon(Icons.sms_outlined),
              hintText: strings.verificationCodeHint,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() => _codeSent = false),
            child: Text(strings.changePhoneNumber),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loading ? null : _verifyCode,
            child: _loading
                ? const _ButtonSpinner()
                : Text(strings.verifyAndSignIn),
          ),
        ],
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
