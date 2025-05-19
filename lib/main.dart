import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:senior_project/pages/login_page.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/profile_page.dart';
import 'package:senior_project/services/auth_service.dart';
import 'firebase_options.dart';
import 'package:senior_project/services/notification_service.dart';
import 'package:senior_project/pages/notifications_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService(navigatorKey: navigatorKey);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // <-- EKLE BUNU
      home: AuthWrapper(authService: _authService),
      routes: {
        '/dashboard': (context) => DashboardPage(),
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfilePage(),
        '/notifications': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          return NotificationPage(notificationData: args);
        },
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final AuthService authService;

  const AuthWrapper({Key? key, required this.authService}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await widget.authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn ? ProfilePage() : LoginPage();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM servisini başlat
  FCMService fcmService = FCMService(navigatorKey: navigatorKey);
  await fcmService.initialize();

  // Burada istersen tokeni backend'e gönderebilirsin
  if (fcmService.fcmToken != null) {
    print("FCM Token: ${fcmService.fcmToken}");
    await fcmService.sendTokenToBackend(fcmService.fcmToken!);
  }

  runApp(MyApp());
}
