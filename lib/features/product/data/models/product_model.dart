import '../../domain/entities/product_entity.dart';

/// Data model for cosmetic product
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.productId,
    required super.title,
    required super.brandName,
    required super.rating,
    required super.reviews,
    super.category,
    required super.priceRange,
    super.imageUrl,
    super.targetUrl,
    super.skuId,
    super.score,
  });

  /// Create model from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'] ?? '',
      title: json['product_name'] ?? '',
      brandName: json['brand_name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      category: json['primary_category'],
      priceRange: json['price_usd'] ?? '',
      imageUrl: json['image_url'],
      targetUrl: json['target_url'],
      skuId: json['skuId'],
      score: json['score']?.toDouble(),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': title,
      'brand_name': brandName,
      'rating': rating,
      'reviews': reviews,
      'primary_category': category,
      'price_usd': priceRange,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'skuId': skuId,
      'score': score,
    };
  }

  /// Create model from entity
  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      productId: entity.productId,
      title: entity.title,
      brandName: entity.brandName,
      rating: entity.rating,
      reviews: entity.reviews,
      category: entity.category,
      priceRange: entity.priceRange,
      imageUrl: entity.imageUrl,
      targetUrl: entity.targetUrl,
      skuId: entity.skuId,
      score: entity.score,
    );
  }
}

