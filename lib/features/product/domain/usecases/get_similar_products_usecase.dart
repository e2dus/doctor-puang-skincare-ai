import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/similar_product_entity.dart';
import '../repositories/product_repository.dart';

/// Use case for getting similar products
class GetSimilarProductsUseCase
    implements UseCase<List<SimilarProductEntity>, GetSimilarProductsParams> {
  final ProductRepository repository;

  GetSimilarProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SimilarProductEntity>>> call(
    GetSimilarProductsParams params,
  ) {
    return repository.getSimilarProducts(productId: params.productId);
  }
}

/// Parameters for get similar products use case
class GetSimilarProductsParams extends Equatable {
  final String productId;

  const GetSimilarProductsParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}
