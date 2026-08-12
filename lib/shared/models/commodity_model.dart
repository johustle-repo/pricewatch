class CommodityModel {
  const CommodityModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.unit,
    required this.srp,
    required this.createdAt,
  });

  final int? id;
  final int categoryId;
  final String? description;
  final String name;
  final String unit;
  final double srp;
  final String createdAt;

  factory CommodityModel.fromMap(Map<String, Object?> map) {
    return CommodityModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      unit: map['unit'] as String,
      srp: (map['srp'] as num).toDouble(),
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'unit': unit,
      'srp': srp,
      'created_at': createdAt,
    };
  }
}
