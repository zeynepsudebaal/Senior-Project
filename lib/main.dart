import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:senior_project/pages/login_page.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/profile_page.dart';
import 'package:senior_project/services/auth_service.dart';
import 'package:senior_project/pages/messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

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
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      _handleNotification(message);
    });

    // App background -> from tray tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotification(message);
    });

    // App terminated -> cold start
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotification(message);
      }
    });
  }

  void _handleNotification(RemoteMessage message) {
    final data = message.data;
    final question = data['question'];
    final notificationId = data['notificationId'];
    final yesLabel = data['yesLabel'] ?? 'Evet';
    final noLabel = data['noLabel'] ?? 'Hayır';

    if (question != null && notificationId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Text(question),
          actions: [
            TextButton(
              child: Text(yesLabel),
              onPressed: () {
                sendResponse(notificationId, 'yes');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(noLabel),
              onPressed: () {
                sendResponse(notificationId, 'no');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
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

    if (isLoggedIn) {
      // 🔐 Firebase Auth'tan kullanıcı UID'sini al
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        // 🔔 Android 13 için bildirim izni al
        await FirebaseMessaging.instance.requestPermission();

        // 🚀 Token'ı backend'e gönder
        await sendFcmToken(userId);
      }
    }
  }

  Future<void> sendFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final response = await http.post(
          Uri.parse(
              'http://192.168.1.40:3000/api/token'), // IP'ni kendine göre değiştir
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'fcmToken': fcmToken,
          }),
        );

        if (response.statusCode == 200) {
          print('✅ FCM token başarıyla backend\'e gönderildi');
        } else {
          print('❌ Backend hata: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Token gönderilirken hata oluştu: $e');
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
