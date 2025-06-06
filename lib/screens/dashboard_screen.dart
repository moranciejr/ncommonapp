import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/chat_service.dart';
import 'todo_screen.dart';
import '../services/supabase_service.dart';
import '../services/todo_service.dart';

class DashboardScreen extends StatefulWidget {
  final ChatService chatService;
  
  const DashboardScreen({
    super.key,
    required this.chatService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _analytics = FirebaseAnalytics.instance;
  late final supabase = SupabaseService().client;
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    setState(() => _isLoading = true);
    try {
      // _supabase = await SupabaseBrowserClient.getInstance();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _analytics.logEvent(
      name: 'dashboard_tab_changed',
      parameters: {'tab_index': index},
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await widget.chatService.disconnectUser();
      // await _supabase.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NCommon App'),
        bottom: TabBar(
          controller: _tabController,
          onTap: _onTabChanged,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.check_circle), text: 'Tasks'),
            Tab(icon: Icon(Icons.people), text: 'Social'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.pushNamed(context, '/chat');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test Stream Chat',
            onPressed: () {
              Navigator.pushNamed(context, '/stream_test');
            },
          ),
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Inbox',
            onPressed: () {
              Navigator.pushNamed(context, '/inbox');
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Home Tab
          const Center(
            child: Text('Welcome to NCommon App!'),
          ),
          
          // Tasks Tab
          TodoScreen(todoService: TodoService(supabase)),
          
          // Social Tab
          // const ChatScreen(),
          
          // Profile Tab
          FutureBuilder(
            future: supabase.from('users').select().maybeSingle(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
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
                        'Error loading profile: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Retry loading
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final userData = snapshot.data as Map<String, dynamic>;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userData['profile_picture_url'] != null)
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(userData['profile_picture_url']),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Name: ${userData['full_name']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mood: ${userData['mood'] ?? 'Not set'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Interests:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FutureBuilder(
                      future: supabase.from('user_interests')
                          .select('interest_id')
                          .eq('user_id', supabase.auth.currentUser?.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        final interestIds = (snapshot.data as List)
                            .map((i) => i['interest_id'] as int)
                            .toList();
                            
                        return FutureBuilder(
                          future: supabase.from('interests')
                              .select()
                              .inFilter('id', interestIds),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            
                            final interests = (snapshot.data as List)
                                .map((i) => i['name'] as String)
                                .toList();
                                
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: interests
                                  .map((i) => Chip(
                                    label: Text(i),
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ))
                                  .toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // Add new todo
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 