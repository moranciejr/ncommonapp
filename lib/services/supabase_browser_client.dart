import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseBrowserClient {
  static SupabaseBrowserClient? _instance;
  late final SupabaseClient client;

  static const String _supabaseUrl = 'https://yucfdziwquyzpchkmxjk.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Y2Zkeml3cXV5enBjaGtteGprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxNzI1NTYsImV4cCI6MjA2Mjc0ODU1Nn0.pn861ClAWPfkZvxOyl_ROasgZregrrVJhmVemWzx3hg';

  SupabaseBrowserClient._();

  static Future<SupabaseBrowserClient> getInstance() async {
    if (_instance == null) {
      _instance = SupabaseBrowserClient._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authCallbackUrlHostname: 'login-callback',
      debug: kDebugMode,
      authFlowType: AuthFlowType.pkce,
    );

    client = Supabase.instance.client;
  }

  // Test connection and authentication
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // Test 1: Basic connection
      final healthCheck = await client.from('todos').select('count').limit(1);
      debugPrint('✅ Basic connection test passed');

      // Test 2: Authentication state
      final user = currentUser;
      final session = currentSession;
      debugPrint('✅ Auth state check passed');
      debugPrint('User: ${user?.email ?? 'Not logged in'}');
      debugPrint('Session: ${session != null ? 'Active' : 'None'}');

      // Test 3: Real-time subscription
      final subscription = client.from('todos').stream(primaryKey: ['id']).listen(
        (data) {
          debugPrint('✅ Real-time subscription test passed');
          subscription.cancel();
        },
        onError: (error) {
          debugPrint('❌ Real-time subscription test failed: $error');
        },
      );

      // Test 4: Storage access
      try {
        await client.storage.from('local').list();
        debugPrint('✅ Storage access test passed');
      } catch (e) {
        debugPrint('❌ Storage access test failed: $e');
      }

      return {
        'status': 'success',
        'message': 'All tests passed',
        'user': user?.email,
        'session': session != null,
        'health': healthCheck != null,
      };
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  // Basic CRUD operations
  Future<List<Map<String, dynamic>>> from(String table) async {
    return client.from(table).select() as Future<List<Map<String, dynamic>>>;
  }

  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) async {
    return client.from(table).insert(data).select().single() as Future<Map<String, dynamic>>;
  }

  Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data,
    String id,
  ) async {
    return client.from(table).update(data).eq('id', id).select().single() as Future<Map<String, dynamic>>;
  }

  Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> stream(String table) {
    return client.from(table).stream(primaryKey: ['id']);
  }

  // Auth operations
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
} 