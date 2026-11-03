import 'package:mobileprogramming_groupproject_2025/features/product/domain/entities/product_entity.dart';

/// Domain layer entity for cosmetic items
class CosmeticItemEntity {
  final String title;
  final double rating;
  final String category;
  final String priceRange;
  final String supportingText;
  final String? productId;
  final String? skuId;
  final String? imageUrl;

  const CosmeticItemEntity({
    required this.title,
    required this.rating,
    required this.category,
    required this.priceRange,
    required this.supportingText,
    this.productId,
    this.skuId,
    this.imageUrl,
  });

  /// Convert to ProductEntity
  ProductEntity toProductEntity() {
    return ProductEntity(
      productId: productId ?? title.hashCode.toString(),
      title: title,
      brandName: category,
      rating: rating,
      reviews: 0,
      category: category,
      priceRange: priceRange,
      imageUrl: imageUrl,
      targetUrl: null,
      skuId: skuId,
      score: null,
    );
  }

  /// Create a copy with optional updated fields
  CosmeticItemEntity copyWith({
    String? title,
    double? rating,
    String? category,
    String? priceRange,
    String? supportingText,
    String? productId,
    String? skuId,
    String? imageUrl,
  }) {
    return CosmeticItemEntity(
      title: title ?? this.title,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      priceRange: priceRange ?? this.priceRange,
      supportingText: supportingText ?? this.supportingText,
      productId: productId ?? this.productId,
      skuId: skuId ?? this.skuId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CosmeticItemEntity && other.title == title;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'rating': rating,
      'category': category,
      'priceRange': priceRange,
      'supportingText': supportingText,
      'productId': productId,
      'skuId': skuId,
      'imageUrl': imageUrl,
    };
  }

  /// Create from JSON
  factory CosmeticItemEntity.fromJson(Map<String, dynamic> json) {
    return CosmeticItemEntity(
      title: json['title'] as String,
      rating: (json['rating'] as num).toDouble(),
      category: json['category'] as String,
      priceRange: json['priceRange'] as String,
      supportingText: json['supportingText'] as String,
      productId: json['productId'] as String?,
      skuId: json['skuId'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  @override
  int get hashCode => title.hashCode;
}
