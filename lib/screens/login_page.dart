import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      _showMessage('Enter your email and password');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.signIn(email: email, password: password);
      // Navigation handled by AuthGate via the auth stream.
    } catch (e) {
      if (!mounted) return;
      _showMessage('$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Enter your phone number');
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
      _showMessage('$e'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _verifyCode() async {
    final phone = _phoneController.text.trim();
    final token = _otpController.text.trim();
    if (token.isEmpty) {
      _showMessage('Enter the code you received');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.verifyPhoneOtp(phone, token);
      // Navigation handled by AuthGate via the auth stream.
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('$e'.replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Sign in to find or share your next ride.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'New to Alonzy?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupPage(),
                      ),
                    ),
            child: const Text('Create an account'),
          ),
        ],
      ),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Email'),
              icon: Icon(Icons.alternate_email, size: 18),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Phone'),
              icon: Icon(Icons.phone_android, size: 18),
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
          child: _mode == 0
              ? _buildEmailForm()
              : _buildPhoneForm(),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
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
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          enabled: !_loading,
          obscureText: _obscurePassword,
          onSubmitted: (_) => _signInWithEmail(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
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
          child: _loading
              ? const _ButtonSpinner()
              : const Text('Sign in'),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
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
          decoration: const InputDecoration(
            labelText: 'Phone number',
            prefixIcon: Icon(Icons.phone_android),
            hintText: 'e.g. +15145550123',
          ),
        ),
        if (!_codeSent) ...[
          const SizedBox(height: 14),
          Text(
            'We\'ll text you a one-time code to sign in.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _sendCode,
            child: _loading
                ? const _ButtonSpinner()
                : const Text('Send code'),
          ),
        ] else ...[
          const SizedBox(height: 14),
          TextField(
            controller: _otpController,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verifyCode(),
            decoration: const InputDecoration(
              labelText: 'Verification code',
              prefixIcon: Icon(Icons.sms_outlined),
              hintText: '6-digit code',
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() => _codeSent = false),
            child: const Text('Change phone number'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loading ? null : _verifyCode,
            child: _loading
                ? const _ButtonSpinner()
                : const Text('Verify & sign in'),
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