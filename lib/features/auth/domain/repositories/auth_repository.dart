import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract authentication repository interface.
///
/// Defines the contract for authentication operations.
/// Implementations should handle the actual communication with
/// the authentication backend (Supabase Auth).
abstract class AuthRepository {
  /// Get the currently authenticated user.
  ///
  /// Returns [Right] with [UserEntity] if authenticated,
  /// or [Left] with [Failure] if not authenticated or error occurred.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Sign in with email and password.
  ///
  /// Returns [Right] with [UserEntity] on success,
  /// or [Left] with [AuthFailure] on failure.
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Register a new user with email and password.
  ///
  /// Returns [Right] with [UserEntity] on success,
  /// or [Left] with [AuthFailure] on failure.
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign out the current user.
  ///
  /// Returns [Right] with [unit] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, Unit>> signOut();

  /// Request a password reset email.
  ///
  /// Returns [Right] with [unit] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
  });

  /// Update the current user's display name.
  ///
  /// Returns [Right] with updated [UserEntity] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, UserEntity>> updateDisplayName({
    required String displayName,
  });

  /// Delete the current user's account.
  ///
  /// If [anonymizeExpenses] is true, the user's name will be replaced
  /// with "Utente eliminato" on their expenses. Otherwise, the original
  /// name will be kept on expenses.
  ///
  /// Returns [Right] with [unit] on success,
  /// or [Left] with [Failure] on failure.
  Future<Either<Failure, Unit>> deleteAccount({
    required bool anonymizeExpenses,
  });

  /// Stream of authentication state changes.
  ///
  /// Emits [UserEntity] when user is authenticated,
  /// or [UserEntity.empty()] when not authenticated.
  Stream<UserEntity> get authStateChanges;

  /// Check if a user is currently authenticated.
  bool get isAuthenticated;
}
