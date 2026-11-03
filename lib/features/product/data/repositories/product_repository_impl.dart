import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_detail_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/similar_product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

/// Implementation of ProductRepository
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<CategoryEntity>>> fetchCategories() async {
    try {
      final categories = await remoteDataSource.fetchCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> fetchRankingProducts({
    int topN = 100,
    String? category,
  }) async {
    try {
      final products = await remoteDataSource.fetchRankingProducts(
        topN: topN,
        category: category,
      );
      return Right(products);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getLikedProducts() async {
    try {
      final products = localDataSource.getLikedProducts();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> likeProduct(ProductEntity product) async {
    try {
      localDataSource.likeProduct(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unlikeProduct(ProductEntity product) async {
    try {
      localDataSource.unlikeProduct(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getCartProducts() async {
    try {
      final products = localDataSource.getCartProducts();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addToCart(ProductEntity product) async {
    try {
      localDataSource.addToCart(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromCart(String title) async {
    try {
      localDataSource.removeFromCart(title);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCart() async {
    try {
      localDataSource.clearCart();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getBlockedProducts() async {
    try {
      final products = localDataSource.getBlockedProducts();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> blockProduct(ProductEntity product) async {
    try {
      localDataSource.blockProduct(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unblockProduct(ProductEntity product) async {
    try {
      localDataSource.unblockProduct(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getNoRecommendProducts() async {
    try {
      final products = localDataSource.getNoRecommendProducts();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addNoRecommend(ProductEntity product) async {
    try {
      localDataSource.addNoRecommend(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeNoRecommend(ProductEntity product) async {
    try {
      localDataSource.removeNoRecommend(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductDetailEntity>> getProductDetail({
    required String productId,
    required String preferredSku,
  }) async {
    try {
      final productDetail = await remoteDataSource.fetchProductDetail(
        productId: productId,
        preferredSku: preferredSku,
      );
      return Right(productDetail);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SimilarProductEntity>>> getSimilarProducts({
    required String productId,
  }) async {
    try {
      final similarProducts = await remoteDataSource.fetchSimilarProducts(
        productId: productId,
      );
      return Right(similarProducts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
