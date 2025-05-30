import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'register_page.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';
import '../models/user_data.dart';
import '../models/user.dart' as my_model;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response['success'] == true) {
        try {
          // ✅ Firebase giriş
          await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          print('Firebase login successful');

          // ✅ FCM Token'ı gönder
          final userId = fb_auth.FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            await sendFcmToken(userId);
          }

        } catch (e) {
          print('Firebase login failed: $e');
        }

        if (!mounted) return;
        UserData.myUser = my_model.User(
          imagePath: 'https://via.placeholder.com/150',
          name: response['user']['name'] ?? 'No Name',
          surname: response['user']['surname'] ?? 'No Surname',
          email: response['user']['email'] ?? 'No Email',
          phone: response['user']['phoneNumber'] ?? 'No Phone',
          address: response['user']['address'] ?? 'No Address',
          isDarkMode: false,
          relatives: [],
        );

        await Future.delayed(Duration(milliseconds: 300));
        final token = await _authService.getToken();

        if (token == null) {
          setState(() {
            _errorMessage = 'Authentication failed. Please try again.';
            _isLoading = false;
          });
          return;
        }

        final profileResponse = await _authService.getUserProfile();
        if (profileResponse['success'] == true) {
          try {
            final relativesResponse = await _authService.getRelatives();
            if (relativesResponse['success'] == true && relativesResponse['relatives'] != null) {
              UserData.myUser.relatives = (relativesResponse['relatives'] as List).map((relative) {
                return {
                  'id': relative['id']?.toString() ?? '',
                  'name': relative['name']?.toString() ?? '',
                  'surname': relative['surname']?.toString() ?? '',
                  'email': relative['email']?.toString() ?? '',
                  'phone': relative['phone']?.toString() ?? '',
                };
              }).toList();
            }
          } catch (_) {}
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else {
          setState(() {
            _errorMessage = 'Authentication failed. Please try again.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> sendFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        print("📦 FCM Token: $fcmToken");

        final response = await http.post(
          Uri.parse('http://192.168.1.40:3000/api/token'), // IP'ni değiştir
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'fcmToken': fcmToken,
          }),
        );

        if (response.statusCode == 200) {
          print('✅ Token backend\'e gönderildi');
        } else {
          print('❌ Backend Hatası: ${response.statusCode} - ${response.body}');
        }
      } else {
        print("⚠️ Token alınamadı");
      }
    } catch (e) {
      print("❌ Token gönderme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.indigo.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Icon(Icons.phone, size: 80, color: Colors.blueAccent),
                SizedBox(height: 10),
                Text(
                  "YOUR SAFETY\nOUR PRIORITY",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  hintText: "Email",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  hintText: "Password",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Center(
                        child: Text(
                          "LOGIN",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 15),

            TextButton(
              onPressed: () {
                print("Forgot Password clicked");
              },
              child: Text(
                "Forgot your password?",
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text(
                "Don't you have an account? Sign up",
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
