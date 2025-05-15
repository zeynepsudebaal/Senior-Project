import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senior_project/firebase_options.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/profile_page.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = [];
  int _selectedIndex = 1;

  String? _chatId;
  final String _adminId = 'web';
  String? _userId;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndStartChat();

    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_chatId != null) {
        _loadMessages();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeFirebaseAndStartChat() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await _setUserIdAndInitChat();
    } catch (e) {
      print('🔥 Firebase başlatılamadı: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _setUserIdAndInitChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Firebase user: $user');

      if (user == null) {
        print('Kullanıcı oturumu yok!');
        setState(() {
          _loading = false;
        });
        return;
      }

      setState(() {
        _userId = user.uid;
      });

      await _initializeChat();
    } catch (e) {
      print('Hata: FirebaseAuth çağrısı başarısız: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _initializeChat() async {
    if (_userId == null) {
      print('_userId null, chat başlatılamaz');
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      _chatId = await ChatService.startChat(_adminId, _userId!);
      print('Chat başlatıldı, chatId: $_chatId');
      await _loadMessages();
    } catch (e) {
      print('Chat başlatılırken hata oluştu: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_chatId == null) {
      print('chatId null, mesajlar yüklenemez');
      setState(() => _loading = false);
      return;
    }

    try {
      final messages = await ChatService.fetchMessages(_chatId!);
      print('Mesajlar yüklendi: ${messages.length}');
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (e) {
      print('Mesajlar yüklenirken hata oluştu: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null || _userId == null) return;

    try {
      await ChatService.sendMessage(_chatId!, _userId!, text);

      setState(() {
        _messages.add(
          Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: _userId!,
            text: text,
            sentAt: DateTime.now(),
            read: false,
          ),
        );
      });

      _messageController.clear();
    } catch (e) {
      print('Mesaj gönderilirken hata oluştu: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => DashboardPage()));
        break;
      case 1:
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => NotificationPage()));
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Communication'),
        backgroundColor: const Color.fromARGB(255, 99, 129, 203),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      bool isMe = msg.senderId == _userId;

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
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
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
