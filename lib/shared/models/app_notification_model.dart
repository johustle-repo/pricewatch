class AppNotificationModel {
  const AppNotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String createdAt;

  factory AppNotificationModel.fromMap(Map<String, Object?> map) {
    return AppNotificationModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      isRead: (map['is_read'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt,
    };
  }
}
