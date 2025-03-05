import 'package:flutter/material.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/showDialog.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/settings_page.dart'; // SettingsPage import edildi
import '../models/user.dart';
import '../utils/user_data.dart';
import '../widgets/button_widget.dart';
import 'package:senior_project/pages/login_page.dart'; // LoginPage import edildi

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User user = UserData.myUser;
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Burada sayfa geçişlerini yönetebilirsin
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
        break;
    }
  }

  void _onDrawerItemTapped(int index) {
    Navigator.pop(context); // Close the drawer
    _onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 120, // Set the desired height
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 99, 129, 203),
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log out'),
              onTap: () {
                // Çıkış yapma işlemi
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ), // LoginPage'e yönlendiriyor
                );
              },
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
                  backgroundImage:
                      user.imagePath.startsWith('http')
                          ? NetworkImage(user.imagePath)
                          : AssetImage(user.imagePath) as ImageProvider,
                ),
              ),
              const SizedBox(height: 10),
              buildEditableField("Name-Surname", user.name, (newValue) {
                setState(() => user.name = newValue);
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
                onClicked: () {
                  print("Changes saved");
                },
              ),
              ElevatedButton(
                onPressed: () {
                  showSafetyNotification(context);
                },
                child: Text("Check Safety"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue, // Seçili öğe rengi
        unselectedItemColor: Colors.grey, // Seçilmemiş öğe rengi
        currentIndex: _selectedIndex, // Seçili sekmeyi takip ediyor
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget buildEditableField(
    String label,
    String value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
        Text(
          "Relatives",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: user.relatives.length,
          itemBuilder: (context, index) {
            final relative = user.relatives[index];
            return ListTile(
              title: Text(relative["name"]!),
              subtitle: Text(
                "Phone: ${relative["phone"]!}\nEmail: ${relative["email"]!}",
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    user.relatives.removeAt(index);
                  });
                },
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement add relative functionality
          },
          child: Text("Add Relative"),
        ),
      ],
    );
  }
}
