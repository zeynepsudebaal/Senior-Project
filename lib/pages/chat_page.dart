import 'dart:async';
import 'package:flutter/material.dart';
import 'package:senior_project/pages/dashboard_page.dart';
import 'package:senior_project/pages/notifications_page.dart';
import 'package:senior_project/pages/profile_page.dart';
import '../services/chat_service.dart';
import '../utils/user_data.dart';
import '../services/api_service.dart';

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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _chatId;
  String? _userId;
  String _adminId = 'web';
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _loading = true;
  int _selectedIndex = 1;
  String? _error;

  Timer? _timer;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      final userId = await UserData.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _error =
              'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar giriş yapın.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _userId = userId;
      });

      // Admin ID'sini al
      _adminId = await _apiService.getAdminId();
      if (_adminId == null || _adminId.isEmpty) {
        setState(() {
          _error =
              'Admin bilgileri alınamadı. Lütfen daha sonra tekrar deneyin.';
          _loading = false;
        });
        return;
      }

      await _initializeChat();
    } catch (e) {
      print('Kullanıcı başlatılırken hata oluştu: $e');
      setState(() {
        _error = 'Bir hata oluştu: $e';
        _loading = false;
      });
    }
  }

  Future<void> _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_userId == null) {
        throw Exception('Kullanıcı bilgileri yüklenemedi');
      }

      _chatId = await _chatService.startChat(_adminId, _userId!);
      if (_chatId != null) {
        await _loadMessages();

        // Start the timer only after chat is initialized
        _timer = Timer.periodic(Duration(seconds: 5), (timer) {
          if (_chatId != null) {
            _loadMessages();
          }
        });
      }
    } catch (e) {
      print('Chat başlatma hatası: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat başlatılamadı: $e')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_chatId == null) return;
    try {
      final messages = await _chatService.fetchMessages(_chatId!);
      setState(() {
        _messages = messages;
        _loading = false;
        _isLoading = false;
      });
    } catch (e) {
      print('Mesajlar yüklenirken hata oluştu: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    try {
      await _chatService.sendMessage(_chatId!, _messageController.text.trim());
      _messageController.clear();
      await _loadMessages(); // Mesajı gönderdikten sonra mesajları yenile
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    }
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
        title: Text('Communication'),
        backgroundColor: const Color.fromARGB(255, 99, 129, 203),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text('Giriş Sayfasına Dön'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              _messages[_messages.length - 1 - index];
                          final isMe = message.senderId == _userId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message.senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
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
                              decoration: const InputDecoration(
                                hintText: 'Mesajınızı yazın...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
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
