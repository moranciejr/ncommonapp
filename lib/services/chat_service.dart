import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/platform_config.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  late final stream.StreamChatClient _client;
  late final SupabaseClient _supabase;
  bool _isInitialized = false;
  late FirebaseAnalytics _analytics;

  Future<void> setup(FirebaseAnalytics analytics) async {
    if (_isInitialized) return;

    _analytics = analytics;
    _supabase = Supabase.instance.client;
    _client = stream.StreamChatClient(
      PlatformConfig.platformConfig['streamApiKey'] as String,
      logLevel: stream.Level.INFO,
    );
    _isInitialized = true;
  }

  Future<String> getStreamToken(String userId) async {
    if (!_isInitialized) await setup(_analytics);

    try {
      final response = await _supabase.functions.invoke(
        'generate-stream-token',
        body: {'userId': userId},
      );

      if (response.status != 200) {
        throw Exception('Failed to generate Stream token: ${response.data}');
      }

      return response.data['token'] as String;
    } catch (e) {
      throw Exception('Error generating Stream token: $e');
    }
  }

  Future<void> connectUser(String userId, String username) async {
    if (!_isInitialized) await setup(_analytics);

    try {
      final token = await getStreamToken(userId);
      await _client.connectUser(
        stream.User(id: userId, extraData: {'name': username}),
        token,
      );

      _analytics.logEvent(
        name: 'chat_user_connected',
        parameters: {'user_id': userId} as Map<String, Object>,
      );
    } catch (e) {
      _analytics.logEvent(
        name: 'chat_connection_error',
        parameters: {'error': e.toString()} as Map<String, Object>,
      );
      debugPrint('Error connecting user: $e');
      rethrow;
    }
  }

  Future<void> connectCurrentUser() async {
    try {
      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser == null) {
        throw Exception('No authenticated user found');
      }

      final response = await _supabase.functions.invoke(
        'generate-stream-token',
        body: {'user_id': supabaseUser.id},
      );
      final token = response.data['token'];

      await connectUser(supabaseUser.id, supabaseUser.email ?? supabaseUser.id);
    } catch (e) {
      _analytics.logEvent(
        name: 'chat_connection_error',
        parameters: {'error': e.toString()} as Map<String, Object>,
      );
      debugPrint('Error connecting current user: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (!_isInitialized) return;
    await _client.disconnectUser();
  }

  Future<stream.Channel> createChannel({
    required String channelId,
    required String channelType,
    required List<String> memberIds,
    String? name,
    String? image,
  }) async {
    try {
      final channel = _client.channel(
        channelType,
        id: channelId,
        extraData: {
          if (name != null) 'name': name,
          if (image != null) 'image': image,
          'members': memberIds,
        },
      );

      await channel.watch();
      _analytics.logEvent(
        name: 'chat_channel_created',
        parameters: {'channel_id': channelId} as Map<String, Object>,
      );
      return channel;
    } catch (e) {
      _analytics.logEvent(
        name: 'chat_channel_error',
        parameters: {'error': e.toString()} as Map<String, Object>,
      );
      debugPrint('Error creating channel: $e');
      rethrow;
    }
  }

  Stream<List<stream.Channel>> getChannels() {
    try {
      return _client.queryChannels(
        filter: stream.Filter.in_('members', [_client.state.currentUser?.id ?? '']),
      ).map((channels) => channels.toList());
    } catch (e) {
      _analytics.logEvent(
        name: 'chat_query_error',
        parameters: {'error': e.toString()} as Map<String, Object>,
      );
      debugPrint('Error getting channels: $e');
      rethrow;
    }
  }

  stream.StreamChatClient get client {
    if (!_isInitialized) {
      throw Exception('ChatService not initialized. Call setup() first.');
    }
    return _client;
  }
} 