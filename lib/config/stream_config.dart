import 'package:flutter_dotenv/flutter_dotenv.dart';

class StreamConfig {
  static String get apiKey {
    const envKey = String.fromEnvironment('STREAM_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    
    final dotenvKey = dotenv.env['STREAM_API_KEY'];
    if (dotenvKey == null || dotenvKey.isEmpty) {
      throw Exception('Stream API key not found. Please set STREAM_API_KEY in .env file or as a build argument.');
    }
    return dotenvKey;
  }
  
  // This should only be used in your Supabase Edge Function
  static String get secretKey {
    const envKey = String.fromEnvironment('STREAM_SECRET_KEY');
    if (envKey.isNotEmpty) return envKey;
    
    final dotenvKey = dotenv.env['STREAM_SECRET_KEY'];
    if (dotenvKey == null || dotenvKey.isEmpty) {
      throw Exception('Stream secret key not found. Please set STREAM_SECRET_KEY in .env file or as a build argument.');
    }
    return dotenvKey;
  }
} 