import 'package:supabase_flutter/supabase_flutter.dart';

import 'generated/app_localizations.dart';

/// Localizes known AuthService messages without changing the service contract.
///
/// AuthService currently wraps Supabase exceptions in English exceptions.
/// Unknown technical messages are never displayed verbatim in the UI.
String localizedAuthError(
  Object error,
  AppLocalizations strings, {
  required String fallback,
}) {
  final message = error.toString().toLowerCase();
  final code = error is AuthException ? error.code : null;
  if (code == 'invalid_credentials' ||
      message.contains('incorrect email or password') ||
      message.contains('invalid login credentials')) {
    return strings.authIncorrectCredentials;
  }
  if (code == 'user_already_exists' ||
      code == 'email_exists' ||
      message.contains('an account with this email already exists') ||
      message.contains('already registered')) {
    return strings.authAccountExists;
  }
  if (code == 'email_not_confirmed' ||
      message.contains('please verify your email before signing in') ||
      message.contains('email not confirmed') ||
      message.contains('email not verified')) {
    return strings.authEmailNotConfirmed;
  }
  if (code == 'email_address_invalid' ||
      message.contains('invalid email') ||
      message.contains('email address is invalid')) {
    return strings.authInvalidEmail;
  }
  if (code == 'phone_number_invalid' ||
      message.contains('invalid phone') ||
      message.contains('phone number is invalid')) {
    return strings.authInvalidPhone;
  }
  if (code == 'otp_expired' ||
      message.contains('token has expired or is invalid') ||
      message.contains('otp expired') ||
      message.contains('invalid otp')) {
    return strings.authInvalidCode;
  }
  if (code == 'over_request_rate_limit' ||
      code == 'over_email_send_rate_limit' ||
      code == 'over_sms_send_rate_limit' ||
      message.contains('rate limit') ||
      message.contains('too many requests')) {
    return strings.authRateLimited;
  }
  if (code == 'weak_password' || message.contains('weak password')) {
    return strings.authWeakPassword;
  }
  return fallback;
}
