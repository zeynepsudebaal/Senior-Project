import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/chat_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';
import 'services/api_service.dart';
import 'utils/user_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama başlatıldığında token'ı yükle
  final token = await UserData.getToken();
  if (token != null) {
    try {
      // Token varsa kullanıcı bilgilerini güncelle
      await UserData.updateUser({
        'token': token,
        'user': {
          'id': UserData.myUser.id,
          'email': UserData.myUser.email,
          'username': UserData.myUser.name,
        },
      });
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/chat': (context) => const ChatScreen(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ana Sayfa')),
      body: const Center(child: Text('Hoş geldiniz!')),
    );
  }
}
