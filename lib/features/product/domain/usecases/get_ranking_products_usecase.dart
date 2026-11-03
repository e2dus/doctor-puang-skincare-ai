import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Use case for getting ranking products
class GetRankingProductsUseCase
    implements UseCase<List<ProductEntity>, GetRankingProductsParams> {
  final ProductRepository repository;

  GetRankingProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(
    GetRankingProductsParams params,
  ) {
    return repository.fetchRankingProducts(
      topN: params.topN,
      category: params.category,
    );
  }
}

/// Parameters for get ranking products use case
class GetRankingProductsParams extends Equatable {
  final int topN;
  final String? category;

  const GetRankingProductsParams({this.topN = 100, this.category});

  @override
  List<Object?> get props => [topN, category];
}
