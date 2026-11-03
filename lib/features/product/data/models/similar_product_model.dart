import '../../domain/entities/similar_product_entity.dart';

/// Data model for similar product
class SimilarProductModel extends SimilarProductEntity {
  const SimilarProductModel({
    required super.productId,
    required super.productName,
    required super.brandName,
    required super.rating,
    required super.reviews,
    super.primaryCategory,
    super.secondaryCategory,
    super.tertiaryCategory,
    required super.price,
    super.imageUrl,
    super.targetUrl,
    super.skuId,
    required super.similarityScore,
  });

  /// Create model from JSON
  factory SimilarProductModel.fromJson(Map<String, dynamic> json) {
    // SKU ID 추출: target_url 또는 image_url에서 추출 시도
    String? skuId = json['skuId'] as String?;

    // target_url에서 skuId 추출 시도
    if (skuId == null || skuId.isEmpty) {
      final targetUrl = json['target_url'] as String?;
      if (targetUrl != null && targetUrl.isNotEmpty) {
        final skuIdMatch = RegExp(r'skuId=(\d+)').firstMatch(targetUrl);
        if (skuIdMatch != null) {
          skuId = skuIdMatch.group(1);
        }
      }
    }

    // image_url에서 SKU ID 추출 시도 (예: s2759082-main-zoom.jpg)
    if (skuId == null || skuId.isEmpty) {
      final imageUrl = json['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final skuMatch = RegExp(r'/sku/s(\d+)-').firstMatch(imageUrl);
        if (skuMatch != null) {
          skuId = skuMatch.group(1);
        }
      }
    }

    return SimilarProductModel(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      brandName: json['brand_name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviews: json['reviews'] ?? 0,
      primaryCategory: json['primary_category'],
      secondaryCategory: json['secondary_category'],
      tertiaryCategory: json['tertiary_category'],
      price: json['price'] ?? '',
      imageUrl: json['image_url'],
      targetUrl: json['target_url'],
      skuId: skuId,
      similarityScore: (json['similarity_score'] ?? 0).toDouble(),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'brand_name': brandName,
      'rating': rating,
      'reviews': reviews,
      'primary_category': primaryCategory,
      'secondary_category': secondaryCategory,
      'tertiary_category': tertiaryCategory,
      'price': price,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'skuId': skuId,
      'similarity_score': similarityScore,
    };
  }
}
