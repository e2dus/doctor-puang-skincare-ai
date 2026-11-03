import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Use case for blocking a product
class BlockProductUseCase implements UseCase<void, ProductEntity> {
  final ProductRepository repository;

  BlockProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ProductEntity product) {
    return repository.blockProduct(product);
  }
}

/// Use case for unblocking a product
class UnblockProductUseCase implements UseCase<void, ProductEntity> {
  final ProductRepository repository;

  UnblockProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ProductEntity product) {
    return repository.unblockProduct(product);
  }
}

/// Use case for getting blocked products
class GetBlockedProductsUseCase implements UseCase<List<ProductEntity>, NoParams> {
  final ProductRepository repository;

  GetBlockedProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams params) {
    return repository.getBlockedProducts();
  }
}

