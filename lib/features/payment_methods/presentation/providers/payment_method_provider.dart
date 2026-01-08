import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/repositories/payment_method_repository.dart';
import '../../data/datasources/payment_method_remote_datasource.dart';
import '../../data/repositories/payment_method_repository_impl.dart';

/// State class for payment method management.
class PaymentMethodState {
  const PaymentMethodState({
    this.paymentMethods = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PaymentMethodEntity> paymentMethods;
  final bool isLoading;
  final String? errorMessage;

  /// Get default payment methods only.
  List<PaymentMethodEntity> get defaultMethods =>
      paymentMethods.where((m) => m.isDefault).toList();

  /// Get custom payment methods only.
  List<PaymentMethodEntity> get customMethods =>
      paymentMethods.where((m) => !m.isDefault).toList();

  /// Get payment method by ID.
  PaymentMethodEntity? getById(String id) =>
      paymentMethods.cast<PaymentMethodEntity?>().firstWhere(
            (m) => m?.id == id,
            orElse: () => null,
          );

  /// Get default "Contanti" method.
  PaymentMethodEntity? get defaultContanti => paymentMethods
      .cast<PaymentMethodEntity?>()
      .firstWhere(
        (m) => m?.name == 'Contanti' && m?.isDefault == true,
        orElse: () => null,
      );

  /// Check if list is empty.
  bool get isEmpty => paymentMethods.isEmpty;

  /// Check if has error.
  bool get hasError => errorMessage != null;

  /// Create a copy with updated fields.
  PaymentMethodState copyWith({
    List<PaymentMethodEntity>? paymentMethods,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PaymentMethodState(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// State notifier for payment method management.
class PaymentMethodNotifier extends StateNotifier<PaymentMethodState> {
  PaymentMethodNotifier({
    required PaymentMethodRepository repository,
    required this.userId,
  })  : _repository = repository,
        super(const PaymentMethodState()) {
    loadPaymentMethods();
  }

  final PaymentMethodRepository _repository;
  final String userId;

  /// Load all payment methods for the current user.
  Future<void> loadPaymentMethods() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getPaymentMethods(userId: userId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (paymentMethods) {
        state = state.copyWith(
          paymentMethods: paymentMethods,
          isLoading: false,
          errorMessage: null,
        );
      },
    );
  }

  /// Refresh payment methods (for manual refresh).
  Future<void> refresh() async {
    await loadPaymentMethods();
  }
}

/// Provider for PaymentMethodRepository.
final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  final remoteDataSource = PaymentMethodRemoteDataSourceImpl(
    supabaseClient: supabaseClient,
  );
  return PaymentMethodRepositoryImpl(
    remoteDataSource: remoteDataSource,
  );
});

/// Provider for PaymentMethodNotifier (family provider for user-scoped state).
final paymentMethodProvider = StateNotifierProvider.family<
    PaymentMethodNotifier,
    PaymentMethodState,
    String>((ref, userId) {
  final repository = ref.watch(paymentMethodRepositoryProvider);
  return PaymentMethodNotifier(
    repository: repository,
    userId: userId,
  );
});
