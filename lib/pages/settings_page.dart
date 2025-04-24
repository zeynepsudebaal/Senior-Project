import 'package:flutter/material.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/chat_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/profile_page.dart'; // ProfilePage'i import ediyoruz.
import '../widgets/button_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String email = "user@example.com";
  String phone = "123-456-7890";
  String address = "123 Main Street";
  List<Map<String, String>> relatives = [
    {"name": "John", "phone": "123-456-7890", "email": "john@example.com"},
  ];

  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _relativeNameController = TextEditingController();
  final _relativePhoneController = TextEditingController();
  final _relativeEmailController = TextEditingController();

  int _selectedIndex = 0; // For BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _emailController.text = email;
    _phoneController.text = phone;
    _addressController.text = address;
  }

  void saveChanges() {
    setState(() {
      email = _emailController.text;
      phone = _phoneController.text;
      address = _addressController.text;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Changes saved successfully!')));
  }

  void addRelative() {
    setState(() {
      relatives.add({
        "name": _relativeNameController.text,
        "phone": _relativePhoneController.text,
        "email": _relativeEmailController.text,
      });
    });
    _relativeNameController.clear();
    _relativePhoneController.clear();
    _relativeEmailController.clear();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: const Color.fromARGB(255, 99, 129, 203),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildEditableField("Email", email, _emailController),
              buildEditableField("Phone", phone, _phoneController),
              buildEditableField("Address", address, _addressController),
              const SizedBox(height: 20),
              buildRelativesSection(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveChanges,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor:
                      Colors.blue, // Use backgroundColor instead of primary
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Save Changes", style: TextStyle(fontSize: 16)),
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
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: value,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
        ),
        const SizedBox(height: 10),
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
          itemCount: relatives.length,
          itemBuilder: (context, index) {
            final relative = relatives[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(relative["name"]!),
                subtitle: Text(
                  "Phone: ${relative["phone"]!}\nEmail: ${relative["email"]!}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      relatives.removeAt(index);
                    });
                  },
                ),
              ),
            );
          },
        ),
        buildAddRelativeSection(),
      ],
    );
  }

  Widget buildAddRelativeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add Relative",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        buildEditableField("Relative Name", "", _relativeNameController),
        buildEditableField("Relative Phone", "", _relativePhoneController),
        buildEditableField("Relative Email", "", _relativeEmailController),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: addRelative,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.green, // Use backgroundColor instead of primary
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text("Add Relative", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
