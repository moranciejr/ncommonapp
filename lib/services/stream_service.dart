import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StreamService {
  static final StreamService _instance = StreamService._internal();
  factory StreamService() => _instance;
  StreamService._internal();

  late final StreamChatClient client;

  Future<void> initialize() async {
    client = StreamChatClient(
      dotenv.env['STREAM_API_KEY'] ?? '',
      logLevel: Level.INFO,
    );
  }

  Future<void> connectUser({
    required String userId,
    required String userToken,
    Map<String, dynamic>? extraData,
  }) async {
    await client.connectUser(
      User(
        id: userId,
        extraData: extraData ?? {},
      ),
      userToken,
    );
  }

  Future<void> disconnectUser() async {
    await client.disconnectUser();
  }

  Future<Channel> createChannel({
    required String channelId,
    required String channelType,
    required List<String> members,
    Map<String, dynamic>? extraData,
  }) async {
    final channel = client.channel(
      channelType,
      id: channelId,
      extraData: extraData ?? {},
    );
    await channel.create();
    await channel.addMembers(members);
    return channel;
  }

  Stream<List<Channel>> getChannels() {
    return client.queryChannels(
      filter: Filter.inFilter('members', [client.state.currentUser?.id ?? '']),
      sort: [SortOption('last_message_at')],
    );
  }
} 