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
  void initState() {
    super.initState();
    _checkLoginStatus();

    FirebaseMessaging.onMessage.listen((message) {
      _handleNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotification(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotification(message);
      }
    });
  }

  void _handleNotification(RemoteMessage message) {
    if (!mounted) return;

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
              onPressed: () async {
                Navigator.of(context).pop();
                await Future.delayed(Duration(milliseconds: 300));
                await sendResponse(
                    notificationId, 'yes', context); // 
              },
            ),
            TextButton(
              child: Text(noLabel),
              onPressed: () async {
                Navigator.of(context).pop();
                // Hemen bilgi mesajını göster
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text("Ekiplerimiz tarafınıza yönlendirildi. İletişimde kalmak için chat sayfasına gidebilirsiniz."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/chat');
                        },
                        child: Text("Chat'e Git"),
                      ),
                    ],
                  ),
                );
                await Future.delayed(Duration(milliseconds: 300));
                await sendResponse(notificationId, 'no', context);
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> sendResponse(String notificationId, String response, BuildContext context) async {
  final url = Uri.parse('http://192.168.1.40:3000/api/web/earthquake/notification-response');

  try {
    final result = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'notificationId': notificationId, 'response': response}),
    );

    debugPrint('🔁 Status code: ${result.statusCode}');
    debugPrint('🔁 Response body: ${result.body}');

    if (result.statusCode == 200 && response == 'no') {
      final data = jsonDecode(result.body);
      final message = data['message'] ??
          "Ekiplerimiz tarafınıza yönlendirildi. İletişimde kalmak için chat sayfasına gidebilirsiniz.";

      Future.delayed(Duration(milliseconds: 300), () {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/chat');
                },
                child: Text("Chat'e Git"),
              ),
            ],
          ),
        );
      });
    }
  } catch (e) {
    debugPrint("❌ Exception: $e");
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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseMessaging.instance.requestPermission();
        await sendFcmToken(userId);
      }
    }
  }

  Future<void> sendFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final response = await http.post(
          Uri.parse('http://192.168.1.40:3000/api/token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId, 'fcmToken': fcmToken}),
        );
        if (response.statusCode == 200) {
          print('✅ Token gönderildi');
        } else {
          print('❌ Backend hata: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Token gönderim hatası: $e');
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
