/// ============================================================================
/// FAILURES
/// ============================================================================
/// 
/// Failure classes for error handling in Clean Architecture.
/// Failures represent expected error conditions (not exceptions).
/// 
/// ## Usage Pattern
/// ```dart
/// Future<Either<Failure, Data>> getData() async {
///   try {
///     final data = await remote.fetch();
///     return Right(data);
///   } on ServerException catch (e) {
///     return Left(ServerFailure(e.message));
///   }
/// }
/// ```
/// 
/// ## When to Use Each Type
/// - ServerFailure: API errors, HTTP errors
/// - CacheFailure: Local storage errors
/// - NetworkFailure: No internet, timeout
/// - AuthFailure: Login failed, token expired
/// - ValidationFailure: Invalid input
/// ============================================================================

import 'package:equatable/equatable.dart';

/// Base failure class
/// 
/// All failures extend this and carry a message.
abstract class Failure extends Equatable {
  /// Human-readable error message
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server/API error
/// 
/// Use when backend returns error response.
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

/// Local storage error
/// 
/// Use when SharedPreferences, SecureStorage, or local DB fails.
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

/// Network connectivity error
/// 
/// Use when device has no internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection']) : super(message);
}

/// Authentication error
/// 
/// Use when login fails or token is invalid/expired.
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) : super(message);
}

/// Input validation error
/// 
/// Use when user input doesn't meet requirements.
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation failed']) : super(message);
}
