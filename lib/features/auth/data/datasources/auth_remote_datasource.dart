import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_tokens_model.dart';

/// Remote data source for authentication
abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  Future<AuthTokensModel> signIn({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<AuthTokensModel> signUp({
    required String email,
    required String password,
    String? username,
  });

  /// Refresh access token using refresh token
  Future<AuthTokensModel> refreshToken({required String refreshToken});
}

/// Implementation of AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  @override
  Future<AuthTokensModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 SignIn: Attempting login with email=$email');

      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      print('🔐 SignIn: Response status=${response.statusCode}');
      print('🔐 SignIn: Response data=${response.data}');

      if (response.statusCode == 200) {
        return AuthTokensModel.fromJson(response.data);
      } else {
        throw ServerException('Login failed', response.statusCode);
      }
    } on DioException catch (e) {
      print('❌ SignIn DioException: ${e.message}');
      print('❌ SignIn Status Code: ${e.response?.statusCode}');
      print('❌ SignIn Response Data: ${e.response?.data}');

      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        throw ServerException('INVALID_PASSWORD', e.response?.statusCode);
      }
      throw ServerException(
        e.message ?? 'Server error',
        e.response?.statusCode,
      );
    } on FormatException catch (e) {
      print('❌ SignIn FormatException: ${e.message}');
      throw ServerException('Unknown Type: ${e.message}', null);
    } catch (e) {
      print('❌ SignIn Exception: $e');
      throw ServerException('Unknown error: $e', null);
    }
  }

  @override
  Future<AuthTokensModel> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      print('📝 SignUp: Attempting signup with email=$email');

      final response = await _dio.post(
        ApiConstants.signUpEndpoint,
        data: {
          'email': email,
          'password': password,
          if (username != null) 'username': username,
        },
      );

      print('📝 SignUp: Response status=${response.statusCode}');
      print('📝 SignUp: Response data=${response.data}');

      // 201 Created: 회원가입 성공하지만 토큰 없음 → 더미 토큰 반환 (로그인 페이지로 이동용)
      if (response.statusCode == 201) {
        print(
          '📝 SignUp: Registration successful (201). No tokens returned by API.',
        );
        // 더미 토큰 반환 - 실제 로그인은 로그인 페이지에서 수행
        return AuthTokensModel(
          accessToken:
              'signup_success_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken:
              'signup_success_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (response.statusCode == 200) {
        return AuthTokensModel.fromJson(response.data);
      } else {
        throw ServerException('Sign up failed', response.statusCode);
      }
    } on DioException catch (e) {
      print('❌ SignUp DioException: ${e.message}');
      print('❌ SignUp Status Code: ${e.response?.statusCode}');
      print('❌ SignUp Response Data: ${e.response?.data}');

      // Handle specific error codes
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 409) {
        throw ServerException('USER_EXISTS', 409);
      } else if (statusCode == 400) {
        if (responseData is Map && responseData.containsKey('error_code')) {
          throw ServerException(responseData['error_code'], 400);
        }
        throw ServerException('EMPTY_FIELD', 400);
      } else if (statusCode == 500) {
        throw ServerException('SERVER_ERROR', 500);
      }

      throw ServerException(
        e.message ?? 'Server error',
        e.response?.statusCode,
      );
    } on FormatException catch (e) {
      print('❌ SignUp FormatException: ${e.message}');
      // FormatException 메시지에서 에러 코드 추출
      if (e.message.contains('EMPTY_FIELD')) {
        throw ServerException('EMPTY_FIELD', null);
      }
      throw ServerException(e.message, null);
    } catch (e) {
      print('❌ SignUp Exception: $e');
      throw ServerException('Unknown error: $e', null);
    }
  }

  @override
  Future<AuthTokensModel> refreshToken({required String refreshToken}) async {
    try {
      print('🔐 RefreshToken: Attempting to refresh token');

      final response = await _dio.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refreshToken': refreshToken},
      );

      print('🔐 RefreshToken: Response status = ${response.statusCode}');
      print('🔐 RefreshToken: Response data = ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final tokens = AuthTokensModel.fromJson(response.data);
        print(
          '✅ RefreshToken Success: accessToken length = ${tokens.accessToken.length}',
        );
        return tokens;
      }

      throw ServerException(
        'Invalid response from server',
        response.statusCode,
      );
    } on DioException catch (e) {
      print('❌ RefreshToken DioException: ${e.message}');
      print('  Status Code: ${e.response?.statusCode}');
      print('  Response: ${e.response?.data}');

      // 401 Unauthorized인 경우 토큰이 만료됨
      if (e.response?.statusCode == 401) {
        throw AuthException('Token expired or invalid');
      }

      throw ServerException(
        e.message ?? 'Network error',
        e.response?.statusCode,
      );
    } catch (e) {
      print('❌ RefreshToken Exception: $e');
      throw ServerException('Unknown error: $e', null);
    }
  }
}
