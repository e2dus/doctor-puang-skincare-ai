import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// API Client for making HTTP requests
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  ApiClient({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers = {'Content-Type': 'application/json'};

    // Interceptor 추가
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 요청 전 토큰 추가
          final accessToken = await _storage.read(key: 'access_token');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // 401 에러이고 아직 토큰 새로고침 중이 아니면
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              // RefreshToken으로 새 AccessToken 받기
              final refreshToken = await _storage.read(key: 'refresh_token');
              if (refreshToken != null) {
                final response = await _refreshAccessToken(refreshToken);

                // 새 토큰 저장
                await _storage.write(
                  key: 'access_token',
                  value: response.data['accessToken'],
                );

                // 원래 요청 재시도
                final options = error.requestOptions;
                options.headers['Authorization'] =
                    'Bearer ${response.data['accessToken']}';

                _isRefreshing = false;
                return handler.resolve(
                  await _dio.request(
                    options.path,
                    options: Options(
                      method: options.method,
                      headers: options.headers,
                    ),
                    data: options.data,
                    queryParameters: options.queryParameters,
                  ),
                );
              }
            } catch (e) {
              _isRefreshing = false;
              // RefreshToken도 실패하면 로그인 화면으로
              return handler.reject(error);
            }
          }

          _isRefreshing = false;
          return handler.next(error);
        },
      ),
    );
  }

  /// RefreshToken을 사용해 새로운 AccessToken 받기
  Future<Response> _refreshAccessToken(String refreshToken) async {
    return await _dio.post(
      ApiConstants.refreshTokenEndpoint,
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  /// Add authentication header to requests
  Future<void> _addAuthHeader() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) async {
    try {
      if (requiresAuth) await _addAuthHeader();
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    bool requiresAuth = false,
  }) async {
    try {
      if (requiresAuth) await _addAuthHeader();
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    bool requiresAuth = false,
  }) async {
    try {
      if (requiresAuth) await _addAuthHeader();
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(String path, {bool requiresAuth = false}) async {
    try {
      if (requiresAuth) await _addAuthHeader();
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to app exceptions
  AppException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timeout');
      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error';
        if (statusCode == 401) {
          return AuthException(message);
        }
        return ServerException(message, statusCode);
      default:
        return ServerException(e.message ?? 'Unknown error');
    }
  }
}
