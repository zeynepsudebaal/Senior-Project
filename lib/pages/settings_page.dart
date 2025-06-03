import 'package:flutter/material.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/profile_page.dart';
import 'package:senior_project/pages/login_page.dart';
import '../widgets/button_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 4; // Index for Settings in bottom navigation
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // User data fields
  String email = "";
  String phone = "";
  String address = "";
  String name = "";
  String surname = "";
  String birthDate = "";
  String gender = "";

  // Controllers for text fields
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _genderController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Email validation regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  // Phone validation regex - updated to enforce E.164 format (+CountryCodeDigits)
  static final _phoneRegex = RegExp(
    r'^\+[1-9]\d{1,14}$'
  );

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profileData = await _authService.getUserProfile();
      print('Settings Page - Profile Data: $profileData');
      
      if (!mounted) return;

      setState(() {
        final userData = profileData['user'];
        email = userData['email'] ?? "";
        phone = userData['phoneNumber'] ?? "";
        address = userData['address'] ?? "";
        name = userData['name'] ?? "";
        surname = userData['surname'] ?? "";
        birthDate = userData['birthDate'] ?? "";
        gender = userData['gender'] ?? "";

        print('Settings Page - Birth Date received: $birthDate');

        // Update controllers
        _emailController.text = email;
        _phoneController.text = phone;
        _addressController.text = address;
        _nameController.text = name;
        _surnameController.text = surname;
        _birthDateController.text = birthDate;
        _genderController.text = gender;
        
        print('Settings Page - Birth Date controller text: ${_birthDateController.text}');
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Parse the existing date or use today's date as fallback
    DateTime initialDate;
    try {
      if (_birthDateController.text.isNotEmpty) {
        initialDate = DateTime.parse(_birthDateController.text);
      } else {
        initialDate = DateTime.now();
      }
    } catch (e) {
      print('Error parsing date: $e');
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        final formattedDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _birthDateController.text = formattedDate;
        print('New birth date selected: $formattedDate');
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
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
    
    return null;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Don't navigate if already on this page
    
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
    }
  }

  Widget buildEditableField(String label, TextEditingController controller, {
    String? Function(String?)? validator,
    bool isPassword = false,
    Function(String)? onChanged,
  }) {
    bool isPasswordField = isPassword || 
                         label.toLowerCase().contains('password');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          TextFormField(
            controller: controller,
            obscureText: isPasswordField,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
              hintText: label == "Phone" ? "E.164 format: +1234567890" : null,
              helperText: label == "Phone" ? "Must include country code with + prefix" : null,
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Format phone number before saving
      String phone = _phoneController.text.trim();
      // Remove any spaces, dashes, parentheses
      phone = phone.replaceAll(RegExp(r'[\s\-()]'), '');
      // Ensure it starts with a plus sign
      if (!phone.startsWith('+')) {
        phone = '+$phone';
      }
      _phoneController.text = phone;

      // Ensure gender is lowercase for the backend
      String genderValue = _genderController.text.toLowerCase();

      final response = await _authService.updateProfile(
        _nameController.text,
        _surnameController.text,
        phone,
        _addressController.text,
        email: _emailController.text,
        birthDate: _birthDateController.text,
        gender: genderValue,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        await fetchUserData(); // Refresh the data
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      if (!mounted) return;
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

  Future<void> changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('Attempting to change password...');
      final response = await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully!')),
        );
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to change password';
        });
      }
    } catch (e) {
      if (!mounted) return;
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
      backgroundColor: Colors.indigo.shade900,
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo.shade900,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 120,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.indigo.shade900),
                child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              selected: true,
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log out'),
              onTap: () async {
                await _authService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildEditableField("Name", _nameController, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    }),
                    buildEditableField("Surname", _surnameController, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Surname is required';
                      }
                      return null;
                    }),
                    buildEditableField("Email", _emailController, validator: _validateEmail),
                    buildEditableField("Phone", _phoneController, 
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
                    buildEditableField("Address", _addressController, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    }),
                    const SizedBox(height: 16),
                    Text(
                      "Birth Date",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    TextFormField(
                      controller: _birthDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                        suffixIcon: Icon(Icons.calendar_today, color: Colors.indigo.shade900),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Birth date is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _getFormattedGender(),
                          isExpanded: true,
                          dropdownColor: Colors.white.withOpacity(0.2),
                          items: ['Male', 'Female', 'Other'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _genderController.text = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildEditableField("Current Password", _currentPasswordController, isPassword: true),
                    buildEditableField("New Password", _newPasswordController, isPassword: true),
                    buildEditableField("Confirm New Password", _confirmPasswordController, isPassword: true),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saveUserData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: StadiumBorder(),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text("Save Profile"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: StadiumBorder(),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text("Change Password"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80), // Add padding for bottom navigation
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  // Helper method to ensure gender value matches dropdown options
  String _getFormattedGender() {
    // Default to 'Male' if empty
    if (_genderController.text.isEmpty) {
      return 'Male';
    }
    
    // Format the gender value to match dropdown options (capitalize first letter)
    String gender = _genderController.text.toLowerCase();
    if (gender == 'male') return 'Male';
    if (gender == 'female') return 'Female';
    if (gender == 'other') return 'Other';
    
    // Default to Male if no match found
    return 'Male';
  }
}
