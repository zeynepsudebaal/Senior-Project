import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String type;
  final DateTime dateTime;
  String? userResponse;

  NotificationItem({
    required this.id,
    required this.type,
    required this.dateTime,
    this.userResponse,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'].toString(),
      type: json['type'] ?? 'Deprem',
      dateTime:
          DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class NotificationPage extends StatefulWidget {
  final Map<String, dynamic>? notificationData;

  NotificationPage({Key? key, this.notificationData}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();

    // Bildirimden veri geldiyse listeye ekle
    if (widget.notificationData != null) {
      final singleNotif = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.notificationData!['type'] ?? 'Deprem',
        dateTime: DateTime.parse(widget.notificationData!['dateTime'] ??
            DateTime.now().toIso8601String()),
      );

      setState(() {
        notifications.insert(0, singleNotif);
        isLoading = false;
      });
    }
  }

  Future<void> fetchNotifications() async {
    final url = Uri.parse('http://192.168.1.47:3000/api/web/earthquake');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final now = DateTime.now();
        final oneDayAgo = now.subtract(Duration(days: 1));

        // 1 gün içindeki bildirimleri filtrele
        final filteredData = data.where((item) {
          final dateTimeStr = item['dateTime'] ?? now.toIso8601String();
          final dateTime = DateTime.tryParse(dateTimeStr) ?? now;
          return dateTime.isAfter(oneDayAgo);
        }).toList();

        setState(() {
          notifications = filteredData
              .map((item) => NotificationItem.fromJson(item))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('API error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Fetch error: $e');
    }
  }

  final user = FirebaseAuth.instance.currentUser;
  void _setUserResponse(String id, String response) async {
    final userId = user?.uid; // TODO: Gerçek kullanıcı ID'sini burada al

    final url = Uri.parse('http://192.168.1.47:3000/api/web/user-response');
    final body = {
      'notificationId': id,
      'userId': userId,
      'response': response,
    };

    try {
      final res = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

      if (res.statusCode == 200) {
        print("Cevap başarıyla gönderildi");
        setState(() {
          final notif = notifications.firstWhere((element) => element.id == id);
          notif.userResponse = response;
        });
      } else {
        print("Sunucu hatası: ${res.statusCode}");
      }
    } catch (e) {
      print("Hata oluştu: $e");
    }
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.type} Alert',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tarih: ${item.dateTime.toLocal().toString().split('.')[0]}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Text(
              'Güvende misiniz?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            if (item.userResponse == null) ...[
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _setUserResponse(item.id, 'Evet'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('Evet'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _setUserResponse(item.id, 'Hayır'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text('Hayır'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Cevabınız: ${item.userResponse}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bildirimler'),
        backgroundColor: Color.fromARGB(255, 99, 129, 203),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(child: Text('Henüz bildirim yok'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(notifications[index]);
                  },
                ),
    );
  }
}
