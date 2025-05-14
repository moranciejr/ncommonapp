import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class StreamTokenService {
  static final StreamTokenService _instance = StreamTokenService._internal();
  factory StreamTokenService() => _instance;
  StreamTokenService._internal();

  final _supabase = Supabase.instance.client;
  final _analytics = FirebaseAnalytics.instance;

  Future<String> generateToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'generate-stream-token',
        body: {'user_id': userId},
      );

      if (response.status != 200) {
        throw Exception('Failed to generate token: ${response.data['error']}');
      }

      final token = response.data['token'] as String;
      _analytics.logEvent(
        name: 'stream_token_generated',
        parameters: {'user_id': userId},
      );

      return token;
    } catch (e) {
      _analytics.logEvent(
        name: 'stream_token_generation_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }
} 