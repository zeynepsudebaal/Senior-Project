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
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = await UserData.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _error = 'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar giriş yapın.';
          _loading = false;
          _isLoading = false;
        });
        return;
      }

      print('User ID loaded: $userId');
      setState(() {
        _userId = userId;
      });

      // Admin ID'sini al
      _adminId = await _apiService.getAdminId();
      if (_adminId.isEmpty) {
        setState(() {
          _error = 'Admin bilgileri alınamadı. Lütfen daha sonra tekrar deneyin.';
          _loading = false;
          _isLoading = false;
        });
        return;
      }

      print('Admin ID loaded: $_adminId');
      await _initializeChat();
    } catch (e) {
      print('User initialization error: $e');
      setState(() {
        _error = 'Bir hata oluştu: $e';
        _loading = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeChat() async {
    if (_userId == null || _userId!.isEmpty) {
      print('Cannot initialize chat: User ID is missing');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('Starting chat with admin: $_adminId and user: $_userId');
      _chatId = await _chatService.startChat(_adminId, _userId!);
      
      if (_chatId != null && _chatId!.isNotEmpty) {
        print('Chat initialized with ID: $_chatId');
        await _loadMessages();

        // Cancel existing timer if any
        _timer?.cancel();
        
        // Start new timer for message updates
        _timer = Timer.periodic(Duration(seconds: 5), (timer) {
          if (_chatId != null && mounted) {
            _loadMessages();
          }
        });

        setState(() {
          _loading = false;
          _isLoading = false;
        });
      } else {
        throw Exception('Invalid chat ID received');
      }
    } catch (e) {
      print('Chat initialization error: $e');
      setState(() {
        _error = 'Chat başlatılamadı: $e';
        _loading = false;
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
    if (_chatId == null || _chatId!.isEmpty) {
      print('Cannot load messages: Chat ID is missing');
      return;
    }

    try {
      final messages = await _chatService.fetchMessages(_chatId!);
      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      print('Message loading error: $e');
      if (mounted) {
        setState(() {
          _error = 'Mesajlar yüklenirken hata oluştu: $e';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _chatId == null) {
      print('Cannot send message: ${messageText.isEmpty ? "Empty message" : "Chat ID is missing"}');
      return;
    }
    
    try {
      await _chatService.sendMessage(_chatId!, messageText);
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      print('Message sending error: $e');
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
