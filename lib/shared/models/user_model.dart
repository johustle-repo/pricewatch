class UserModel {
  const UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    this.authUid,
    required this.role,
    this.storeId,
    required this.createdAt,
  });

  final int? id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String? authUid;
  final String role;
  final int? storeId;
  final String createdAt;

  bool get isAdmin => role == 'admin';
  bool get isVendor => role == 'vendor';

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String? ?? '',
      authUid: map['auth_uid'] as String?,
      role: map['role'] as String,
      storeId: map['store_id'] as int?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'auth_uid': authUid,
      'role': role,
      'store_id': storeId,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? passwordHash,
    String? authUid,
    String? role,
    int? storeId,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      authUid: authUid ?? this.authUid,
      role: role ?? this.role,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
