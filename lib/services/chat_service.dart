import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/message.dart';
import '../models/user.dart';
import '../utils/user_data.dart';

// Bilgisayarının IP adresini burada doğru yazmalısın.
const String apiUrl = 'http://192.168.1.60:3000/api/web/chat';

class ChatService {
  static Future<String> startChat(String adminId, String userId) async {
    final response = await http.post(
      Uri.parse('$apiUrl/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adminId': adminId,
        'userId': userId,
        'userName': UserData.myUser.name,
        'userEmail': UserData.myUser.email,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['chatId'];
    } else {
      throw Exception('Chat başlatılamadı');
    }
  }

  static Future<List<Message>> fetchMessages(String chatId) async {
    final response = await http.get(Uri.parse('$apiUrl/conversation/$chatId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(
        response.body,
      ); // sadece jsonDecode yapıyoruz
      return data.map((e) => Message.fromJson(e)).toList();
    } else {
      throw Exception('Mesajlar alınamadı');
    }
  }

  static Future<void> sendMessage(
    String chatId,
    String senderId,
    String text,
  ) async {
    final User currentUser = UserData.myUser;

    final response = await http.post(
      Uri.parse('$apiUrl/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': currentUser.name,
        'senderEmail': currentUser.email,
        'text': text,
        'lastMessage': text, // Son mesajı da güncelliyoruz
        'participants': ['web', senderId], // Katılımcıları güncelliyoruz
        'updatedAt':
            DateTime.now().toIso8601String(), // Güncelleme zamanını ekliyoruz
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Mesaj gönderilemedi');
    }
  }
}
