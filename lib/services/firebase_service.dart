import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final FirebaseAnalytics analytics;

  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
      ),
    );
    analytics = FirebaseAnalytics.instance;
  }

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  Future<void> setUserProperties({
    required String userId,
    required String userRole,
  }) async {
    await analytics.setUserId(id: userId);
    await analytics.setUserProperty(name: 'user_role', value: userRole);
  }
} 