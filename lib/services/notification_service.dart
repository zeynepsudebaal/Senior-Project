import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey;

  FCMService({required this.navigatorKey});

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    await _requestPermission();

    _fcmToken = await _messaging.getToken();
    print("FCM Token alındı: $_fcmToken");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print("FCM Token yenilendi: $newToken");
      // sendTokenToBackend(newToken);
    });

    // Uygulama ön plandayken mesaj alınca
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground mesaj alındı: ${message.notification?.title}');
      await saveNotificationToFirestore(message.data);
    });

    // Uygulama kapalı ya da arka plandayken bildirim tıklanma işlemi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('Bildirim tıklandı: ${message.data}');

      final data = message.data;
      await saveNotificationToFirestore(data);

      navigatorKey.currentState?.pushNamed(
        '/notifications',
        arguments: {
          'type': data['type'] ?? 'Deprem',
          'dateTime': data['dateTime'] ?? DateTime.now().toIso8601String(),
        },
      );
    });
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Bildirim izni verildi');
    } else {
      print('Bildirim izni reddedildi');
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    final response = await http.post(
      Uri.parse('http://172.20.10.2:3000/api/web/register-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      print('Token başarıyla backend\'e gönderildi');
    } else {
      print('Token gönderilirken hata oluştu: ${response.body}');
    }
  }

  Future<void> saveNotificationToFirestore(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Kullanıcı oturumu yok, bildirim kaydedilemedi.");
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'title': data['title'] ?? 'Başlık yok',
        'body': data['body'] ?? 'Mesaj yok',
        'type': data['type'] ?? 'bilgi',
        'dateTime': data['dateTime'] ?? DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Bildirim Firestore'a kaydedildi.");
    } catch (e) {
      print("Bildirim kaydı sırasında hata oluştu: $e");
    }
  }
}
