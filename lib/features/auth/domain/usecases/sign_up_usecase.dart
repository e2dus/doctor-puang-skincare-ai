import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_tokens_entity.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing up a new user
class SignUpUseCase implements UseCase<AuthTokensEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthTokensEntity>> call(SignUpParams params) {
    return repository.signUp(
      email: params.email,
      password: params.password,
      username: params.username,
    );
  }
}

/// Parameters for sign up use case
class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String? username;

  const SignUpParams({
    required this.email,
    required this.password,
    this.username,
  });

  @override
  List<Object?> get props => [email, password, username];
}
