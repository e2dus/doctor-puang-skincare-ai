/// ============================================================================
/// EXCEPTIONS
/// ============================================================================
/// 
/// Exception classes for error handling in data layer.
/// Exceptions are thrown in data sources and caught in repositories.
/// 
/// ## Flow
/// 1. DataSource throws Exception
/// 2. Repository catches Exception
/// 3. Repository returns Failure (Either.Left)
/// 
/// ## Example
/// ```dart
/// // In data source:
/// throw ServerException('API returned 500', 500);
/// 
/// // In repository:
/// try {
///   return Right(await dataSource.fetch());
/// } on ServerException catch (e) {
///   return Left(ServerFailure(e.message));
/// }
/// ```
/// ============================================================================

/// Base exception for all app exceptions
class AppException implements Exception {
  /// Human-readable error message
  final String message;

  const AppException([this.message = 'An error occurred']);

  @override
  String toString() => message;
}

/// Server/API exception
/// 
/// Thrown when API returns error status code.
class ServerException extends AppException {
  /// HTTP status code (if available)
  final int? statusCode;

  const ServerException([
    String message = 'Server error occurred',
    this.statusCode,
  ]) : super(message);
}

/// Cache/storage exception
/// 
/// Thrown when local storage operations fail.
class CacheException extends AppException {
  const CacheException([String message = 'Cache error occurred']) : super(message);
}

/// Network exception
/// 
/// Thrown when network is unavailable or request times out.
class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection']) : super(message);
}

/// Authentication exception
/// 
/// Thrown when authentication fails or token is invalid.
class AuthException extends AppException {
  const AuthException([String message = 'Authentication failed']) : super(message);
}
