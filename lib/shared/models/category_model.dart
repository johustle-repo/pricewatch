class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? icon;
  final String createdAt;

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'icon': icon, 'created_at': createdAt};
  }
}
