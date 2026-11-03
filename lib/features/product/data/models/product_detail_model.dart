import '../../domain/entities/product_detail_entity.dart';

/// SKU 정보 모델
class SkuModel extends SkuEntity {
  const SkuModel({
    required super.skuId,
    required super.productId,
    required super.size,
    required super.image,
  });

  factory SkuModel.fromJson(Map<String, dynamic> json) {
    return SkuModel(
      skuId: json['skuId'] ?? '',
      productId: json['productId'] ?? '',
      size: json['size'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skuId': skuId,
      'productId': productId,
      'size': size,
      'image': image,
    };
  }
}

/// 상품 상세 정보 모델
class ProductDetailModel extends ProductDetailEntity {
  const ProductDetailModel({
    required super.productId,
    required super.productName,
    required super.brandName,
    required super.rating,
    required super.lovesCount,
    required super.reviews,
    required super.price,
    required super.images,
    required super.mainImage,
    required super.highlights,
    required super.ingredients,
    required super.shortDescription,
    required super.longDescription,
    required super.targetUrl,
    required super.skus,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;

    // target_url 로그 출력
    final targetUrl = product['target_url'] ?? '';
    print('📦 ProductDetailModel.fromJson:');
    print('  target_url (raw): ${product['target_url']}');
    print('  target_url (parsed): $targetUrl');
    print('  target_url isEmpty: ${targetUrl.isEmpty}');
    print('  target_url length: ${targetUrl.length}');

    return ProductDetailModel(
      productId: product['product_id'] ?? '',
      productName: product['product_name'] ?? '',
      brandName: product['brand_name'] ?? '',
      rating: (product['rating'] ?? 0).toDouble(),
      lovesCount: product['loves_count'] ?? 0,
      reviews: product['reviews'] ?? 0,
      price: product['price'] ?? '',
      images:
          (product['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mainImage: product['main_image'] ?? '',
      highlights:
          (product['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ingredients:
          (product['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      shortDescription: product['short_description'] ?? '',
      longDescription: product['long_description'] ?? '',
      targetUrl: targetUrl,
      skus:
          (product['skus'] as List<dynamic>?)
              ?.map((e) => SkuModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': {
        'product_id': productId,
        'product_name': productName,
        'brand_name': brandName,
        'rating': rating,
        'loves_count': lovesCount,
        'reviews': reviews,
        'price': price,
        'images': images,
        'main_image': mainImage,
        'highlights': highlights,
        'ingredients': ingredients,
        'short_description': shortDescription,
        'long_description': longDescription,
        'target_url': targetUrl,
        'skus': skus.map((sku) => (sku as SkuModel).toJson()).toList(),
      },
    };
  }
}
