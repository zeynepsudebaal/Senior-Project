import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationRecord {
  final String type;
  final String? response;
  final String? locationName;
  final DateTime? createdAt;

  NotificationRecord({
    required this.type,
    this.response,
    this.locationName,
    this.createdAt,
  });
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  Stream<List<NotificationRecord>> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return NotificationRecord(
                type: data['type'] ?? '',
                response: data['response'],
                locationName: data['location']?['name'],
                createdAt: data['createdAt'] != null
                    ? (data['createdAt'] is String
                        ? DateTime.parse(data['createdAt'])
                        : (data['createdAt'] is Timestamp
                            ? (data['createdAt'] as Timestamp).toDate()
                            : null))
                    : null,
              );
            }).toList());
  }

  String getTypeLabel(String type) {
    switch (type) {
      case 'fire':
        return 'Yangın';
      case 'earthquake':
        return 'Deprem';
      case 'flood':
        return 'Sel';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bildirimler")),
      body: StreamBuilder<List<NotificationRecord>>(
        stream: getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Hiç bildiriminiz yok."));
          }
          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Card(
                margin:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(
                    "${getTypeLabel(n.type)} Alarmı",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Lokasyon: ${n.locationName ?? '-'}\n"
                      "Zaman: ${n.createdAt != null ? "${n.createdAt!.hour.toString().padLeft(2, '0')}:${n.createdAt!.minute.toString().padLeft(2, '0')} - ${n.createdAt!.day}.${n.createdAt!.month}.${n.createdAt!.year}" : '-'}\n"
                      "Cevap: ${n.response ?? '-'}",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}