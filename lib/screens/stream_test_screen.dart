import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class StreamTestScreen extends StatefulWidget {
  const StreamTestScreen({super.key});

  @override
  State<StreamTestScreen> createState() => _StreamTestScreenState();
}

class _StreamTestScreenState extends State<StreamTestScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final StreamChatClient streamClient = StreamChatClient(
    'wa3zput4v9h9', // Replace with your actual Stream API Key
    logLevel: Level.INFO,
  );

  String status = 'Waiting to connect...';

  Future<void> connectToStream() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => status = 'No Supabase user found.');
        return;
      }

      final response = await supabase.functions.invoke(
        'generate-stream-token',
        body: {'user_id': user.id},
      );

      final token = response.data?['token'];
      if (token == null) {
        setState(() => status = 'No token received from function.');
        return;
      }

      setState(() => status = 'Token received. Connecting...');

      await streamClient.connectUser(
        User(id: user.id, extraData: {
          'name': user.email ?? 'nCommon User',
        }),
        token,
      );

      setState(() => status = '✅ Connected as \\${user.id}');
    } catch (e) {
      setState(() => status = '❌ Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    connectToStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stream Chat Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: connectToStream,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
} 