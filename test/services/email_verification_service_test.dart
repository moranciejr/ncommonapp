import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ncommonapp/services/email_verification_service.dart';

@GenerateMocks([SupabaseClient, FirebaseAnalytics, User])
void main() {
  late MockSupabaseClient mockSupabase;
  late MockFirebaseAnalytics mockAnalytics;
  late MockUser mockUser;
  late EmailVerificationService emailVerificationService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAnalytics = MockFirebaseAnalytics();
    mockUser = MockUser();
    emailVerificationService = EmailVerificationService(mockSupabase, mockAnalytics);
  });

  group('EmailVerificationService', () {
    test('sendVerificationEmail success', () async {
      when(mockSupabase.auth.resend(
        type: anyNamed('type'),
        email: anyNamed('email'),
      )).thenAnswer((_) async => {});

      await emailVerificationService.sendVerificationEmail('test@example.com');

      verify(mockAnalytics.logEvent(
        name: 'verification_email_sent',
        parameters: {'email': 'test@example.com'},
      )).called(1);
    });

    test('sendVerificationEmail failure', () async {
      when(mockSupabase.auth.resend(
        type: anyNamed('type'),
        email: anyNamed('email'),
      )).thenThrow(AuthException('Failed to send verification email'));

      expect(
        () => emailVerificationService.sendVerificationEmail('test@example.com'),
        throwsA(isA<AuthException>()),
      );

      verify(mockAnalytics.logEvent(
        name: 'verification_email_sent',
        parameters: {'email': 'test@example.com'},
      )).called(1);

      verify(mockAnalytics.logEvent(
        name: 'verification_email_failed',
        parameters: {
          'email': 'test@example.com',
          'error': 'Failed to send verification email',
        },
      )).called(1);
    });

    test('isEmailVerified returns true when verified', () async {
      when(mockSupabase.auth.currentUser).thenReturn(mockUser);
      when(mockUser.emailConfirmedAt).thenReturn(DateTime.now());

      final result = await emailVerificationService.isEmailVerified();
      expect(result, true);

      verify(mockAnalytics.logEvent(
        name: 'email_verification_check',
        parameters: {'email': mockUser.email},
      )).called(1);
    });

    test('isEmailVerified returns false when not verified', () async {
      when(mockSupabase.auth.currentUser).thenReturn(mockUser);
      when(mockUser.emailConfirmedAt).thenReturn(null);

      final result = await emailVerificationService.isEmailVerified();
      expect(result, false);

      verify(mockAnalytics.logEvent(
        name: 'email_verification_check',
        parameters: {'email': mockUser.email},
      )).called(1);
    });

    test('refreshSession success', () async {
      when(mockSupabase.auth.refreshSession())
          .thenAnswer((_) async => {});

      await emailVerificationService.refreshSession();

      verify(mockAnalytics.logEvent(
        name: 'session_refreshed',
      )).called(1);
    });

    test('refreshSession failure', () async {
      when(mockSupabase.auth.refreshSession())
          .thenThrow(AuthException('Failed to refresh session'));

      expect(
        () => emailVerificationService.refreshSession(),
        throwsA(isA<AuthException>()),
      );

      verify(mockAnalytics.logEvent(
        name: 'session_refresh_failed',
        parameters: {'error': 'AuthException: Failed to refresh session'},
      )).called(1);
    });
  });
} 