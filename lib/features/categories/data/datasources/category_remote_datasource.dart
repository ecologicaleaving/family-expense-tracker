import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/expense_category_model.dart';

/// Remote data source for category operations using Supabase.
abstract class CategoryRemoteDataSource {
  /// Get all categories for a group.
  Future<List<ExpenseCategoryModel>> getCategories({
    required String groupId,
    bool includeExpenseCount = false,
  });

  /// Get a single category by ID.
  Future<ExpenseCategoryModel> getCategory({required String categoryId});

  /// Create a new category.
  Future<ExpenseCategoryModel> createCategory({
    required String groupId,
    required String name,
  });

  /// Update a category name.
  Future<ExpenseCategoryModel> updateCategory({
    required String categoryId,
    required String name,
  });

  /// Delete a category.
  Future<void> deleteCategory({required String categoryId});

  /// Batch update expenses to new category (using RPC function).
  Future<int> batchUpdateExpenseCategory({
    required String groupId,
    required String oldCategoryId,
    required String newCategoryId,
  });

  /// Get expense count for a category (using RPC function).
  Future<int> getCategoryExpenseCount({required String categoryId});

  /// Check if category name exists in group.
  Future<bool> categoryNameExists({
    required String groupId,
    required String name,
    String? excludeCategoryId,
  });
}

/// Implementation of [CategoryRemoteDataSource] using Supabase.
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('No authenticated user', 'not_authenticated');
    }
    return userId;
  }

  @override
  Future<List<ExpenseCategoryModel>> getCategories({
    required String groupId,
    bool includeExpenseCount = false,
  }) async {
    try {
      var query = supabaseClient
          .from('expense_categories')
          .select(includeExpenseCount
              ? '*, expense_count:get_category_expense_count(category_id)'
              : '*')
          .eq('group_id', groupId)
          .order('is_default', ascending: false) // Default categories first
          .order('name', ascending: true);

      final response = await query;

      return (response as List)
          .map((json) => ExpenseCategoryModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get categories: $e');
    }
  }

  @override
  Future<ExpenseCategoryModel> getCategory({required String categoryId}) async {
    try {
      final response = await supabaseClient
          .from('expense_categories')
          .select('*, expense_count:get_category_expense_count(category_id)')
          .eq('id', categoryId)
          .single();

      return ExpenseCategoryModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get category: $e');
    }
  }

  @override
  Future<ExpenseCategoryModel> createCategory({
    required String groupId,
    required String name,
  }) async {
    try {
      final userId = _currentUserId;

      final response = await supabaseClient
          .from('expense_categories')
          .insert({
            'group_id': groupId,
            'name': name,
            'is_default': false,
            'created_by': userId,
          })
          .select()
          .single();

      return ExpenseCategoryModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Check for unique constraint violation
      if (e.code == '23505') {
        throw const ValidationException(
          'A category with this name already exists',
        );
      }
      // Check for permission error
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw const PermissionException(
          'Only administrators can create categories',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to create category: $e');
    }
  }

  @override
  Future<ExpenseCategoryModel> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    try {
      final response = await supabaseClient
          .from('expense_categories')
          .update({'name': name, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', categoryId)
          .select()
          .single();

      return ExpenseCategoryModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Check for unique constraint violation
      if (e.code == '23505') {
        throw const ValidationException(
          'A category with this name already exists',
        );
      }
      // Check for permission error or default category update attempt
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw const PermissionException(
          'Only administrators can update categories, and default categories cannot be renamed',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory({required String categoryId}) async {
    try {
      await supabaseClient
          .from('expense_categories')
          .delete()
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      // Check for foreign key constraint violation
      if (e.code == '23503') {
        throw const ValidationException(
          'Cannot delete category with existing expenses. Reassign expenses first.',
        );
      }
      // Check for permission error or default category deletion attempt
      if (e.code == '42501' || e.code == 'PGRST301') {
        throw const PermissionException(
          'Only administrators can delete categories, and default categories cannot be deleted',
        );
      }
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to delete category: $e');
    }
  }

  @override
  Future<int> batchUpdateExpenseCategory({
    required String groupId,
    required String oldCategoryId,
    required String newCategoryId,
  }) async {
    try {
      // Call PostgreSQL RPC function for efficient batch update
      final response = await supabaseClient.rpc(
        'batch_update_expense_category',
        params: {
          'p_group_id': groupId,
          'p_old_category_id': oldCategoryId,
          'p_new_category_id': newCategoryId,
        },
      );

      return response as int;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to batch update expense category: $e');
    }
  }

  @override
  Future<int> getCategoryExpenseCount({required String categoryId}) async {
    try {
      // Call PostgreSQL RPC function
      final response = await supabaseClient.rpc(
        'get_category_expense_count',
        params: {'p_category_id': categoryId},
      );

      return response as int;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get category expense count: $e');
    }
  }

  @override
  Future<bool> categoryNameExists({
    required String groupId,
    required String name,
    String? excludeCategoryId,
  }) async {
    try {
      var query = supabaseClient
          .from('expense_categories')
          .select('id')
          .eq('group_id', groupId)
          .ilike('name', name); // Case-insensitive

      if (excludeCategoryId != null) {
        query = query.neq('id', excludeCategoryId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to check category name: $e');
    }
  }
}
