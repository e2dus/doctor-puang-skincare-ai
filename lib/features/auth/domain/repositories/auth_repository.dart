import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_tokens_entity.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, AuthTokensEntity>> signIn({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, AuthTokensEntity>> signUp({
    required String email,
    required String password,
    String? username,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Check if user is authenticated
  Future<Either<Failure, bool>> isAuthenticated();

  /// Get stored tokens
  Future<Either<Failure, AuthTokensEntity?>> getStoredTokens();

  /// Refresh the access token using refresh token
  Future<Either<Failure, AuthTokensEntity>> refreshToken({
    required String refreshToken,
  });
}
