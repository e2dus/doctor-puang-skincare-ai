import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Use case for adding product to cart
class AddToCartUseCase implements UseCase<void, ProductEntity> {
  final ProductRepository repository;

  AddToCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ProductEntity product) {
    return repository.addToCart(product);
  }
}

/// Use case for removing product from cart
class RemoveFromCartUseCase implements UseCase<void, String> {
  final ProductRepository repository;

  RemoveFromCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String title) {
    return repository.removeFromCart(title);
  }
}

/// Use case for getting cart products
class GetCartProductsUseCase implements UseCase<List<ProductEntity>, NoParams> {
  final ProductRepository repository;

  GetCartProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(NoParams params) {
    return repository.getCartProducts();
  }
}

/// Use case for clearing cart
class ClearCartUseCase implements UseCase<void, NoParams> {
  final ProductRepository repository;

  ClearCartUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.clearCart();
  }
}

