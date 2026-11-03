/// ============================================================================
/// CATEGORY VIEWMODEL
/// ============================================================================
///
/// Manages the product categories from the server.
/// This is a single-responsibility ViewModel for categories only.
///
/// ## Usage
/// ```dart
/// final categoriesAsync = ref.watch(categoriesProvider);
/// categoriesAsync.when(
///   data: (categories) => ...,
///   loading: () => ...,
///   error: (e, s) => ...,
/// );
/// ```
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';

/// Provider for product categories
///
/// Fetches categories from the server.
/// Auto-refreshes when invalidated.
final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final remoteDataSource = ProductRemoteDataSourceImpl();
  final localDataSource = ProductLocalDataSourceImpl();
  final repository = ProductRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );

  final result = await repository.fetchCategories();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});
