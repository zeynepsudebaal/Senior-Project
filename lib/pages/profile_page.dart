import 'package:flutter/material.dart';
import 'package:senior_project/pages/showDialog.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import '../models/user.dart';
import '../utils/user_data.dart';
import '../widgets/button_widget.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User user = UserData.myUser;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case 1:
      // Navigate to Settings
        break;
      case 2:
      // Handle log out
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
                  color: Colors.green,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () => _onDrawerItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () => _onDrawerItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log out'),
              onTap: () => _onDrawerItemTapped(2),
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Log out',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildEditableField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Text("Relatives", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: user.relatives.length,
          itemBuilder: (context, index) {
            final relative = user.relatives[index];
            return ListTile(
              title: Text(relative["name"]!),
              subtitle: Text("Phone: ${relative["phone"]!}\nEmail: ${relative["email"]!}"),
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