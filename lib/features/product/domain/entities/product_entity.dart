import 'package:equatable/equatable.dart';

/// Product entity representing cosmetic product data
class ProductEntity extends Equatable {
  final String productId;
  final String title;
  final String brandName;
  final double rating;
  final int reviews;
  final String? category;
  final String priceRange;
  final String? imageUrl;
  final String? targetUrl;
  final String? skuId;
  final double? score;

  const ProductEntity({
    required this.productId,
    required this.title,
    required this.brandName,
    required this.rating,
    required this.reviews,
    this.category,
    required this.priceRange,
    this.imageUrl,
    this.targetUrl,
    this.skuId,
    this.score,
  });

  @override
  List<Object?> get props => [
        productId,
        title,
        brandName,
        rating,
        reviews,
        category,
        priceRange,
        imageUrl,
        targetUrl,
        skuId,
        score,
      ];
}

