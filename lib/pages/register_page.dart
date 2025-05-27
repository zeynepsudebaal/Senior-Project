import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/auth_service.dart';
import '../pages/add_relatives_popup.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  String _selectedGender = 'Male';
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  // Email validation regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Phone validation regex - updated to enforce E.164 format (+CountryCodeDigits)
  static final _phoneRegex = RegExp(
    r'^\+[1-9]\d{1,14}$',
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
    
    // Remove any spaces, dashes, parentheses
    String formattedPhone = value.replaceAll(RegExp(r'[\s\-()]'), '');
    
    // Ensure it starts with a plus sign
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }
    
    if (!_phoneRegex.hasMatch(formattedPhone)) {
      return 'Please enter a valid phone number in E.164 format (e.g., +1234567890)';
    }
    
    // Store the formatted number back in the controller
    if (value != formattedPhone) {
      // We can't modify the controller directly from the validator,
      // but we can provide guidance for the user
      return 'Please format as: $formattedPhone';
    }
    
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Address validation regex
  static final _addressRegex = RegExp(
    r'^[A-Za-z\s]+,\s*[A-Za-z\s]+,\s*[A-Za-z\s]+,\s*\d+$',
  );

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }

    // Format the address
    String formattedAddress = value.trim();
    
    // Capitalize first letter of each word
    formattedAddress = formattedAddress.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    // Ensure proper spacing after commas
    formattedAddress = formattedAddress.replaceAll(RegExp(r',\s*'), ', ');

    // Validate the format
    if (!_addressRegex.hasMatch(formattedAddress)) {
      return 'Please use format: City, District, Street Name, Building Number\nExample: Istanbul, Kadikoy, Ataturk Street, 42';
    }

    // Update the controller with the formatted value
    if (value != formattedAddress) {
      _addressController.value = TextEditingValue(
        text: formattedAddress,
        selection: TextSelection.collapsed(offset: formattedAddress.length),
      );
    }

    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    
    // Format the phone number to E.164 before submitting
    String phone = _phoneController.text.trim();
    // Remove any spaces, dashes, parentheses
    phone = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    // Ensure it starts with a plus sign
    if (!phone.startsWith('+')) {
      phone = '+$phone';
    }
    
    // Validate phone number again
    if (!_phoneRegex.hasMatch(phone)) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number in E.164 format (e.g., +1234567890)';
      });
      return;
    }
    
    // Update the controller with the formatted value
    _phoneController.text = phone;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if email exists first
      final checkEmailResponse = await _authService.checkEmailExists(_emailController.text);
      
      if (checkEmailResponse['exists'] == true) {
        setState(() {
          _errorMessage = 'This email is already registered';
          _isLoading = false;
        });
        return;
      }

      // If we get here, the email is valid and not registered
      // Navigate to AddRelativesPopup
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddRelativesPopup(
            userData: {
              'email': _emailController.text,
              'password': _passwordController.text,
              'name': _nameController.text,
              'surname': _surnameController.text,
              'phone': _phoneController.text,
              'address': _addressController.text,
              'birthDate': _birthDateController.text,
              'gender': _selectedGender,
            },
          ),
        ),
      );
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Column(
                  children: [
                    Icon(Icons.phone, size: 80, color: Colors.blueAccent),
                    SizedBox(height: 10),
                    Text(
                      "CREATE ACCOUNT",
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

                // Name TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: "Name",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Surname TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _surnameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: "Surname",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Surname is required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Email TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
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
                    validator: _validateEmail,
                  ),
                ),
                SizedBox(height: 15),

                // Password TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Confirm Password TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: "Confirm Password",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Phone TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: "Phone Number (E.164 format: +1234567890)",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      helperText: 'Must include country code with + prefix',
                      helperStyle: TextStyle(color: Colors.white70),
                    ),
                    validator: _validatePhone,
                    onChanged: (value) {
                      // Auto-format: remove spaces, dashes, parentheses
                      String formatted = value.replaceAll(RegExp(r'[\s\-()]'), '');
                      
                      // Ensure it starts with a plus sign
                      if (formatted.isNotEmpty && !formatted.startsWith('+')) {
                        formatted = '+$formatted';
                        
                        // Update controller with the formatted value
                        _phoneController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Address TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: "Address (e.g., Istanbul, Kadikoy, Ataturk Street, 42)",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      helperText: 'Format: City, District, Street Name, Building Number',
                      helperStyle: TextStyle(color: Colors.white70),
                    ),
                    validator: _validateAddress,
                  ),
                ),
                SizedBox(height: 15),

                // Birth Date TextFormField
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      hintText: "Birth Date",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Birth date is required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 15),

                // Gender Dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        dropdownColor: Colors.indigo.shade700,
                        style: TextStyle(color: Colors.white),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                        items: ['Male', 'Female', 'Other']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Register Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                              "SIGN UP",
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 15),

                // Login Link
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text(
                    "Already have an account? Log in",
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
