import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication helpers built on top of Supabase Auth.
///
/// Supports email/password and phone OTP flows. Sessions are persisted by
/// Supabase automatically; the [AuthGate] in `main.dart` reacts to the auth
/// stream, so screens never navigate manually after sign-in/out.
class AuthService {
  final supabase = Supabase.instance.client;

  /// Creates an account with email + password and updates the profile row
  /// (auto-created by the `on_auth_user_created` trigger) with any extra info.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        final updates = <String, dynamic>{
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        };
        if (updates.isNotEmpty) {
          await supabase.from('profiles').update(updates).eq('id', response.user!.id);
        }
      }

      return response;
    } on AuthException catch (e) {
      debugPrint('SIGNUP AUTH ERROR: ${e.message}');
      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');
      throw Exception('Unexpected error during signup');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      debugPrint('LOGIN AUTH ERROR: ${e.message}');
      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      throw Exception('Unexpected error during login');
    }
  }

  /// Sends a one-time code to [phone] (E.164 format). Requires an SMS
  /// provider to be configured in the Supabase project.
  Future<void> sendPhoneOtp(String phone) async {
    try {
      await supabase.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      debugPrint('PHONE OTP ERROR: ${e.message}');
      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      debugPrint('PHONE OTP ERROR: $e');
      throw Exception('Could not send the verification code');
    }
  }

  /// Verifies a phone OTP, which signs the user in (creating the account on
  /// first use). The profile row is created by the database trigger.
  Future<AuthResponse> verifyPhoneOtp(String phone, String token) async {
    try {
      final response = await supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: token,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('PHONE VERIFY ERROR: ${e.message}');
      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      debugPrint('PHONE VERIFY ERROR: $e');
      throw Exception('Could not verify the code');
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('SIGN OUT ERROR: $e');
    }
  }

  User? get currentUser => supabase.auth.currentUser;

  String _friendlyAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password';
    }
    if (lower.contains('already registered')) {
      return 'An account with this email already exists';
    }
    if (lower.contains('email not confirmed') || lower.contains('email not verified')) {
      return 'Please verify your email before signing in';
    }
    return message;
  }
}
