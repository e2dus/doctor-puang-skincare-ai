import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthTokensEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final tokens = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      await localDataSource.saveTokens(tokens);
      await localDataSource.saveEmail(email); // 이메일 저장
      return Right(tokens);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokensEntity>> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      print('🔐 AuthRepositoryImpl.signUp: Starting...');
      final tokens = await remoteDataSource.signUp(
        email: email,
        password: password,
        username: username,
      );
      print(
        '🔐 AuthRepositoryImpl.signUp: Tokens received - accessToken length: ${tokens.accessToken.length}',
      );

      await localDataSource.saveTokens(tokens);
      print('🔐 AuthRepositoryImpl.signUp: Tokens saved to local storage');

      return Right(tokens);
    } on ServerException catch (e) {
      print('❌ AuthRepositoryImpl.signUp: ServerException - ${e.message}');
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      print('❌ AuthRepositoryImpl.signUp: CacheException - ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ AuthRepositoryImpl.signUp: Exception - $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await localDataSource.clearTokens();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final hasTokens = await localDataSource.hasTokens();
      return Right(hasTokens);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, AuthTokensEntity?>> getStoredTokens() async {
    try {
      final tokens = await localDataSource.getTokens();
      return Right(tokens);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokensEntity>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final newTokens = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      await localDataSource.saveTokens(newTokens);
      return Right(newTokens);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
