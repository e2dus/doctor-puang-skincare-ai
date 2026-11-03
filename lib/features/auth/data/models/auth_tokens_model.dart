import '../../domain/entities/auth_tokens_entity.dart';

/// Data model for authentication tokens
class AuthTokensModel extends AuthTokensEntity {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
  });

  /// Create model from JSON
  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    print('🔐 AuthTokensModel.fromJson: Parsing response');
    print('   Full response: $json');

    // Handle different response formats
    String? accessToken = json['access_token'] as String?;
    String? refreshToken = json['refresh_token'] as String?;

    print(
      '   Attempt 1 (snake_case): accessToken=$accessToken, refreshToken=$refreshToken',
    );

    // Try alternative field names
    accessToken ??= json['accessToken'] as String?;
    refreshToken ??= json['refreshToken'] as String?;

    print(
      '   Attempt 2 (camelCase): accessToken=$accessToken, refreshToken=$refreshToken',
    );

    // Try nested data object
    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      print('   Found data object: $data');
      accessToken ??= data['access_token'] as String?;
      refreshToken ??= data['refresh_token'] as String?;
      accessToken ??= data['accessToken'] as String?;
      refreshToken ??= data['refreshToken'] as String?;
      print(
        '   Attempt 3 (from data): accessToken=${accessToken?.substring(0, 20)}..., refreshToken=${refreshToken?.substring(0, 20)}...',
      );
    }

    // Try top-level response object
    if (json['response'] is Map<String, dynamic>) {
      final response = json['response'] as Map<String, dynamic>;
      print('   Found response object: $response');
      accessToken ??= response['access_token'] as String?;
      refreshToken ??= response['refresh_token'] as String?;
      accessToken ??= response['accessToken'] as String?;
      refreshToken ??= response['refreshToken'] as String?;
      print(
        '   Attempt 4 (from response): accessToken=${accessToken?.substring(0, 20)}..., refreshToken=${refreshToken?.substring(0, 20)}...',
      );
    }

    if (accessToken == null || refreshToken == null) {
      print(
        '❌ Missing tokens - accessToken is ${accessToken != null ? 'present' : 'NULL'}, refreshToken is ${refreshToken != null ? 'present' : 'NULL'}',
      );
      throw FormatException(
        'EMPTY_FIELD: Missing tokens in response. Response keys: ${json.keys.toList()}',
      );
    }

    print(
      '✅ Tokens parsed successfully - accessToken length: ${accessToken.length}, refreshToken length: ${refreshToken.length}',
    );

    return AuthTokensModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {'access_token': accessToken, 'refresh_token': refreshToken};
  }

  /// Create model from entity
  factory AuthTokensModel.fromEntity(AuthTokensEntity entity) {
    return AuthTokensModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
    );
  }
}
