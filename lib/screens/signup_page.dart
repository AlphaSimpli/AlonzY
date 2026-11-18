import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/auth_error_localization.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.length < 6) {
      _showMessage(AppLocalizations.of(context).signupValidation);
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName.isEmpty ? null : firstName,
        lastName: lastName.isEmpty ? null : lastName,
        phone: phone.isEmpty ? null : phone,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).accountCreated),
            duration: const Duration(seconds: 4),
          ),
        );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      _showMessage(
        localizedAuthError(e, strings, fallback: strings.authSignupFailed),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AuthLayout(
      title: strings.signupTitle,
      subtitle: strings.signupSubtitle,
      footer: Center(
        child: Text(
          strings.signupTermsNotice,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                enabled: !_loading,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.firstNameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                enabled: !_loading,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: strings.lastNameLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          enabled: !_loading,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
          ],
          decoration: InputDecoration(
            labelText: strings.optionalPhoneLabel,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 14),
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
          onSubmitted: (_) => _signUp(),
          decoration: InputDecoration(
            labelText: strings.passwordLabel,
            helperText: strings.passwordLengthHint,
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
          onPressed: _loading ? null : _signUp,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(strings.createAccount),
        ),
      ],
    );
  }
}
