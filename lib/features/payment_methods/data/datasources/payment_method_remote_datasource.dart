import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/payment_method_model.dart';

/// Remote data source for payment method operations using Supabase.
abstract class PaymentMethodRemoteDataSource {
  /// Get all payment methods for a user (default + custom).
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String userId,
    bool includeExpenseCount = false,
  });

  /// Get a single payment method by ID.
  Future<PaymentMethodModel> getPaymentMethod({required String id});

  /// Create a new custom payment method.
  Future<PaymentMethodModel> createPaymentMethod({
    required String userId,
    required String name,
  });

  /// Update a custom payment method name.
  Future<PaymentMethodModel> updatePaymentMethod({
    required String id,
    required String name,
  });

  /// Delete a custom payment method.
  Future<void> deletePaymentMethod({required String id});

  /// Get expense count for a payment method.
  Future<int> getPaymentMethodExpenseCount({required String id});

  /// Check if payment method name exists for user.
  Future<bool> paymentMethodNameExists({
    required String userId,
    required String name,
    String? excludeId,
  });

  /// Get the default "Contanti" payment method.
  Future<PaymentMethodModel> getDefaultContanti();
}

/// Implementation of [PaymentMethodRemoteDataSource] using Supabase.
class PaymentMethodRemoteDataSourceImpl
    implements PaymentMethodRemoteDataSource {
  PaymentMethodRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('No authenticated user', 'not_authenticated');
    }
    return userId;
  }

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String userId,
    bool includeExpenseCount = false,
  }) async {
    try {
      // Query for default methods (user_id IS NULL) OR user's custom methods
      var query = supabaseClient
          .from('payment_methods')
          .select(includeExpenseCount
              ? '*, expense_count:expenses!payment_method_id(count)'
              : '*')
          .or('is_default.eq.true,user_id.eq.$userId')
          .order('is_default', ascending: false) // Default methods first
          .order('name', ascending: true);

      final response = await query;

      return (response as List)
          .map((json) => PaymentMethodModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get payment methods: $e');
    }
  }

  @override
  Future<PaymentMethodModel> getPaymentMethod({required String id}) async {
    try {
      final response = await supabaseClient
          .from('payment_methods')
          .select('*, expense_count:expenses!payment_method_id(count)')
          .eq('id', id)
          .single();

      return PaymentMethodModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const ServerException('Metodo di pagamento non trovato', 'not_found');
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get payment method: $e');
    }
  }

  @override
  Future<PaymentMethodModel> createPaymentMethod({
    required String userId,
    required String name,
  }) async {
    try {
      final response = await supabaseClient
          .from('payment_methods')
          .insert({
            'user_id': userId,
            'name': name.trim(),
            'is_default': false,
          })
          .select()
          .single();

      return PaymentMethodModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Check for unique constraint violation
      if (e.code == '23505') {
        throw const ValidationException(
          'A payment method with this name already exists',
        );
      }
      // Check for permission error
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw const PermissionException(
          'Cannot create payment method',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to create payment method: $e');
    }
  }

  @override
  Future<PaymentMethodModel> updatePaymentMethod({
    required String id,
    required String name,
  }) async {
    try {
      final response = await supabaseClient
          .from('payment_methods')
          .update({
            'name': name.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return PaymentMethodModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Check for unique constraint violation
      if (e.code == '23505') {
        throw const ValidationException(
          'A payment method with this name already exists',
        );
      }
      // Check for permission error or default method update attempt
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw const PermissionException(
          'Cannot update default payment methods',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to update payment method: $e');
    }
  }

  @override
  Future<void> deletePaymentMethod({required String id}) async {
    try {
      await supabaseClient.from('payment_methods').delete().eq('id', id);
    } on PostgrestException catch (e) {
      // Check for foreign key constraint violation
      if (e.code == '23503') {
        throw const ValidationException(
          'Cannot delete payment method with existing expenses',
        );
      }
      // Check for permission error or default method deletion attempt
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw const PermissionException(
          'Cannot delete default payment methods',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to delete payment method: $e');
    }
  }

  @override
  Future<int> getPaymentMethodExpenseCount({required String id}) async {
    try {
      // Count expenses using this payment method
      final response = await supabaseClient
          .from('expenses')
          .select('id')
          .eq('payment_method_id', id)
          .count();

      return response.count;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get payment method expense count: $e');
    }
  }

  @override
  Future<bool> paymentMethodNameExists({
    required String userId,
    required String name,
    String? excludeId,
  }) async {
    try {
      var query = supabaseClient
          .from('payment_methods')
          .select('id')
          .or('is_default.eq.true,user_id.eq.$userId')
          .ilike('name', name); // Case-insensitive

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to check payment method name: $e');
    }
  }

  @override
  Future<PaymentMethodModel> getDefaultContanti() async {
    try {
      final response = await supabaseClient
          .from('payment_methods')
          .select('*')
          .eq('name', 'Contanti')
          .eq('is_default', true)
          .single();

      return PaymentMethodModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const ServerException(
          'Metodo di pagamento predefinito "Contanti" non trovato',
          'not_found',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get default Contanti method: $e');
    }
  }
}
