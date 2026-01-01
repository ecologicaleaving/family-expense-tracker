import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/expense_model.dart';

/// Remote data source for expense operations using Supabase.
abstract class ExpenseRemoteDataSource {
  /// Get all expenses for the current user's group.
  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? createdBy,
    int? limit,
    int? offset,
  });

  /// Get a single expense by ID.
  Future<ExpenseModel> getExpense({required String expenseId});

  /// Create a new expense.
  Future<ExpenseModel> createExpense({
    required double amount,
    required DateTime date,
    required String category,
    String? merchant,
    String? notes,
    bool isGroupExpense = true,
  });

  /// Update an existing expense.
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    double? amount,
    DateTime? date,
    String? category,
    String? merchant,
    String? notes,
  });

  /// Delete an expense.
  Future<void> deleteExpense({required String expenseId});

  /// Update expense classification (group or personal).
  Future<ExpenseModel> updateExpenseClassification({
    required String expenseId,
    required bool isGroupExpense,
  });

  /// Upload a receipt image.
  Future<String> uploadReceiptImage({
    required String expenseId,
    required Uint8List imageData,
  });

  /// Get signed URL for a receipt.
  Future<String> getReceiptUrl({required String receiptPath});
}

/// Implementation of [ExpenseRemoteDataSource] using Supabase.
class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  ExpenseRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Nessun utente autenticato', 'not_authenticated');
    }
    return userId;
  }

  Future<String?> get _currentUserGroupId async {
    final userId = _currentUserId;
    final response = await supabaseClient
        .from('profiles')
        .select('group_id')
        .eq('id', userId)
        .single();
    return response['group_id'] as String?;
  }

  @override
  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? createdBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final groupId = await _currentUserGroupId;
      if (groupId == null) {
        throw const GroupException('Non fai parte di nessun gruppo', 'not_in_group');
      }

      // Build the filter query
      var filterQuery = supabaseClient
          .from('expenses')
          .select()
          .eq('group_id', groupId);

      if (startDate != null) {
        filterQuery = filterQuery.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        filterQuery = filterQuery.lte('date', endDate.toIso8601String().split('T')[0]);
      }
      if (category != null) {
        filterQuery = filterQuery.eq('category', category);
      }
      if (createdBy != null) {
        filterQuery = filterQuery.eq('created_by', createdBy);
      }

      // Apply ordering and pagination
      var orderedQuery = filterQuery.order('date', ascending: false);

      if (offset != null && limit != null) {
        orderedQuery = orderedQuery.range(offset, offset + limit - 1);
      } else if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      return (response as List).map((json) => ExpenseModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ExpenseModel> getExpense({required String expenseId}) async {
    try {
      final response = await supabaseClient
          .from('expenses')
          .select()
          .eq('id', expenseId)
          .single();

      return ExpenseModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ExpenseModel> createExpense({
    required double amount,
    required DateTime date,
    required String category,
    String? merchant,
    String? notes,
    bool isGroupExpense = true,
  }) async {
    try {
      final userId = _currentUserId;
      final groupId = await _currentUserGroupId;

      if (groupId == null) {
        throw const GroupException('Non fai parte di nessun gruppo', 'not_in_group');
      }

      // Get user's display name
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .single();
      final displayName = profileResponse['display_name'] as String?;

      // Normalize date to UTC date only (no time component)
      final normalizedDate = DateTime.utc(date.year, date.month, date.day);

      final response = await supabaseClient
          .from('expenses')
          .insert({
            'group_id': groupId,
            'created_by': userId,
            'created_by_name': displayName ?? 'Utente',
            'paid_by': userId,
            'paid_by_name': displayName ?? 'Utente',
            'amount': amount,
            'date': normalizedDate.toIso8601String().split('T')[0],
            'category': category,
            'merchant': merchant,
            'notes': notes,
            'is_group_expense': isGroupExpense,
          })
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      if (e is AppAuthException || e is GroupException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ExpenseModel> updateExpense({
    required String expenseId,
    double? amount,
    DateTime? date,
    String? category,
    String? merchant,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (amount != null) updates['amount'] = amount;
      if (date != null) updates['date'] = date.toIso8601String().split('T')[0];
      if (category != null) updates['category'] = category;
      if (merchant != null) updates['merchant'] = merchant;
      if (notes != null) updates['notes'] = notes;

      if (updates.isEmpty) {
        return await getExpense(expenseId: expenseId);
      }

      final response = await supabaseClient
          .from('expenses')
          .update(updates)
          .eq('id', expenseId)
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteExpense({required String expenseId}) async {
    try {
      await supabaseClient
          .from('expenses')
          .delete()
          .eq('id', expenseId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ExpenseModel> updateExpenseClassification({
    required String expenseId,
    required bool isGroupExpense,
  }) async {
    try {
      final response = await supabaseClient
          .from('expenses')
          .update({'is_group_expense': isGroupExpense})
          .eq('id', expenseId)
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } on PostgrestException catch (e) {
      // RLS will prevent unauthorized updates
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw const PermissionException(
          'You can only change classification of your own expenses',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadReceiptImage({
    required String expenseId,
    required Uint8List imageData,
  }) async {
    try {
      final userId = _currentUserId;
      final path = '$userId/$expenseId.jpg';

      await supabaseClient.storage
          .from('receipts')
          .uploadBinary(
            path,
            imageData,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Update expense with receipt path
      await supabaseClient
          .from('expenses')
          .update({'receipt_url': path})
          .eq('id', expenseId);

      return path;
    } on StorageException catch (e) {
      throw ServerException(e.message, e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> getReceiptUrl({required String receiptPath}) async {
    try {
      final signedUrl = await supabaseClient.storage
          .from('receipts')
          .createSignedUrl(receiptPath, 3600); // 1 hour expiry

      return signedUrl;
    } on StorageException catch (e) {
      throw ServerException(e.message, e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
