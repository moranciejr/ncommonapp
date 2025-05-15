import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient client;
  late final SharedPreferences _prefs;

  static const String _supabaseUrl = 'https://yucfdziwquyzpchkmxjk.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1Y2Zkeml3cXV5enBjaGtteGprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcxNzI1NTYsImV4cCI6MjA2Mjc0ODU1Nn0.pn861ClAWPfkZvxOyl_ROasgZregrrVJhmVemWzx3hg';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      debug: true,
    );

    client = Supabase.instance.client;

    // Listen to auth state changes
    client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          _handleSignedIn(session);
          break;
        case AuthChangeEvent.signedOut:
          _handleSignedOut();
          break;
        case AuthChangeEvent.tokenRefreshed:
          _handleTokenRefreshed(session);
          break;
        default:
          break;
      }
    });
  }

  Future<void> _handleSignedIn(Session? session) async {
    if (session != null) {
      await _prefs.setString('supabase_auth_token', session.accessToken);
      await _prefs.setString('supabase_refresh_token', session.refreshToken ?? '');
    }
  }

  Future<void> _handleSignedOut() async {
    await _prefs.remove('supabase_auth_token');
    await _prefs.remove('supabase_refresh_token');
  }

  Future<void> _handleTokenRefreshed(Session? session) async {
    if (session != null) {
      await _prefs.setString('supabase_auth_token', session.accessToken);
      await _prefs.setString('supabase_refresh_token', session.refreshToken ?? '');
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    await _handleSignedOut();
  }

  Future<Session?> getCurrentSession() async {
    return client.auth.currentSession;
  }

  Future<User?> getCurrentUser() async {
    return client.auth.currentUser;
  }

  bool isAuthenticated() {
    return client.auth.currentSession != null;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      Provider.google,
      redirectTo: 'io.supabase.ncommonapp://login-callback/',
    );
  }

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
} 