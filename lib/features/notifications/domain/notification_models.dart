// Create file: lib/features/notifications/domain/notification_models.dart

class AppNotification {
  final String id;
  final String title;
  final String timestamp;
  final String message;
  final bool isRead;
  final String? type; // 'sync', 'report', 'alert', 'registration'

  AppNotification({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.message,
    this.isRead = true,
    this.type,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      timestamp: json['timestamp'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? true,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'timestamp': timestamp,
    'message': message,
    'is_read': isRead,
    'type': type,
  };
}
