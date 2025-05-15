class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.read,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      sentAt: parseDate(json['sentAt']),
      read: json['read'] ?? false,
    );
  }

  static DateTime parseDate(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    } else if (value is Map<String, dynamic> && value.containsKey('_seconds')) {
      // Firestore Timestamp geliyor
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    } else {
      return DateTime.now(); // Yedekleme
    }
  }
}