/// ============================================================================
/// USE CASE BASE CLASS
/// ============================================================================
/// 
/// Base class for all use cases in Clean Architecture.
/// Use cases encapsulate single business operations.
/// 
/// ## Pattern
/// ```dart
/// class GetUserUseCase implements UseCase<User, GetUserParams> {
///   final UserRepository repository;
///   
///   GetUserUseCase(this.repository);
///   
///   @override
///   Future<Either<Failure, User>> call(GetUserParams params) {
///     return repository.getUser(params.userId);
///   }
/// }
/// ```
/// 
/// ## Rules
/// 1. One use case = one business operation
/// 2. Use cases call repositories only
/// 3. Use cases don't know about UI or data sources
/// 4. Parameters are immutable value objects
/// ============================================================================

import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base use case interface
/// 
/// Type parameters:
/// - [Type]: Return type on success
/// - [Params]: Parameters type (use NoParams if none needed)
abstract class UseCase<Type, Params> {
  /// Execute the use case
  /// 
  /// Returns Either:
  /// - Left(Failure) on error
  /// - Right(Type) on success
  Future<Either<Failure, Type>> call(Params params);
}

/// Empty parameters class
/// 
/// Use when use case doesn't need any parameters:
/// ```dart
/// class GetAllUsersUseCase implements UseCase<List<User>, NoParams> {
///   @override
///   Future<Either<Failure, List<User>>> call(NoParams params) {
///     return repository.getAllUsers();
///   }
/// }
/// 
/// // Usage:
/// final result = await useCase(const NoParams());
/// ```
class NoParams {
  const NoParams();
}
