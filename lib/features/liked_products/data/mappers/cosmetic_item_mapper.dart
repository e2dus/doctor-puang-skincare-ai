import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';
import 'package:mobileprogramming_groupproject_2025/models/cosmetic_item.dart'
    as model;
import 'package:mobileprogramming_groupproject_2025/features/product/domain/entities/product_entity.dart';

/// Mapper for converting between domain entities and data models
class CosmeticItemMapper {
  /// Convert from old CosmeticItem model to Entity
  static CosmeticItemEntity fromModel(model.CosmeticItem item) {
    return CosmeticItemEntity(
      title: item.title,
      rating: item.rating,
      category: item.category,
      priceRange: item.priceRange,
      supportingText: item.supportingText,
      productId: item.productId,
      skuId: item.skuId,
      imageUrl: item.imageUrl,
    );
  }

  /// Convert from Entity to old CosmeticItem model (if needed)
  static model.CosmeticItem toModel(CosmeticItemEntity entity) {
    return model.CosmeticItem(
      title: entity.title,
      rating: entity.rating,
      category: entity.category,
      priceRange: entity.priceRange,
      supportingText: entity.supportingText,
      productId: entity.productId,
      skuId: entity.skuId,
      imageUrl: entity.imageUrl,
    );
  }

  /// Convert from ProductEntity to CosmeticItemEntity
  static CosmeticItemEntity fromProductEntity(ProductEntity product) {
    return CosmeticItemEntity(
      title: product.title,
      rating: product.rating,
      category: product.category ?? product.brandName,
      priceRange: product.priceRange,
      supportingText: product.brandName,
      productId: product.productId,
      skuId: product.skuId,
      imageUrl: product.imageUrl,
    );
  }

  /// Convert from ProductEntity to CosmeticItem model
  static model.CosmeticItem productEntityToModel(ProductEntity product) {
    return model.CosmeticItem(
      title: product.title,
      rating: product.rating,
      category: product.category ?? product.brandName,
      priceRange: product.priceRange,
      supportingText: product.brandName,
      productId: product.productId,
      skuId: product.skuId,
      imageUrl: product.imageUrl,
    );
  }
}
