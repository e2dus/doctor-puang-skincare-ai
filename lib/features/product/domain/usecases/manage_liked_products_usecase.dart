import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Use case for liking a product
class LikeProductUseCase implements UseCase<void, ProductEntity> {
  final ProductRepository repository;

  LikeProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ProductEntity product) {
    return repository.likeProduct(product);
  }
}

/// Use case for unliking a product
class UnlikeProductUseCase implements UseCase<void, ProductEntity> {
  final ProductRepository repository;

  UnlikeProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ProductEntity product) {
    return repository.unlikeProduct(product);
  }
}

/// Use case for getting liked products
class GetLikedProductsUseCase implements UseCase<List<ProductEntity>, NoParams> {
  final ProductRepository repository;

  GetLikedProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams params) {
    return repository.getLikedProducts();
  }
}

