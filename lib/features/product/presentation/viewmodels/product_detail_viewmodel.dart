/// ============================================================================
/// PRODUCT DETAIL VIEWMODEL
/// ============================================================================
///
/// Manages the product detail information from the server.
/// This is a single-responsibility ViewModel for product detail only.
///
/// ## Usage
/// ```dart
/// final productDetailAsync = ref.watch(productDetailProvider('P510337|2758951'));
/// productDetailAsync.when(
///   data: (detail) => ...,
///   loading: () => ...,
///   error: (e, s) => ...,
/// );
/// ```
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_detail_entity.dart';
import '../../domain/usecases/get_product_detail_usecase.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';

/// Provider for product detail
///
/// Fetches product detail information from the server.
/// Parameters: productId (String), preferredSku (String)
///
/// Uses a composite key (productId|preferredSku) for proper caching.
/// Uses '|' as separator to avoid conflicts with productId/skuId containing '_'.
final productDetailProvider =
    FutureProvider.family<ProductDetailEntity, String>((ref, key) async {
      print('📦 [productDetailProvider] 시작');
      print('  Key: $key');

      // Parse key: "productId|preferredSku"
      final parts = key.split('|');
      print('  Parsed parts: $parts (length: ${parts.length})');

      if (parts.length != 2) {
        print('  ❌ Invalid key format');
        throw Exception(
          'Invalid key format. Expected: "productId|preferredSku"',
        );
      }

      final productId = parts[0];
      final preferredSku = parts[1];
      print('  productId: $productId');
      print('  preferredSku: $preferredSku');

      if (productId.isEmpty || preferredSku.isEmpty) {
        print('  ❌ Empty productId or preferredSku');
        throw Exception('productId and preferredSku are required');
      }

      print('  ⏳ 데이터 소스 및 레포지토리 생성 중...');
      final remoteDataSource = ProductRemoteDataSourceImpl();
      final localDataSource = ProductLocalDataSourceImpl();
      final repository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      final useCase = GetProductDetailUseCase(repository);
      print('  ✅ 데이터 소스 및 레포지토리 생성 완료');

      print('  ⏳ UseCase 실행 중...');
      final result = await useCase(
        GetProductDetailParams(
          productId: productId,
          preferredSku: preferredSku,
        ),
      );
      print('  ✅ UseCase 실행 완료');

      return result.fold(
        (failure) {
          print('  ❌ UseCase 실패: ${failure.message}');
          throw Exception(failure.message);
        },
        (productDetail) {
          print('  ✅ UseCase 성공: ${productDetail.productName}');
          return productDetail;
        },
      );
    });
