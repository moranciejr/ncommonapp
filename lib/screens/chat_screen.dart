import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../services/chat_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/stream_config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;
  final _analytics = FirebaseAnalytics.instance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (StreamConfig.apiKey.isEmpty) {
        throw Exception('Stream API key is not configured');
      }

      final client = StreamChatClient(
        StreamConfig.apiKey,
        logLevel: Level.INFO,
      );

      _chatService = ChatService(
        client: client,
        analytics: _analytics,
        supabase: Supabase.instance.client,
      );

      await _chatService.connectUser();
    } catch (e) {
      _analytics.logEvent(
        name: 'chat_initialization_error',
        parameters: {'error': e.toString()},
      );
      setState(() {
        _error = 'Failed to initialize chat: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing chat...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeChat,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamChat(
      client: _chatService.client,
      child: const ChannelListPage(),
    );
  }
}

class ChannelListPage extends StatelessWidget {
  const ChannelListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ChannelsBloc(
        child: ChannelListView(
          filter: Filter.in_('members', [StreamChat.of(context).currentUser!.id]),
          sort: const [SortOption('last_message_at')],
          onChannelTap: (channel, _) => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChannelPage(channel: channel)),
          ),
        ),
      ),
    );
  }
}

class ChannelPage extends StatelessWidget {
  final Channel channel;

  const ChannelPage({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return StreamChannel(
      channel: channel,
      child: Scaffold(
        appBar: const StreamChannelHeader(),
        body: const Column(
          children: [
            Expanded(child: MessageListView()),
            MessageInput(),
          ],
        ),
      ),
    );
  }
} 