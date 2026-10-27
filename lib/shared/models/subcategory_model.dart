class SubcategoryModel {
  const SubcategoryModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.createdAt,
  });

  final int? id;
  final int categoryId;
  final String name;
  final String createdAt;

  factory SubcategoryModel.fromMap(Map<String, Object?> map) {
    return SubcategoryModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'created_at': createdAt,
    };
  }
}
