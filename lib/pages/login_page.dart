import 'package:flutter/material.dart';
import 'register_page.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';
import '../models/user_data.dart';
import '../models/user.dart';

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
        if (!mounted) return;
        
        // Store the user data in UserData
        UserData.myUser = User(
          imagePath: 'https://via.placeholder.com/150',
          name: response['user']['name'] ?? 'No Name',
          surname: response['user']['surname'] ?? 'No Surname',
          email: response['user']['email'] ?? 'No Email',
          phone: response['user']['phoneNumber'] ?? 'No Phone',
          address: response['user']['address'] ?? 'No Address',
          isDarkMode: false,
          relatives: [],
        );

        // Wait to ensure token is properly saved
        await Future.delayed(Duration(milliseconds: 300));

        // Verify token is available before proceeding
        final token = await _authService.getToken();
        print('Verifying token before proceeding: ${token != null ? 'Token exists' : 'No token found'}');
        
        if (token == null) {
          setState(() {
            _errorMessage = 'Authentication failed. Please try again.';
            _isLoading = false;
          });
          return;
        }

        // Fetch user profile first to ensure authentication is working
        try {
          print('Fetching user profile to verify authentication...');
          final profileResponse = await _authService.getUserProfile();
          print('Profile response: $profileResponse');
          
          if (profileResponse['success'] == true) {
            // Now fetch relatives after confirming authentication works
            try {
              print('Fetching relatives after login...');
              final relativesResponse = await _authService.getRelatives();
              print('Relatives response: $relativesResponse');
              
              if (relativesResponse['success'] == true && relativesResponse['relatives'] != null) {
                print('Successfully fetched relatives: ${relativesResponse['relatives']}');
                UserData.myUser.relatives = (relativesResponse['relatives'] as List).map((relative) {
                  return {
                    'id': relative['id']?.toString() ?? '',
                    'name': relative['name']?.toString() ?? '',
                    'surname': relative['surname']?.toString() ?? '',
                    'email': relative['email']?.toString() ?? '',
                    'phone': relative['phone']?.toString() ?? '',
                  };
                }).toList();
                print('Updated UserData.myUser.relatives: ${UserData.myUser.relatives}');
              } else {
                print('Failed to fetch relatives: ${relativesResponse['message']}');
              }
            } catch (e) {
              print('Error fetching relatives during login: $e');
              // Continue with login even if relatives fetch fails
            }

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
        } catch (e) {
          print('Error verifying authentication after login: $e');
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
            // Logo ve Başlık
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

            // Error Message
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

            // Email TextField
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

            // Password TextField
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

            // Login Button
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

            // Forgot Password Link
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

            // Register Link
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
