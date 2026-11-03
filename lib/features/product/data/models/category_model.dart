import '../../domain/entities/category_entity.dart';

/// Data model for product category
class CategoryModel extends CategoryEntity {
  const CategoryModel({required super.name, required super.count});

  /// Create model from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(name: json['name'] ?? '', count: json['count'] ?? 0);
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {'name': name, 'count': count};
  }
}
