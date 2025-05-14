import 'package:flutter/material.dart';
import '../services/supabase_browser_client.dart';

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

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
    });

    try {
      final client = await SupabaseBrowserClient.getInstance();
      final results = await client.testConnection();
      setState(() {
        _testResults = results;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'status': 'error',
          'message': e.toString(),
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
    });

    try {
      final client = await SupabaseBrowserClient.getInstance();
      final response = await client.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _testResults = {
          'status': 'success',
          'message': 'Signed in successfully',
          'user': response.user?.email,
        };
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'status': 'error',
          'message': e.toString(),
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runTests,
              child: Text(_isLoading ? 'Running Tests...' : 'Run Connection Tests'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: Text(_isLoading ? 'Signing In...' : 'Sign In'),
            ),
            if (_testResults != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${_testResults!['status']}'),
                      Text('Message: ${_testResults!['message']}'),
                      if (_testResults!['user'] != null)
                        Text('User: ${_testResults!['user']}'),
                      if (_testResults!['session'] != null)
                        Text('Session: ${_testResults!['session']}'),
                    ],
                  ),
                ),
              ),
            ],
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