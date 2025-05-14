import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ncommonapp/services/auth_service.dart';

@GenerateMocks([SupabaseClient, FirebaseAnalytics])
void main() {
  late MockSupabaseClient mockSupabase;
  late MockFirebaseAnalytics mockAnalytics;
  late AuthService authService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAnalytics = MockFirebaseAnalytics();
    authService = AuthService(mockSupabase, mockAnalytics);
  });

  group('AuthService', () {
    test('signInWithEmail success', () async {
      when(mockSupabase.auth.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => AuthResponse());

      await authService.signInWithEmail('test@example.com', 'password123');

      verify(mockAnalytics.logEvent(
        name: 'login_attempt',
        parameters: {'email': 'test@example.com'},
      )).called(1);

      verify(mockAnalytics.logEvent(
        name: 'login_success',
        parameters: {'email': 'test@example.com'},
      )).called(1);
    });

    test('signInWithEmail failure', () async {
      when(mockSupabase.auth.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(AuthException('Invalid login credentials'));

      expect(
        () => authService.signInWithEmail('test@example.com', 'wrongpassword'),
        throwsA(isA<AuthException>()),
      );

      verify(mockAnalytics.logEvent(
        name: 'login_attempt',
        parameters: {'email': 'test@example.com'},
      )).called(1);

      verify(mockAnalytics.logEvent(
        name: 'login_failure',
        parameters: {
          'email': 'test@example.com',
          'error_code': 'Invalid login credentials',
        },
      )).called(1);
    });

    test('validatePassword success', () {
      expect(
        authService.validatePassword('StrongP@ss123'),
        null,
      );
    });

    test('validatePassword too short', () {
      expect(
        authService.validatePassword('weak'),
        'Password must be at least 8 characters',
      );
    });

    test('validatePassword missing requirements', () {
      expect(
        authService.validatePassword('weakpassword'),
        'Password must contain at least one letter, one number, and one special character',
      );
    });
  });
} 