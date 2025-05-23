import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senior_project/pages/chat_page.dart';

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
  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Tarih alanını kontrol et
    DateTime dateTime;
    if (data.containsKey('createdAt') && data['createdAt'] != null) {
      dateTime = (data['createdAt'] as Timestamp).toDate();
    } else if (data.containsKey('timestamp') && data['timestamp'] != null) {
      dateTime = (data['timestamp'] as Timestamp).toDate();
    } else {
      dateTime = DateTime.now(); // Tarih yoksa şimdiki zamanı koy
    }

    return NotificationItem(
      id: doc.id,
      type: data['type'] ?? 'Deprem',
      dateTime: dateTime,
      userResponse: data['userResponse'],
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

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchNotifications();

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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .limit(50) // İstersen limiti arttırabilirsin
          .get();

      final notifList = snapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc))
          .toList();

      // Tarihe göre azalan sıralama (en yeni en üstte)
      notifList.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        notifications = notifList;
        isLoading = false;
      });
    } catch (e) {
      print("Firestore'dan bildirim çekilirken hata: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _setUserResponse(String id, String response) async {
    final userId = user?.uid;

    final url = Uri.parse('http://192.168.1.50:3000/api/web/user-response');
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
                    onPressed: () async {
                      await _setUserResponse(item.id, 'Hayır');

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("SAKİN OLUN"),
                            content: Text(
                                "Sakin kalın, Chat sayfasına yönlendiriliyorsunuz"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => ChatScreen()),
                                  );
                                },
                                child: Text("Tamam"),
                              ),
                            ],
                          );
                        },
                      );
                    },
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
