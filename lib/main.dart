import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/supabase_test_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'services/email_verification_service.dart';
import 'services/todo_service.dart';
import 'services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'services/chat_service.dart';
import 'screens/stream_test_screen.dart';
import 'screens/chat_inbox_screen.dart';

final supabaseUrl = dotenv.env['SUPABASE_URL'];
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // Loads the .env file
  
  // Initialize SupabaseService
  final supabaseService = SupabaseService();
  await supabaseService.initialize();
  final supabase = supabaseService.client;
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
    ),
  );
  
  // Initialize Firebase Analytics
  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);
  
  // Initialize services
  final authService = AuthService(supabase, analytics);
  final biometricService = BiometricService(analytics);
  final emailVerificationService = EmailVerificationService(supabase, analytics);
  final todoService = TodoService(supabase);
  
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('onboarding_complete') ?? false;
  final profileComplete = prefs.getBool('profile_complete') ?? false;
  
  String startRoute = '/onboarding';
  if (seen) {
    if (supabaseService.isAuthenticated()) {
      startRoute = profileComplete ? '/dashboard' : '/profile';
    } else {
      startRoute = '/login';
    }
  }
  
  final chatService = ChatService();
  chatService.setup(analytics: analytics, supabase: supabase);
  await chatService.initialize(dotenv.env['STREAM_API_KEY'] ?? '');
  
  runApp(MyApp(
    authService: authService,
    biometricService: biometricService,
    emailVerificationService: emailVerificationService,
    todoService: todoService,
    startRoute: startRoute,
    chatService: chatService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final BiometricService biometricService;
  final EmailVerificationService emailVerificationService;
  final TodoService todoService;
  final String startRoute;
  final ChatService chatService;
  
  const MyApp({
    super.key,
    required this.authService,
    required this.biometricService,
    required this.emailVerificationService,
    required this.todoService,
    required this.startRoute,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NCommon App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return StreamChat(
          client: chatService.client,
          child: child!,
        );
      },
      initialRoute: startRoute,
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/dashboard': (context) => DashboardScreen(
          chatService: chatService,
        ),
        '/auth': (context) => const AuthScreen(),
        '/supabase_test': (context) => const SupabaseTestScreen(),
        '/stream_test': (context) => const StreamTestScreen(),
        '/inbox': (context) => ChatInboxScreen(client: ChatService().client),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
