import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/message.dart';

// Bilgisayarının IP adresini burada doğru yazmalısın.
const String apiUrl = 'http://172.20.10.2:3000/api/web/chat';

class ChatService {
  static Future<String> startChat(String adminId, String userId) async {
    if (userId.isEmpty) throw Exception('Kullanıcı ID boş olamaz');
    final response = await http.post(
      Uri.parse('$apiUrl/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adminId': adminId,
        'userId': userId,
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
    if (chatId.isEmpty) throw Exception('Chat ID boş olamaz');
    final response = await http.get(Uri.parse('$apiUrl/conversation/$chatId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Message.fromJson(e)).toList();
    } else {
      throw Exception('Mesajlar alınamadı');
    }
  }

  static Future<void> sendMessage(
      String chatId, String senderId, String text) async {
    if (chatId.isEmpty || senderId.isEmpty || text.isEmpty) {
      throw Exception('Boş parametre ile mesaj gönderilemez');
    }
    final response = await http.post(
      Uri.parse('$apiUrl/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Mesaj gönderilemedi');
    }
  }
}
