import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ncommonapp/services/biometric_service.dart';

@GenerateMocks([LocalAuthentication, FlutterSecureStorage, FirebaseAnalytics])
void main() {
  late MockLocalAuthentication mockLocalAuth;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockFirebaseAnalytics mockAnalytics;
  late BiometricService biometricService;

  setUp(() {
    mockLocalAuth = MockLocalAuthentication();
    mockSecureStorage = MockFlutterSecureStorage();
    mockAnalytics = MockFirebaseAnalytics();
    biometricService = BiometricService(mockAnalytics);
  });

  group('BiometricService', () {
    test('isBiometricsAvailable returns true when available', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);

      final result = await biometricService.isBiometricsAvailable();
      expect(result, true);
    });

    test('isBiometricsAvailable returns false when not available', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

      final result = await biometricService.isBiometricsAvailable();
      expect(result, false);
    });

    test('authenticate success', () async {
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);

      final result = await biometricService.authenticate();
      expect(result, true);

      verify(mockAnalytics.logEvent(
        name: 'biometric_auth_attempt',
      )).called(1);

      verify(mockAnalytics.logEvent(
        name: 'biometric_auth_success',
      )).called(1);
    });

    test('authenticate failure', () async {
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => false);

      final result = await biometricService.authenticate();
      expect(result, false);

      verify(mockAnalytics.logEvent(
        name: 'biometric_auth_attempt',
      )).called(1);

      verify(mockAnalytics.logEvent(
        name: 'biometric_auth_failure',
        parameters: {'reason': 'user_cancelled'},
      )).called(1);
    });

    test('saveCredentials stores email and password', () async {
      await biometricService.saveCredentials('test@example.com', 'password123');

      verify(mockSecureStorage.write(
        key: 'email',
        value: 'test@example.com',
      )).called(1);

      verify(mockSecureStorage.write(
        key: 'password',
        value: 'password123',
      )).called(1);
    });

    test('getCredentials retrieves stored credentials', () async {
      when(mockSecureStorage.read(key: 'email'))
          .thenAnswer((_) async => 'test@example.com');
      when(mockSecureStorage.read(key: 'password'))
          .thenAnswer((_) async => 'password123');

      final credentials = await biometricService.getCredentials();
      expect(credentials['email'], 'test@example.com');
      expect(credentials['password'], 'password123');
    });

    test('clearCredentials removes stored credentials', () async {
      await biometricService.clearCredentials();

      verify(mockSecureStorage.delete(key: 'email')).called(1);
      verify(mockSecureStorage.delete(key: 'password')).called(1);
    });
  });
} 