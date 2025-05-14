import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class ChatService {
  final StreamChatClient client;
  final FirebaseAnalytics analytics;
  final SupabaseClient supabase;

  ChatService({
    required this.client,
    required this.analytics,
    required this.supabase,
  });

  Future<void> connectUser() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      final response = await supabase.functions.invoke(
        'generate-stream-token',
        body: {'user_id': userId},
      );
      final token = response.data['token'];

      await client.connectUser(
        User(id: userId),
        token,
      );

      analytics.logEvent(
        name: 'chat_user_connected',
        parameters: {'user_id': userId},
      );
    } catch (e) {
      analytics.logEvent(
        name: 'chat_connection_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<List<Channel>> getUserChannels() async {
    try {
      final channels = await client.queryChannels(
        filter: Filter.in_('members', [client.state.currentUser!.id]),
        sort: const [SortOption('last_message_at')],
      );
      return channels;
    } catch (e) {
      analytics.logEvent(
        name: 'chat_query_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<Channel> createChannel({
    required String channelId,
    String? name,
    List<String>? members,
  }) async {
    try {
      final channel = client.channel(
        'messaging',
        id: channelId,
        extraData: {
          'name': name ?? 'New Channel',
          'members': members ?? [client.state.currentUser!.id],
        },
      );

      await channel.create();
      
      analytics.logEvent(
        name: 'chat_channel_created',
        parameters: {'channel_id': channelId},
      );

      return channel;
    } catch (e) {
      analytics.logEvent(
        name: 'chat_channel_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }
} 