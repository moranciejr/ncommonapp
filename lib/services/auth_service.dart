import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../constants/auth_constants.dart';

class AuthService {
  final SupabaseClient _supabase;
  final FirebaseAnalytics _analytics;

  AuthService(this._supabase, this._analytics);

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await _analytics.logLogin(loginMethod: 'email');
      return response;
    } on AuthException catch (e) {
      await _analytics.logEvent(
        name: 'login_error',
        parameters: {
          'error_code': e.message,
          'method': 'email',
        },
      );
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      await _analytics.logSignUp(signUpMethod: 'email');
      return response;
    } on AuthException catch (e) {
      await _analytics.logEvent(
        name: 'signup_error',
        parameters: {
          'error_code': e.message,
          'method': 'email',
        },
      );
      rethrow;
    }
  }

  Future<AuthResponse> signInWithSocial(String provider) async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        provider: Provider.values.firstWhere(
          (p) => p.name.toLowerCase() == provider.toLowerCase(),
        ),
        redirectTo: 'https://your-project-id.supabase.co/auth/v1/callback',
      );

      await _analytics.logLogin(loginMethod: provider);
      return response;
    } on AuthException catch (e) {
      await _analytics.logEvent(
        name: 'login_error',
        parameters: {
          'error_code': e.message,
          'method': provider,
        },
      );
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      await _analytics.logEvent(
        name: 'password_reset_requested',
        parameters: {'email': email},
      );
    } on AuthException catch (e) {
      await _analytics.logEvent(
        name: 'password_reset_error',
        parameters: {
          'error_code': e.message,
          'email': email,
        },
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _analytics.logEvent(name: 'logout');
    } on AuthException catch (e) {
      await _analytics.logEvent(
        name: 'logout_error',
        parameters: {'error_code': e.message},
      );
      rethrow;
    }
  }

  String? validatePassword(String password) {
    if (password.length < AuthConstants.minPasswordLength) {
      return 'Password must be at least ${AuthConstants.minPasswordLength} characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String getErrorMessage(String? errorCode) {
    if (errorCode == null) {
      return AuthConstants.errorMessages['unknown_error']!;
    }

    final errorKey = errorCode.toLowerCase().replaceAll('-', '_');
    return AuthConstants.errorMessages[errorKey] ?? 
           AuthConstants.errorMessages['unknown_error']!;
  }
} 