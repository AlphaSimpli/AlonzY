import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // SIGN UP (create account)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      debugPrint("🔵 SUPABASE SIGNUP START");
      debugPrint("Email: $email");

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      debugPrint("🟢 SIGNUP SUCCESS");
      debugPrint("User: ${response.user?.email}");
      debugPrint("Session: ${response.session}");

      // Profile is automatically created by database trigger (on_auth_user_created)
      // Optional: Update profile with additional info
      if (response.user != null && (firstName != null || lastName != null)) {
        await supabase.from('profiles').update({
          'first_name': ?firstName,
          'last_name': ?lastName,
        }).eq('id', response.user!.id);

        debugPrint("✅ User profile updated with additional info");
      } else {
        debugPrint("✅ User profile auto-created by trigger");
      }

      return response;
    } on AuthException catch (e) {
      debugPrint("🔴 SUPABASE AUTH ERROR (SIGNUP)");
      debugPrint("Message: ${e.message}");
      debugPrint("Status: ${e.statusCode}");

      throw Exception("Signup failed: ${e.message}");
    } catch (e) {
      debugPrint("🔴 UNKNOWN ERROR (SIGNUP)");
      debugPrint(e.toString());

      throw Exception("Unexpected error during signup");
    }
  }

  // SIGN IN (login)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("🔵 SUPABASE LOGIN START");
      debugPrint("Email: $email");

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint("🟢 LOGIN SUCCESS");
      debugPrint("User: ${response.user?.email}");
      debugPrint("Session: ${response.session}");

      return response;
    } on AuthException catch (e) {
      debugPrint("🔴 SUPABASE AUTH ERROR (LOGIN)");
      debugPrint("Message: ${e.message}");
      debugPrint("Status: ${e.statusCode}");

      throw Exception("Login failed: ${e.message}");
    } catch (e) {
      debugPrint("🔴 UNKNOWN ERROR (LOGIN)");
      debugPrint(e.toString());

      throw Exception("Unexpected error during login");
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      debugPrint("🔵 SIGNING OUT");
      await supabase.auth.signOut();
      debugPrint("🟢 SIGN OUT SUCCESS");
    } catch (e) {
      debugPrint("🔴 SIGN OUT ERROR");
      debugPrint(e.toString());
    }
  }

  // CURRENT USER
  User? get currentUser => supabase.auth.currentUser;
}