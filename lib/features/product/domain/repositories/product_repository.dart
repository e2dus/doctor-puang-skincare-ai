import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../entities/product_detail_entity.dart';
import '../entities/category_entity.dart';
import '../entities/similar_product_entity.dart';

/// Abstract repository for product operations
abstract class ProductRepository {
  /// Fetch product categories from the server
  Future<Either<Failure, List<CategoryEntity>>> fetchCategories();

  /// Fetch ranking products from the server
  /// [topN] - Number of top products to fetch (default: 100)
  /// [category] - Optional category filter (e.g., "Skincare")
  Future<Either<Failure, List<ProductEntity>>> fetchRankingProducts({
    int topN = 100,
    String? category,
  });

  /// Get product detail information
  Future<Either<Failure, ProductDetailEntity>> getProductDetail({
    required String productId,
    required String preferredSku,
  });

  /// Fetch similar products for a product
  /// [productId] - Product ID (e.g., "P510337")
  Future<Either<Failure, List<SimilarProductEntity>>> getSimilarProducts({
    required String productId,
  });

  /// Get liked products from local storage
  Future<Either<Failure, List<ProductEntity>>> getLikedProducts();

  /// Add a product to liked list
  Future<Either<Failure, void>> likeProduct(ProductEntity product);

  /// Remove a product from liked list
  Future<Either<Failure, void>> unlikeProduct(ProductEntity product);

  /// Get cart products
  Future<Either<Failure, List<ProductEntity>>> getCartProducts();

  /// Add a product to cart
  Future<Either<Failure, void>> addToCart(ProductEntity product);

  /// Remove a product from cart
  Future<Either<Failure, void>> removeFromCart(String title);

  /// Clear cart
  Future<Either<Failure, void>> clearCart();

  /// Get blocked products
  Future<Either<Failure, List<ProductEntity>>> getBlockedProducts();

  /// Block a product
  Future<Either<Failure, void>> blockProduct(ProductEntity product);

  /// Unblock a product
  Future<Either<Failure, void>> unblockProduct(ProductEntity product);

  /// Get no-recommend products
  Future<Either<Failure, List<ProductEntity>>> getNoRecommendProducts();

  /// Add a product to no-recommend list
  Future<Either<Failure, void>> addNoRecommend(ProductEntity product);

  /// Remove a product from no-recommend list
  Future<Either<Failure, void>> removeNoRecommend(ProductEntity product);
}
