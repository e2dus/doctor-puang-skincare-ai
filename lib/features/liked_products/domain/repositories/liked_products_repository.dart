import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';

/// Repository interface for liked products
abstract class LikedProductsRepository {
  /// Get all liked products
  Future<List<CosmeticItemEntity>> getLikedProducts();

  /// Add a product to liked list
  Future<void> likeProduct(CosmeticItemEntity product);

  /// Remove a product from liked list
  Future<void> unlikeProduct(CosmeticItemEntity product);

  /// Check if a product is liked
  Future<bool> isLiked(CosmeticItemEntity product);
}

