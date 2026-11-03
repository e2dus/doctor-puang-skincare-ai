import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/repositories/liked_products_repository.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/data/datasources/liked_products_local_datasource.dart';

/// Implementation of LikedProductsRepository
class LikedProductsRepositoryImpl implements LikedProductsRepository {
  final LikedProductsLocalDataSource _localDataSource;

  LikedProductsRepositoryImpl(this._localDataSource);

  @override
  Future<List<CosmeticItemEntity>> getLikedProducts() async {
    return await _localDataSource.getLikedProducts();
  }

  @override
  Future<void> likeProduct(CosmeticItemEntity product) async {
    await _localDataSource.saveLikedProduct(product);
  }

  @override
  Future<void> unlikeProduct(CosmeticItemEntity product) async {
    await _localDataSource.removeLikedProduct(product);
  }

  @override
  Future<bool> isLiked(CosmeticItemEntity product) async {
    return await _localDataSource.isLiked(product);
  }
}

