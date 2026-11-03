/// ============================================================================
/// LIKED PRODUCTS VIEWMODEL
/// ============================================================================
///
/// Manages the liked/favorite products state.
/// This is a single-responsibility ViewModel for liked products only.
///
/// ## Usage
/// ```dart
/// // Get liked items
/// final likedItems = ref.watch(likedProductsProvider);
///
/// // Toggle like
/// ref.read(likedProductsProvider.notifier).toggleLike(product);
///
/// // Check if liked
/// final isLiked = ref.read(likedProductsProvider.notifier).isLiked(product);
/// ```
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_entity.dart';
import '../../../liked_products/data/mappers/cosmetic_item_mapper.dart';
import '../../../liked_products/presentation/providers/liked_products_provider.dart';

/// Notifier for liked products state
class LikedProductsNotifier extends Notifier<List<ProductEntity>> {
  @override
  List<ProductEntity> build() {
    // likedProductsNotifierProvider를 watch하여 자동으로 동기화
    final notifierState = ref.watch(likedProductsNotifierProvider);
    
    // CosmeticItemEntity를 ProductEntity로 변환
    final productEntities = notifierState.products
        .map((entity) => entity.toProductEntity())
        .toList();
    
    return productEntities;
  }

  /// Add product to liked list
  void likeProduct(ProductEntity item) {
    if (!isLiked(item)) {
      state = [...state, item];
      print('Adding item to liked products: ${item.title}');
      print(item.imageUrl);

      // likedProductsNotifierProvider도 함께 업데이트
      final cosmeticEntity = CosmeticItemMapper.fromProductEntity(item);
      ref
          .read(likedProductsNotifierProvider.notifier)
          .likeProduct(cosmeticEntity);
    }
  }

  /// Remove product from liked list
  void unlikeProduct(ProductEntity item) {
    state = state.where((i) => i.title != item.title).toList();

    // likedProductsNotifierProvider도 함께 업데이트
    final cosmeticEntity = CosmeticItemMapper.fromProductEntity(item);
    ref
        .read(likedProductsNotifierProvider.notifier)
        .unlikeProduct(cosmeticEntity);
  }

  /// Check if product is liked
  bool isLiked(ProductEntity item) {
    return state.any((i) => i.title == item.title);
  }

  /// Toggle like status
  void toggleLike(ProductEntity item) {
    if (isLiked(item)) {
      unlikeProduct(item);
    } else {
      likeProduct(item);
    }
  }

  /// Get count of liked products
  int get likedCount => state.length;
}

/// Provider for liked products
final likedProductsProvider =
    NotifierProvider<LikedProductsNotifier, List<ProductEntity>>(() {
      return LikedProductsNotifier();
    });
