/// ============================================================================
/// AUTH VIEWMODEL
/// ============================================================================
///
/// Manages authentication state and operations.
///
/// ## Usage
/// ```dart
/// // Check auth status
/// final authState = ref.watch(authProvider);
///
/// // Perform sign in
/// await ref.read(authProvider.notifier).signIn(email, password);
/// ```
///
/// ## State Flow
/// initial → loading → authenticated/unauthenticated/error
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Authentication status enum
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Authentication state
class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.initial, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Authentication Notifier (ViewModel)
class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;

  AuthNotifier({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       super(const AuthState());

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    print('🔐 AuthViewModel: signIn called with email=$email');
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _signInUseCase(
      SignInParams(email: email, password: password),
    );

    return result.fold(
      (failure) {
        print('❌ AuthViewModel: SignIn failure - ${failure.message}');
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (tokens) {
        print(
          '✅ AuthViewModel: SignIn success - accessToken length=${tokens.accessToken.length}',
        );
        state = state.copyWith(status: AuthStatus.authenticated);
        return true;
      },
    );
  }

  /// Sign up with email and password
  Future<bool> signUp(String email, String password, {String? username}) async {
    print(
      '🔐 AuthViewModel: signUp called with email=$email, username=$username',
    );
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _signUpUseCase(
      SignUpParams(email: email, password: password, username: username),
    );

    return result.fold(
      (failure) {
        print('❌ AuthViewModel: SignUp failure - ${failure.message}');
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (tokens) {
        print(
          '✅ AuthViewModel: SignUp success - accessToken length=${tokens.accessToken.length}',
        );
        state = state.copyWith(status: AuthStatus.authenticated);
        return true;
      },
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _signOutUseCase(const NoParams());

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      },
    );
  }

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    final result = await _checkAuthStatusUseCase(const NoParams());

    result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      },
      (isAuthenticated) {
        state = state.copyWith(
          status: isAuthenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
        );
      },
    );
  }
}

/// Provider for authentication state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final remoteDataSource = AuthRemoteDataSourceImpl();
  final localDataSource = AuthLocalDataSourceImpl();
  final repository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );

  return AuthNotifier(
    signInUseCase: SignInUseCase(repository),
    signUpUseCase: SignUpUseCase(repository),
    signOutUseCase: SignOutUseCase(repository),
    checkAuthStatusUseCase: CheckAuthStatusUseCase(repository),
  );
});
