import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_detail_entity.dart';
import '../repositories/product_repository.dart';

/// Use case for fetching product detail information
class GetProductDetailUseCase implements UseCase<ProductDetailEntity, GetProductDetailParams> {
  final ProductRepository repository;

  GetProductDetailUseCase(this.repository);

  @override
  Future<Either<Failure, ProductDetailEntity>> call(GetProductDetailParams params) async {
    return await repository.getProductDetail(
      productId: params.productId,
      preferredSku: params.preferredSku,
    );
  }
}

/// Parameters for GetProductDetailUseCase
class GetProductDetailParams {
  final String productId;
  final String preferredSku;

  GetProductDetailParams({
    required this.productId,
    required this.preferredSku,
  });
}

