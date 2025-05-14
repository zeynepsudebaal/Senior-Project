import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class AddRelativesPopup extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AddRelativesPopup({Key? key, required this.userData}) : super(key: key);

  @override
  _AddRelativesPopupState createState() => _AddRelativesPopupState();
}

class _AddRelativesPopupState extends State<AddRelativesPopup> {
  final List<Map<String, TextEditingController>> _relatives = [];
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  // Email validation regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  // Phone validation regex (allows formats like: +1234567890, 123-456-7890, (123) 456-7890)
  static final _phoneRegex = RegExp(
    r'^\+?[\d\s-()]{10,}$',
  );

  // List of common email domains
  static final List<String> _commonDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
  ];

  // Suggest a domain if a common typo is detected
  String? _suggestDomain(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return null;
    final domain = parts[1];
    for (final commonDomain in _commonDomains) {
      if (_levenshteinDistance(domain, commonDomain) == 1) {
        return commonDomain;
      }
    }
    return null;
  }

  // Calculate Levenshtein distance
  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost
        ].reduce((a, b) => a < b ? a : b);
      }
      for (var j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    final suggestion = _suggestDomain(value);
    if (suggestion != null) {
      return 'Did you mean ${value.split('@')[0]}@$suggestion?';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Initialize with two empty relative forms
    _addRelativeForm();
    _addRelativeForm();
  }

  void _addRelativeForm() {
    setState(() {
      _relatives.add({
        'name': TextEditingController(),
        'surname': TextEditingController(),
        'email': TextEditingController(),
        'phone': TextEditingController(),
      });
    });
  }

  void _removeRelativeForm(int index) {
    if (_relatives.length > 2) {
      setState(() {
        _relatives.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least two relatives are required'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finishRegistration() async {
    // Validate all relative forms
    for (var relative in _relatives) {
      if (relative['name']!.text.isEmpty ||
          relative['surname']!.text.isEmpty ||
          !_emailRegex.hasMatch(relative['email']!.text) ||
          !_phoneRegex.hasMatch(relative['phone']!.text)) {
        setState(() {
          _errorMessage = 'Please fill in all fields with valid data for all relatives';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Prepare relatives data
      final relativesData = _relatives.map((relative) => {
        'name': relative['name']!.text,
        'surname': relative['surname']!.text,
        'email': relative['email']!.text,
        'phone': relative['phone']!.text,
      }).toList();

      // Register the user with relatives
      print('Starting user registration with relatives...');
      final registerResponse = await _authService.register(
        widget.userData['email'],
        widget.userData['password'],
        widget.userData['name'],
        widget.userData['surname'],
        widget.userData['phone'],
        widget.userData['address'],
        widget.userData['birthDate'],
        widget.userData['gender'],
        relativesData,
      );
      print('Registration response: $registerResponse');

      if (registerResponse['success'] == true) {
        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        print('Registration failed: ${registerResponse['message']}');
        setState(() {
          _errorMessage = registerResponse['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      print('Error during registration process: $e');
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
      appBar: AppBar(
        title: Text('Add Relatives'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.indigo.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Add at least two relatives to complete registration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _relatives.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Relative ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_relatives.length > 2)
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeRelativeForm(index),
                                  ),
                              ],
                            ),
                            TextFormField(
                              controller: _relatives[index]['name'],
                              decoration: InputDecoration(
                                labelText: 'Name',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _relatives[index]['surname'],
                              decoration: InputDecoration(
                                labelText: 'Surname',
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Surname is required';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _relatives[index]['email'],
                              decoration: InputDecoration(
                                labelText: 'Email',
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'example@email.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            TextFormField(
                              controller: _relatives[index]['phone'],
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                filled: true,
                                fillColor: Colors.white,
                                hintText: '+1234567890 or (123) 456-7890',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: _validatePhone,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addRelativeForm,
                    icon: Icon(Icons.add),
                    label: Text('Add Another Relative'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _finishRegistration,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Finish Registration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var relative in _relatives) {
      relative['name']!.dispose();
      relative['surname']!.dispose();
      relative['email']!.dispose();
      relative['phone']!.dispose();
    }
    super.dispose();
  }
} 