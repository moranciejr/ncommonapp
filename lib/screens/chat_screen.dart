import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;

    return Scaffold(
      appBar: StreamChannelHeader(channel: channel),
      body: Column(
        children: [
          Expanded(child: MessageListView(channel: channel)),
          MessageInput(channel: channel),
        ],
      ),
    );
  }
} 