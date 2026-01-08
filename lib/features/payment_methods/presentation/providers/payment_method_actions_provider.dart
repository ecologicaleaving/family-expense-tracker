import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment_method_entity.dart';
import '../../domain/repositories/payment_method_repository.dart';
import 'payment_method_provider.dart';

/// Actions class for payment method operations.
///
/// Provides high-level operations with validation for creating, updating,
/// and deleting payment methods.
class PaymentMethodActions {
  PaymentMethodActions(this._repository);

  final PaymentMethodRepository _repository;

  /// Create a new custom payment method with validation.
  ///
  /// Validates:
  /// - Name length (1-50 characters)
  /// - No duplicate names (case-insensitive)
  ///
  /// Throws:
  /// - Exception if validation fails or creation fails
  Future<PaymentMethodEntity> createPaymentMethod({
    required String userId,
    required String name,
  }) async {
    // Validate name
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      throw Exception('Il nome deve essere tra 1 e 50 caratteri');
    }

    // Check for duplicates
    final existsResult = await _repository.paymentMethodNameExists(
      userId: userId,
      name: trimmed,
    );

    final exists = existsResult.fold(
      (_) => false,
      (exists) => exists,
    );

    if (exists) {
      throw Exception('Esiste già un metodo di pagamento con questo nome');
    }

    // Create
    final result = await _repository.createPaymentMethod(
      userId: userId,
      name: trimmed,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (method) => method,
    );
  }

  /// Update custom payment method name with validation.
  ///
  /// Validates:
  /// - Name length (1-50 characters)
  /// - No duplicate names (excluding current method)
  ///
  /// Throws:
  /// - Exception if validation fails or update fails
  Future<PaymentMethodEntity> updatePaymentMethod({
    required String id,
    required String userId,
    required String name,
  }) async {
    // Validate name
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 50) {
      throw Exception('Il nome deve essere tra 1 e 50 caratteri');
    }

    // Check for duplicates (excluding current method)
    final existsResult = await _repository.paymentMethodNameExists(
      userId: userId,
      name: trimmed,
      excludeId: id,
    );

    final exists = existsResult.fold(
      (_) => false,
      (exists) => exists,
    );

    if (exists) {
      throw Exception('Esiste già un metodo di pagamento con questo nome');
    }

    // Update
    final result = await _repository.updatePaymentMethod(
      id: id,
      name: trimmed,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (method) => method,
    );
  }

  /// Delete custom payment method (with usage check).
  ///
  /// Checks if the payment method is in use before deletion.
  ///
  /// Throws:
  /// - Exception if method is in use or deletion fails
  Future<bool> deletePaymentMethod({
    required String id,
  }) async {
    // Check if in use
    final countResult = await _repository.getPaymentMethodExpenseCount(id: id);
    final count = countResult.fold(
      (_) => 0,
      (count) => count,
    );

    if (count > 0) {
      throw Exception(
        'Impossibile eliminare: metodo di pagamento utilizzato in $count spesa/e',
      );
    }

    // Delete
    final result = await _repository.deletePaymentMethod(id: id);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (success) => success,
    );
  }

  /// Get expense count for a payment method.
  Future<int> getPaymentMethodExpenseCount({
    required String id,
  }) async {
    final result = await _repository.getPaymentMethodExpenseCount(id: id);
    return result.fold(
      (_) => 0,
      (count) => count,
    );
  }

  /// Check if payment method name exists.
  Future<bool> paymentMethodNameExists({
    required String userId,
    required String name,
    String? excludeId,
  }) async {
    final result = await _repository.paymentMethodNameExists(
      userId: userId,
      name: name,
      excludeId: excludeId,
    );
    return result.fold(
      (_) => false,
      (exists) => exists,
    );
  }
}

/// Provider for PaymentMethodActions.
final paymentMethodActionsProvider = Provider<PaymentMethodActions>((ref) {
  final repository = ref.watch(paymentMethodRepositoryProvider);
  return PaymentMethodActions(repository);
});
