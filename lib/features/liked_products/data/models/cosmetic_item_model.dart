import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';

/// Data model for cosmetic items (extends entity)
class CosmeticItemModel extends CosmeticItemEntity {
  const CosmeticItemModel({
    required super.title,
    required super.rating,
    required super.category,
    required super.priceRange,
    required super.supportingText,
  });

  /// Convert from entity
  factory CosmeticItemModel.fromEntity(CosmeticItemEntity entity) {
    return CosmeticItemModel(
      title: entity.title,
      rating: entity.rating,
      category: entity.category,
      priceRange: entity.priceRange,
      supportingText: entity.supportingText,
    );
  }

  /// Convert to entity
  CosmeticItemEntity toEntity() {
    return CosmeticItemEntity(
      title: title,
      rating: rating,
      category: category,
      priceRange: priceRange,
      supportingText: supportingText,
    );
  }
}

