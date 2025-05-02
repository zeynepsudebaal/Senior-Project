import 'package:flutter/material.dart';
import 'package:senior_project/pages/login_page.dart';
import 'package:senior_project/pages/chat_page.dart'; // chat_page yerine chat_screen olması gerekiyor
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Başlangıç route'u belirtiyoruz
      routes: {
        '/': (context) => LoginPage(),         // İlk açılan sayfa login
        '/dashboard': (context) => DashboardPage(),
        '/chat': (context) => ChatScreen(),     // ChatScreen yönlendirmesi
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
