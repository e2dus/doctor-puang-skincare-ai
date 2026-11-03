import 'package:equatable/equatable.dart';

/// SKU 정보 엔티티
class SkuEntity extends Equatable {
  final String skuId;
  final String productId;
  final String size;
  final String image;

  const SkuEntity({
    required this.skuId,
    required this.productId,
    required this.size,
    required this.image,
  });

  @override
  List<Object?> get props => [skuId, productId, size, image];
}

/// 상품 상세 정보 엔티티
class ProductDetailEntity extends Equatable {
  final String productId;
  final String productName;
  final String brandName;
  final double rating;
  final int lovesCount;
  final int reviews;
  final String price;
  final List<String> images;
  final String mainImage;
  final List<String> highlights;
  final List<String> ingredients;
  final String shortDescription;
  final String longDescription;
  final String targetUrl;
  final List<SkuEntity> skus;

  const ProductDetailEntity({
    required this.productId,
    required this.productName,
    required this.brandName,
    required this.rating,
    required this.lovesCount,
    required this.reviews,
    required this.price,
    required this.images,
    required this.mainImage,
    required this.highlights,
    required this.ingredients,
    required this.shortDescription,
    required this.longDescription,
    required this.targetUrl,
    required this.skus,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        brandName,
        rating,
        lovesCount,
        reviews,
        price,
        images,
        mainImage,
        highlights,
        ingredients,
        shortDescription,
        longDescription,
        targetUrl,
        skus,
      ];
}

