import 'package:flutter/material.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/showDialog.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/settings_page.dart';
import 'package:senior_project/pages/login_page.dart';
import 'package:senior_project/services/auth_service.dart';
import '../models/user.dart';
import '../utils/user_data.dart';
import '../widgets/button_widget.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User user = UserData.myUser;
  int _selectedIndex = 3;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    // First try to get the user data from UserData
    if (UserData.myUser.email != 'No Email') {
      setState(() {
        user = UserData.myUser;
        _isLoading = false;
      });
    }
    
    // Then fetch the latest data from the server
    await _fetchUserProfile();
    await _fetchRelatives();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profileData = await _authService.getUserProfile();
      print('Received profile data: $profileData');

      if (!mounted) return;

      setState(() {
        _userProfile = profileData['user'];
        user = User(
          imagePath: 'https://via.placeholder.com/150',
          name: _userProfile!['name'] ?? user.name,
          surname: _userProfile!['surname'] ?? user.surname,
          email: _userProfile!['email'] ?? user.email,
          phone: _userProfile!['phoneNumber'] ?? user.phone,
          address: _userProfile!['address'] ?? user.address,
          isDarkMode: false,
          relatives: user.relatives,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Profile fetch error in UI: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      // If unauthorized, redirect to login
      if (_errorMessage?.contains('Unauthorized') == true) {
        await _authService.removeToken();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }
  }

  Future<void> _fetchRelatives() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _authService.getRelatives();
      print('Relatives response: $response');

      if (response['success'] == true && response['relatives'] != null) {
        setState(() {
          user.relatives = (response['relatives'] as List).map((relative) {
            return {
              'id': relative['id']?.toString() ?? '',
              'name': relative['name']?.toString() ?? '',
              'surname': relative['surname']?.toString() ?? '',
              'email': relative['email']?.toString() ?? '',
              'phone': relative['phone']?.toString() ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Failed to fetch relatives: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching relatives: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load relatives: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardPage()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        break;
    }
  }

  Future<void> _logout() async {
    await _authService.removeToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _showAddRelativeDialog() async {
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Relative'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: surnameController,
                decoration: InputDecoration(labelText: 'Surname'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  surnameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              try {
                setState(() {
                  _isLoading = true;
                });

                final response = await _authService.addRelative(
                  nameController.text,
                  surnameController.text,
                  emailController.text,
                  phoneController.text,
                );

                if (!mounted) return;

                if (response['success'] == true) {
                  // Close the dialog
                  Navigator.pop(context);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Relative added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh the relatives list
                  await _fetchRelatives();

                  // Force a rebuild of the widget
                  setState(() {
                    _isLoading = false;
                  });
                } else {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['message'] ?? 'Failed to add relative'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditRelativeDialog(Map<String, String> relative) async {
    final nameController = TextEditingController(text: relative['name']);
    final surnameController = TextEditingController(text: relative['surname']);
    final emailController = TextEditingController(text: relative['email']);
    final phoneController = TextEditingController(text: relative['phone']);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Relative'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: surnameController,
                decoration: InputDecoration(labelText: 'Surname'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  surnameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              try {
                final response = await _authService.updateRelative(
                  relative['id']!,
                  nameController.text,
                  surnameController.text,
                  emailController.text,
                  phoneController.text,
                );

                if (response['success'] == true) {
                  await _fetchRelatives();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Relative updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRelative(String relativeId) async {
    try {
      final response = await _authService.deleteRelative(relativeId);
      if (response['success'] == true) {
        await _fetchRelatives();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Relative deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 99, 129, 203),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 99, 129, 203),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchUserProfile,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 99, 129, 203),
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 99, 129, 203),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchUserProfile();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 120,
              child: DrawerHeader(
                decoration: BoxDecoration(color: const Color.fromARGB(255, 99, 129, 203)),
                child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SettingsPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log out'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Implement profile picture update
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: user.imagePath.startsWith('http')
                      ? NetworkImage(user.imagePath)
                      : AssetImage(user.imagePath) as ImageProvider,
                ),
              ),
              const SizedBox(height: 10),
              buildEditableField("Name", user.name, (newValue) {
                setState(() => user.name = newValue);
              }),
              buildEditableField("Surname", user.surname, (newValue) {
                setState(() => user.surname = newValue);
              }),
              buildEditableField("Email", user.email, (newValue) {
                setState(() => user.email = newValue);
              }),
              buildEditableField("Phone", user.phone, (newValue) {
                setState(() => user.phone = newValue);
              }),
              buildEditableField("Address", user.address, (newValue) {
                setState(() => user.address = newValue);
              }),
              const SizedBox(height: 20),
              buildRelativesSection(),
              const SizedBox(height: 20),
              ButtonWidget(
                text: "Save Changes",
                onClicked: () async {
                  try {
                    setState(() {
                      _isLoading = true;
                    });

                    final response = await _authService.updateProfile(
                      user.name,
                      user.surname,
                      user.phone,
                      user.address,
                    );

                    if (!mounted) return;

                    if (response['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response['message'] ?? 'Failed to update profile'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
              ),
              ElevatedButton(
                onPressed: () {
                  showSafetyNotification(context);
                },
                child: Text("Check Safety", style: TextStyle(color: Color.fromARGB(255, 99, 129, 203))),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget buildEditableField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white70)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget buildRelativesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Relatives",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _showAddRelativeDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                "Add Relative",
                style: TextStyle(color: Color.fromARGB(255, 99, 129, 203)),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_isLoading)
          Center(child: CircularProgressIndicator(color: Colors.white))
        else if (user.relatives.isEmpty)
          Center(
            child: Text(
              "No relatives added yet",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: user.relatives.length,
            itemBuilder: (context, index) {
              final relative = user.relatives[index];
              return Card(
                color: Colors.white.withOpacity(0.1),
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${relative['name']} ${relative['surname']}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.white),
                                onPressed: () => _showEditRelativeDialog(relative),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.white),
                                onPressed: () => _deleteRelative(relative['id']!),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Email: ${relative['email']}",
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Phone: ${relative['phone']}",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
