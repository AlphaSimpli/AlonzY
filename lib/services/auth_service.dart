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
      print("🔵 SUPABASE SIGNUP START");
      print("Email: $email");

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      print("🟢 SIGNUP SUCCESS");
      print("User: ${response.user?.email}");
      print("Session: ${response.session}");

      // Profile is automatically created by database trigger (on_auth_user_created)
      // Optional: Update profile with additional info
      if (response.user != null && (firstName != null || lastName != null)) {
        await supabase.from('profiles').update({
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        }).eq('id', response.user!.id);

        print("✅ User profile updated with additional info");
      } else {
        print("✅ User profile auto-created by trigger");
      }

      return response;
    } on AuthException catch (e) {
      print("🔴 SUPABASE AUTH ERROR (SIGNUP)");
      print("Message: ${e.message}");
      print("Status: ${e.statusCode}");

      throw Exception("Signup failed: ${e.message}");
    } catch (e) {
      print("🔴 UNKNOWN ERROR (SIGNUP)");
      print(e);

      throw Exception("Unexpected error during signup");
    }
  }

  // SIGN IN (login)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print("🔵 SUPABASE LOGIN START");
      print("Email: $email");

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print("🟢 LOGIN SUCCESS");
      print("User: ${response.user?.email}");
      print("Session: ${response.session}");

      return response;
    } on AuthException catch (e) {
      print("🔴 SUPABASE AUTH ERROR (LOGIN)");
      print("Message: ${e.message}");
      print("Status: ${e.statusCode}");

      throw Exception("Login failed: ${e.message}");
    } catch (e) {
      print("🔴 UNKNOWN ERROR (LOGIN)");
      print(e);

      throw Exception("Unexpected error during login");
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    try {
      print("🔵 SIGNING OUT");
      await supabase.auth.signOut();
      print("🟢 SIGN OUT SUCCESS");
    } catch (e) {
      print("🔴 SIGN OUT ERROR");
      print(e);
    }
  }

  // CURRENT USER
  User? get currentUser => supabase.auth.currentUser;
}