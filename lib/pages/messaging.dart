import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> setupOnMessageHandler(BuildContext context) async {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final data = message.data;
    final question = data['question'];
    final notificationId = data['notificationId'];
    final yesLabel = data['yesLabel'] ?? 'Evet';
    final noLabel = data['noLabel'] ?? 'Hayır';

    if (question != null && notificationId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Text(question),
          actions: [
            TextButton(
              child: Text(yesLabel),
              onPressed: () {
                sendResponse(notificationId, 'yes');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(noLabel),
              onPressed: () {
                sendResponse(notificationId, 'no');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  });
}

Future<void> sendResponse(String notificationId, String response) async {
  final url = Uri.parse('http://192.168.1.40:3000/api/web/earthquake/notification-response');
  try {
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'notificationId': notificationId, 'response': response}),
    );
  } catch (e) {
    debugPrint('Error sending response: $e');
  }
}