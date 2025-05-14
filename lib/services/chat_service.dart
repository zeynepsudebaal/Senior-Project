import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_data.dart';

import '../models/message.dart';
import '../models/user.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<String> startChat(String adminId, String userId) async {
    try {
      final token = await UserData.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/web/chat/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'adminId': adminId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['chatId'] == null) {
          throw Exception('Chat ID is missing from response');
        }
        return data['chatId'];
      } else {
        throw Exception('Chat başlatılamadı: ${response.body}');
      }
    } catch (e) {
      print('Chat başlatma hatası: $e');
      rethrow;
    }
  }

  Future<List<Message>> fetchMessages(String chatId) async {
    try {
      final token = await UserData.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/web/chat/conversation/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Mesajlar alınamadı: ${response.body}');
      }
    } catch (e) {
      print('Mesaj getirme hatası: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(String chatId, String text) async {
    try {
      final token = await UserData.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/web/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'chatId': chatId,
          'text': text,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Mesaj gönderilemedi: ${response.body}');
      }
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      rethrow;
    }
  }
}

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String text;
  final DateTime sentAt;
  final bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.text,
    required this.sentAt,
    required this.read,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['id']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? 'Unknown User',
        senderEmail: json['senderEmail']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        sentAt: json['sentAt'] == null
            ? DateTime.now()
            : json['sentAt'] is Map
                ? DateTime.fromMillisecondsSinceEpoch(
                    (json['sentAt']['_seconds'] as int) * 1000)
                : DateTime.parse(json['sentAt'].toString()),
        read: json['read'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing message: $json');
      print('Error details: $e');
      // Return a default message in case of parsing error
      return Message(
        id: '',
        senderId: '',
        senderName: 'Error',
        senderEmail: '',
        text: 'Message could not be loaded',
        sentAt: DateTime.now(),
        read: false,
      );
    }
  }
}
