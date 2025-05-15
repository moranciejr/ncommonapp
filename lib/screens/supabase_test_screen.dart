import 'package:flutter/material.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;

  // Placeholder for removed SupabaseBrowserClient logic
  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = {'status': 'info', 'message': 'SupabaseBrowserClient removed.'};
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _testResults = {'status': 'info', 'message': 'SupabaseBrowserClient removed.'};
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Test Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              child: const Text('Run Supabase Tests'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: const Text('Sign In (Test)'),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (_testResults != null)
              Text(_testResults!['message'] ?? '', style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 