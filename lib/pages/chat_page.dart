import 'package:flutter/material.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ChatScreen());
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  int _selectedIndex = 1; // Başlangıçta seçili olan sayfa

  // Sayfalar için widget'lar
  static const List<Widget> _widgetOptions = <Widget>[
    Text('Dashboard Sayfası'),
    Text('Chat Sayfası'),
    Text('Notifications Sayfası'),
    Text('Profile Sayfası'),
  ];

  // Alt bar butonlarına tıklandığında yapılacak işlem
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Communication',

          style: TextStyle(
            color: Colors.white, // Yazı rengini beyaz yap
            fontWeight: FontWeight.bold, // Yazıyı kalın yap
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 99, 129, 203),
        elevation: 0, // AppBar altındaki gölgeyi kaldırabilirsiniz
        titleSpacing: 0, // Başlığı sola hizalayın
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Mesajları gösteren liste
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _messages[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Mesaj yazma ve gönderme kısmı
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    setState(() {
                      if (_messageController.text.isNotEmpty) {
                        _messages.add(_messageController.text);
                        _messageController.clear();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      // Alt bar
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
}
