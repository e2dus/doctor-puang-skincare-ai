import 'package:equatable/equatable.dart';

/// Similar product entity representing a product similar to another product
class SimilarProductEntity extends Equatable {
  final String productId;
  final String productName;
  final String brandName;
  final double rating;
  final int reviews;
  final String? primaryCategory;
  final String? secondaryCategory;
  final String? tertiaryCategory;
  final String price;
  final String? imageUrl;
  final String? targetUrl;
  final String? skuId; // SKU ID (image_url 또는 target_url에서 추출 가능)
  final double similarityScore;

  const SimilarProductEntity({
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.rating,
    required this.reviews,
    this.primaryCategory,
    this.secondaryCategory,
    this.tertiaryCategory,
    required this.price,
    this.imageUrl,
    this.targetUrl,
    this.skuId,
    required this.similarityScore,
  });

  @override
  List<Object?> get props => [
    productId,
    productName,
    brandName,
    rating,
    reviews,
    primaryCategory,
    secondaryCategory,
    tertiaryCategory,
    price,
    imageUrl,
    targetUrl,
    skuId,
    similarityScore,
  ];
}
