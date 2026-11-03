/// ============================================================================
/// SIMILAR PRODUCTS VIEWMODEL
/// ============================================================================
///
/// Manages similar products for a given product.
/// This is a single-responsibility ViewModel for similar products only.
///
/// ## Usage
/// ```dart
/// final similarProductsAsync = ref.watch(similarProductsProvider('P510337'));
/// similarProductsAsync.when(
///   data: (products) => ...,
///   loading: () => ...,
///   error: (e, s) => ...,
/// );
/// ```
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/similar_product_entity.dart';
import '../../domain/usecases/get_similar_products_usecase.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';

/// Provider for similar products
///
/// Fetches similar products for a given product ID.
/// Uses FutureProvider.family for parameterized queries.
final similarProductsProvider =
    FutureProvider.family<List<SimilarProductEntity>, String>((
      ref,
      productId,
    ) async {
      final remoteDataSource = ProductRemoteDataSourceImpl();
      final localDataSource = ProductLocalDataSourceImpl();
      final repository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      final useCase = GetSimilarProductsUseCase(repository);

      final result = await useCase(
        GetSimilarProductsParams(productId: productId),
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (products) => products,
      );
    });
