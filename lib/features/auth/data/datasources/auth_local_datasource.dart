import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/error/exceptions.dart';
import '../models/auth_tokens_model.dart';

/// Local data source for authentication (secure storage)
abstract class AuthLocalDataSource {
  /// Save authentication tokens
  Future<void> saveTokens(AuthTokensModel tokens);

  /// Get stored tokens
  Future<AuthTokensModel?> getTokens();

  /// Clear stored tokens
  Future<void> clearTokens();

  /// Check if tokens exist
  Future<bool> hasTokens();

  /// Save user email
  Future<void> saveEmail(String email);

  /// Get stored user email
  Future<String?> getEmail();
}

/// Implementation of AuthLocalDataSource using FlutterSecureStorage
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _emailKey = 'user_email';

  AuthLocalDataSourceImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveTokens(AuthTokensModel tokens) async {
    try {
      print('💾 AuthLocalDataSource.saveTokens:');
      print('   accessToken length: ${tokens.accessToken.length}');
      print('   refreshToken length: ${tokens.refreshToken.length}');

      await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
      print('   ✅ accessToken saved');

      await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
      print('   ✅ refreshToken saved');

      // Verify tokens were saved
      final savedAccessToken = await _storage.read(key: _accessTokenKey);
      final savedRefreshToken = await _storage.read(key: _refreshTokenKey);

      print('   Verification:');
      print(
        '     accessToken saved: ${savedAccessToken != null && savedAccessToken.isNotEmpty}',
      );
      print(
        '     refreshToken saved: ${savedRefreshToken != null && savedRefreshToken.isNotEmpty}',
      );
    } catch (e) {
      print('❌ saveTokens error: $e');
      throw CacheException('Failed to save tokens: $e');
    }
  }

  @override
  Future<AuthTokensModel?> getTokens() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (accessToken != null && refreshToken != null) {
        return AuthTokensModel(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get tokens: $e');
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      throw CacheException('Failed to clear tokens: $e');
    }
  }

  @override
  Future<bool> hasTokens() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      return refreshToken != null && refreshToken.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveEmail(String email) async {
    try {
      await _storage.write(key: _emailKey, value: email);
    } catch (e) {
      throw CacheException('Failed to save email: $e');
    }
  }

  @override
  Future<String?> getEmail() async {
    try {
      return await _storage.read(key: _emailKey);
    } catch (e) {
      throw CacheException('Failed to get email: $e');
    }
  }
}
