import 'package:flutter/material.dart';
import 'package:senior_project/pages/login_page.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        '/dashboard': (context) => DashboardPage(),
        '/chat': (context) => ChatScreen(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
