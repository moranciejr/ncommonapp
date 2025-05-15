import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatInboxScreen extends StatelessWidget {
  final StreamChatClient client;

  const ChatInboxScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ChannelsBloc(
        child: ChannelListView(
          filter: Filter.in_('members', [client.state.currentUser!.id]),
          sort: [SortOption('last_message_at')],
          pagination: const PaginationParams(limit: 20),
          channelWidget: const ChannelPage(),
        ),
      ),
    );
  }
}

class ChannelPage extends StatelessWidget {
  const ChannelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;

    return StreamChannel(
      channel: channel,
      child: Scaffold(
        appBar: const StreamChannelHeader(),
        body: Column(
          children: const [
            Expanded(child: MessageListView()),
            MessageInput(),
          ],
        ),
      ),
    );
  }
} 