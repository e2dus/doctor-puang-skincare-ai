import 'package:mobileprogramming_groupproject_2025/features/product/domain/entities/product_entity.dart';

/// Legacy CosmeticItem model
/// This is kept for backward compatibility with existing code.
/// New code should use CosmeticItemEntity instead.
class CosmeticItem {
  final String title;
  final double rating;
  final String category;
  final String priceRange;
  final String supportingText;
  final String? productId;
  final String? skuId;
  final String? imageUrl;

  const CosmeticItem({
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

  /// Create a copy of this item with modified fields
  CosmeticItem copyWith({
    String? title,
    double? rating,
    String? category,
    String? priceRange,
    String? supportingText,
    String? productId,
    String? skuId,
    String? imageUrl,
  }) {
    return CosmeticItem(
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
    return other is CosmeticItem && other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}
