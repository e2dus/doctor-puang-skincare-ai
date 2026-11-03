import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/product_model.dart';
import '../models/product_detail_model.dart';
import '../models/category_model.dart';
import '../models/similar_product_model.dart';

/// Remote data source for product operations
abstract class ProductRemoteDataSource {
  /// Fetch product categories from the server
  Future<List<CategoryModel>> fetchCategories();

  /// Fetch ranking products from the server
  /// [topN] - Number of top products to fetch (default: 100)
  /// [category] - Optional category filter (e.g., "Skincare")
  Future<List<ProductModel>> fetchRankingProducts({
    int topN = 100,
    String? category,
  });

  /// Fetch product detail information
  /// [productId] - Product ID (e.g., "P510337")
  /// [preferredSku] - Preferred SKU ID (e.g., "2758951")
  Future<ProductDetailModel> fetchProductDetail({
    required String productId,
    required String preferredSku,
  });

  /// Fetch similar products for a product
  /// [productId] - Product ID (e.g., "P510337")
  Future<List<SimilarProductModel>> fetchSimilarProducts({
    required String productId,
  });
}

/// Implementation of ProductRemoteDataSource
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.productsCategoriesEndpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> categories = data['primary_categories'] ?? [];
        return categories.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        throw ServerException('Failed to load categories', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load categories',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<ProductModel>> fetchRankingProducts({
    int topN = 100,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{'top_n': topN};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _dio.get(
        ApiConstants.productsRankingEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> ranking = data['ranking'] ?? [];
        return ranking.map((item) => ProductModel.fromJson(item)).toList();
      } else {
        throw ServerException('Failed to load products', response.statusCode);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load products',
        e.response?.statusCode,
      );
    }
  }

  @override
  Future<ProductDetailModel> fetchProductDetail({
    required String productId,
    required String preferredSku,
  }) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.productsDetailEndpoint}';
    // API 서버는 실제로 'preferedSku' (e가 하나)를 기대함
    // curl 예시: ...?productId=P510337&preferedSku=2758951
    final queryParams = {'productId': productId, 'preferedSku': preferredSku};

    print('🌐 [ProductRemoteDataSource] fetchProductDetail 시작');
    print('  Base URL: ${ApiConstants.baseUrl}');
    print('  Endpoint: ${ApiConstants.productsDetailEndpoint}');
    print('  Full URL: $url');
    print('  Query Params: $queryParams');
    print('  productId: $productId');
    print('  preferredSku: $preferredSku');

    try {
      print('  ⏳ API 요청 전송 중...');
      final response = await _dio.get(
        ApiConstants.productsDetailEndpoint,
        queryParameters: queryParams,
      );

      print('  ✅ API 응답 받음');
      print('    Status Code: ${response.statusCode}');
      print('    Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        print('    ⏳ JSON 파싱 중...');
        final productDetail = ProductDetailModel.fromJson(response.data);
        print('    ✅ JSON 파싱 완료');
        print('      Product ID: ${productDetail.productId}');
        print('      Product Name: ${productDetail.productName}');
        print('      Main Image: ${productDetail.mainImage}');
        print('      Images Count: ${productDetail.images.length}');
        return productDetail;
      } else {
        print('    ❌ 실패: Status Code ${response.statusCode}');
        throw ServerException(
          'Failed to load product detail',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('  ❌ [DioException] 발생');
      print('    Error Type: ${e.type}');
      print('    Error Message: ${e.message}');
      print('    Request URI: ${e.requestOptions.uri}');
      if (e.response != null) {
        print('    Response Status Code: ${e.response?.statusCode}');
        print('    Response Data: ${e.response?.data}');
      }
      throw ServerException(
        e.message ?? 'Failed to load product detail',
        e.response?.statusCode,
      );
    } catch (e, stackTrace) {
      print('  ❌ [Unexpected Exception] 발생');
      print('    Error: $e');
      print('    Stack Trace: $stackTrace');
      throw ServerException('Unexpected error: ${e.toString()}', null);
    }
  }

  @override
  Future<List<SimilarProductModel>> fetchSimilarProducts({
    required String productId,
  }) async {
    try {
      final endpoint =
          '${ApiConstants.productsSimilarEndpoint}/$productId/similar';
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> similarProducts = data['similar_products'] ?? [];
        return similarProducts
            .map((item) => SimilarProductModel.fromJson(item))
            .toList();
      } else {
        throw ServerException(
          'Failed to load similar products',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Failed to load similar products',
        e.response?.statusCode,
      );
    }
  }
}
