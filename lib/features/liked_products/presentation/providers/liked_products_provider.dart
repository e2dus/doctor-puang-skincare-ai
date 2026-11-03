import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/data/datasources/liked_products_local_datasource.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/data/repositories/liked_products_repository_impl.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/repositories/liked_products_repository.dart';

/// State for liked products
class LikedProductsState {
  final List<CosmeticItemEntity> products;
  final bool isLoading;
  final String? error;

  const LikedProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  LikedProductsState copyWith({
    List<CosmeticItemEntity>? products,
    bool? isLoading,
    String? error,
  }) {
    return LikedProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing liked products (Riverpod 3.x)
class LikedProductsNotifier extends AutoDisposeNotifier<LikedProductsState> {
  LikedProductsRepository get _repository =>
      ref.read(likedProductsRepositoryProvider);

  @override
  LikedProductsState build() {
    // 초기 상태 반환 후 비동기 로딩 시작
    Future.microtask(() => _loadLikedProducts());
    return const LikedProductsState();
  }

  /// Load liked products
  Future<void> _loadLikedProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final products = await _repository.getLikedProducts();
      state = state.copyWith(products: products, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggle like status of a product
  Future<void> toggleLike(CosmeticItemEntity product) async {
    try {
      final isLiked = await _repository.isLiked(product);
      if (isLiked) {
        await _repository.unlikeProduct(product);
      } else {
        await _repository.likeProduct(product);
      }
      await _loadLikedProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add product to liked list
  Future<void> likeProduct(CosmeticItemEntity product) async {
    try {
      await _repository.likeProduct(product);
      await _loadLikedProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove product from liked list
  Future<void> unlikeProduct(CosmeticItemEntity product) async {
    try {
      await _repository.unlikeProduct(product);
      await _loadLikedProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Check if product is liked
  Future<bool> isLiked(CosmeticItemEntity product) async {
    try {
      return await _repository.isLiked(product);
    } catch (e) {
      return false;
    }
  }

  /// Clear all liked products
  Future<void> clearAll() async {
    try {
      for (final product in state.products) {
        await _repository.unlikeProduct(product);
      }
      await _loadLikedProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider for liked products data source
final likedProductsLocalDataSourceProvider =
    Provider<LikedProductsLocalDataSource>((ref) {
      return LikedProductsLocalDataSource();
    });

/// Provider for liked products repository
final likedProductsRepositoryProvider = Provider<LikedProductsRepository>((
  ref,
) {
  final dataSource = ref.watch(likedProductsLocalDataSourceProvider);
  return LikedProductsRepositoryImpl(dataSource);
});

/// Provider for liked products notifier (Riverpod 3.x)
final likedProductsNotifierProvider =
    NotifierProvider.autoDispose<LikedProductsNotifier, LikedProductsState>(
      LikedProductsNotifier.new,
    );
