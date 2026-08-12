class SessionModel {
  const SessionModel({
    this.id,
    required this.userId,
    required this.isActive,
    required this.loginAt,
  });

  final int? id;
  final int userId;
  final bool isActive;
  final String loginAt;

  factory SessionModel.fromMap(Map<String, Object?> map) {
    return SessionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      isActive: (map['is_active'] as int? ?? 0) == 1,
      loginAt: map['login_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'is_active': isActive ? 1 : 0,
      'login_at': loginAt,
    };
  }
}
