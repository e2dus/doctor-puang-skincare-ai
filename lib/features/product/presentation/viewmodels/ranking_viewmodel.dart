/// ============================================================================
/// RANKING VIEWMODEL
/// ============================================================================
///
/// Manages the product ranking list from the server.
/// This is a single-responsibility ViewModel for ranking products only.
///
/// ## Usage
/// ```dart
/// final rankingAsync = ref.watch(rankingProductsProvider);
/// rankingAsync.when(
///   data: (products) => ...,
///   loading: () => ...,
///   error: (e, s) => ...,
/// );
/// ```
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_ranking_products_usecase.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';

/// Provider for ranking products
///
/// Fetches top 100 products from the server.
/// Supports optional category filtering.
///
/// ## Usage
/// ```dart
/// // All products
/// final rankingAsync = ref.watch(rankingProductsProvider(null));
///
/// // Filtered by category
/// final rankingAsync = ref.watch(rankingProductsProvider('Skincare'));
/// ```
final rankingProductsProvider =
    FutureProvider.family<List<ProductEntity>, String?>((ref, category) async {
      final remoteDataSource = ProductRemoteDataSourceImpl();
      final localDataSource = ProductLocalDataSourceImpl();
      final repository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      final useCase = GetRankingProductsUseCase(repository);

      final result = await useCase(
        GetRankingProductsParams(topN: 100, category: category),
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (products) => products,
      );
    });
