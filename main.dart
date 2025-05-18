import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:senior_project/pages/login_page.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/profile_page.dart';
import 'package:senior_project/services/auth_service.dart';
import 'firebase_options.dart';

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(authService: _authService),
      routes: {
        '/dashboard': (context) => DashboardPage(),
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfilePage(),
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
    _initializeFCM();
    _checkLoginStatus();
  }

  Future<void> _initializeFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Kullanıcıdan bildirim izni iste
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');

      // FCM token al
      String? token = await messaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        // Token'ı local storage'a kaydet
        await widget.authService.saveFcmToken(token);
        // Token'ı backend'e gönder
        await widget.authService.sendFcmTokenToBackend(token);
      }

      // Uygulama ön plandayken gelen mesajları dinle
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.messageId}');
      });
    } else {
      print('User declined or has not accepted permission');
    }
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
  runApp(MyApp());
}
