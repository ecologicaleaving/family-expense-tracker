/// Repository Contract: Payment Method Management
///
/// This file defines the interface contract for payment method operations.
/// All implementations must adhere to this interface.
///
/// Feature: 011-payment-methods

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment_method_entity.dart';

/// Abstract repository for payment method operations
///
/// Implementations:
/// - PaymentMethodRepositoryImpl: Production implementation using Supabase + Drift cache
abstract class PaymentMethodRepository {
  /// Fetch all payment methods available to the current user
  ///
  /// Returns default methods (user_id = null) + user's custom methods
  ///
  /// Parameters:
  /// - userId: Current user's UUID
  ///
  /// Returns:
  /// - Right(List<PaymentMethodEntity>): Success with payment methods list
  /// - Left(ServerFailure): Network error or database error
  /// - Left(AuthFailure): User not authenticated
  ///
  /// Behavior:
  /// - Tries remote (Supabase) first
  /// - Falls back to cache if network fails
  /// - Returns empty list if both fail and no cache
  /// - Orders: default methods first (by name), then custom methods (by name)
  Future<Either<Failure, List<PaymentMethodEntity>>> getPaymentMethods({
    required String userId,
  });

  /// Fetch a single payment method by ID
  ///
  /// Parameters:
  /// - id: Payment method UUID
  ///
  /// Returns:
  /// - Right(PaymentMethodEntity): Payment method found
  /// - Left(NotFoundFailure): Payment method not found
  /// - Left(ServerFailure): Network or database error
  ///
  /// Security:
  /// - RLS policies ensure user can only fetch defaults or their own methods
  Future<Either<Failure, PaymentMethodEntity>> getPaymentMethodById({
    required String id,
  });

  /// Create a new custom payment method
  ///
  /// Parameters:
  /// - userId: Owner user UUID
  /// - name: Display name (1-50 chars, will be trimmed)
  ///
  /// Returns:
  /// - Right(PaymentMethodEntity): Created payment method
  /// - Left(ValidationFailure): Invalid name or duplicate
  /// - Left(ServerFailure): Database error
  /// - Left(AuthFailure): User not authenticated
  ///
  /// Validations:
  /// - Name: 1-50 characters after trimming
  /// - Uniqueness: (userId, LOWER(name)) must be unique
  /// - isDefault: Always set to false for user-created methods
  ///
  /// Side Effects:
  /// - Updates cache with new method
  /// - Broadcasts real-time event to other sessions
  Future<Either<Failure, PaymentMethodEntity>> createPaymentMethod({
    required String userId,
    required String name,
  });

  /// Update a custom payment method's name
  ///
  /// Parameters:
  /// - id: Payment method UUID
  /// - name: New display name (1-50 chars, will be trimmed)
  ///
  /// Returns:
  /// - Right(PaymentMethodEntity): Updated payment method
  /// - Left(ValidationFailure): Invalid name or duplicate
  /// - Left(PermissionFailure): Attempting to update default method
  /// - Left(NotFoundFailure): Payment method not found
  /// - Left(ServerFailure): Database error
  ///
  /// Restrictions:
  /// - Cannot update default methods (isDefault = true)
  /// - Can only update methods owned by current user (RLS policy)
  ///
  /// Side Effects:
  /// - Updates cache
  /// - Broadcasts real-time event
  /// - DOES NOT update denormalized payment_method_name in expenses table
  ///   (expenses retain historical name at time of creation)
  Future<Either<Failure, PaymentMethodEntity>> updatePaymentMethod({
    required String id,
    required String name,
  });

  /// Delete a custom payment method
  ///
  /// Parameters:
  /// - id: Payment method UUID
  ///
  /// Returns:
  /// - Right(true): Payment method deleted successfully
  /// - Right(false): Delete failed (likely in use by expenses)
  /// - Left(PermissionFailure): Attempting to delete default method
  /// - Left(ValidationFailure): Payment method is in use (FK constraint)
  /// - Left(NotFoundFailure): Payment method not found
  /// - Left(ServerFailure): Database error
  ///
  /// Restrictions:
  /// - Cannot delete default methods (isDefault = true)
  /// - Cannot delete if referenced by any expense (FK constraint)
  /// - Can only delete methods owned by current user (RLS policy)
  ///
  /// Side Effects:
  /// - Removes from cache
  /// - Broadcasts real-time event
  ///
  /// Best Practice:
  /// - Call getPaymentMethodExpenseCount() first to check usage
  /// - Show user confirmation dialog with expense count
  Future<Either<Failure, bool>> deletePaymentMethod({
    required String id,
  });

  /// Count expenses using this payment method
  ///
  /// Parameters:
  /// - id: Payment method UUID
  ///
  /// Returns:
  /// - Right(int): Number of expenses (0 or more)
  /// - Left(NotFoundFailure): Payment method not found
  /// - Left(ServerFailure): Database error
  ///
  /// Use Cases:
  /// - Before delete: Check if payment method is in use
  /// - In UI: Show expense count per method in management screen
  Future<Either<Failure, int>> getPaymentMethodExpenseCount({
    required String id,
  });

  /// Check if a payment method name already exists for this user
  ///
  /// Parameters:
  /// - userId: User UUID
  /// - name: Name to check (case-insensitive)
  /// - excludeId: Optional payment method ID to exclude (for edit validation)
  ///
  /// Returns:
  /// - Right(true): Name already exists
  /// - Right(false): Name is available
  /// - Left(ServerFailure): Database error
  ///
  /// Behavior:
  /// - Case-insensitive comparison
  /// - Excludes payment method with excludeId (useful for edit mode)
  /// - Checks only within user's methods (not against other users)
  ///
  /// Use Cases:
  /// - Form validation before submit
  /// - Real-time duplicate detection as user types
  Future<Either<Failure, bool>> paymentMethodNameExists({
    required String userId,
    required String name,
    String? excludeId,
  });

  /// Stream of payment methods for real-time updates
  ///
  /// Parameters:
  /// - userId: Current user UUID
  ///
  /// Returns:
  /// - Stream<List<PaymentMethodEntity>>: Real-time payment methods list
  ///
  /// Behavior:
  /// - Subscribes to Supabase Realtime channel
  /// - Emits new list whenever INSERT/UPDATE/DELETE occurs
  /// - Automatically filters by user (RLS policies)
  ///
  /// Subscription Lifecycle:
  /// - Starts when first listener subscribes
  /// - Stops when last listener cancels
  /// - Auto-reconnects on network recovery
  ///
  /// Use Cases:
  /// - Payment method management screen (auto-refresh on changes)
  /// - Expense form selector (updates when user adds custom method in settings)
  Stream<List<PaymentMethodEntity>> watchPaymentMethods({
    required String userId,
  });

  /// Get the default "Contanti" payment method
  ///
  /// Returns:
  /// - Right(PaymentMethodEntity): The "Contanti" default method
  /// - Left(NotFoundFailure): "Contanti" not found (database not seeded)
  /// - Left(ServerFailure): Database error
  ///
  /// Behavior:
  /// - Queries for method where name = 'Contanti' AND isDefault = true
  /// - Used to get ID for setting default on new expenses
  ///
  /// Note:
  /// - This should never fail in production (seeded during migration)
  /// - If it fails, database setup is incomplete
  Future<Either<Failure, PaymentMethodEntity>> getDefaultContanti();
}
