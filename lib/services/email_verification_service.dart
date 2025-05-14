import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailVerificationService {
  final SupabaseClient _supabase;
  final FirebaseAnalytics _analytics;

  EmailVerificationService(this._supabase, this._analytics);

  Future<void> sendVerificationEmail(String email) async {
    try {
      await _analytics.logEvent(
        name: 'verification_email_sent',
        parameters: {'email': email},
      );

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } on AuthException catch (e) {
      await _analytics.logEvent(
        name: 'verification_email_error',
        parameters: {
          'email': email,
          'error_code': e.message,
        },
      );
      rethrow;
    }
  }

  Future<bool> isEmailVerified() async {
    try {
      await _analytics.logEvent(name: 'verification_check_attempt');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _analytics.logEvent(
          name: 'verification_check_error',
          parameters: {'error': 'no_user'},
        );
        return false;
      }

      final isVerified = user.emailConfirmedAt != null;
      await _analytics.logEvent(
        name: 'verification_check_result',
        parameters: {'is_verified': isVerified},
      );

      return isVerified;
    } catch (e) {
      await _analytics.logEvent(
        name: 'verification_check_error',
        parameters: {'error': e.toString()},
      );
      return false;
    }
  }

  Future<void> openEmailApp() async {
    try {
      final url = Uri.parse('mailto:');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        await _analytics.logEvent(
          name: 'email_app_opened',
        );
      } else {
        throw 'Could not launch email app';
      }
    } catch (e) {
      await _analytics.logEvent(
        name: 'email_app_open_failed',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<void> refreshSession() async {
    try {
      await _analytics.logEvent(name: 'session_refresh_attempt');

      await _supabase.auth.refreshSession();

      await _analytics.logEvent(name: 'session_refresh_success');
    } on AuthException catch (e) {
      await _analytics.logEvent(
        name: 'session_refresh_error',
        parameters: {'error_code': e.message},
      );
      rethrow;
    }
  }
} 