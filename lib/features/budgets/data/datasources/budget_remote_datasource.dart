import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/timezone_handler.dart';
import '../models/budget_stats_model.dart';
import '../models/group_budget_model.dart';
import '../models/personal_budget_model.dart';

/// Remote data source for budget operations using Supabase.
abstract class BudgetRemoteDataSource {
  // ========== Group Budget Operations ==========

  /// Set or update a group budget.
  Future<GroupBudgetModel> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  });

  /// Get group budget for a specific month/year.
  Future<GroupBudgetModel?> getGroupBudget({
    required String groupId,
    required int month,
    required int year,
  });

  /// Get group budget statistics.
  Future<BudgetStatsModel> getGroupBudgetStats({
    required String groupId,
    required int month,
    required int year,
  });

  /// Get historical group budgets.
  Future<List<GroupBudgetModel>> getGroupBudgetHistory({
    required String groupId,
    int? limit,
  });

  // ========== Personal Budget Operations ==========

  /// Set or update a personal budget.
  Future<PersonalBudgetModel> setPersonalBudget({
    required String userId,
    required int amount,
    required int month,
    required int year,
  });

  /// Get personal budget for a specific month/year.
  Future<PersonalBudgetModel?> getPersonalBudget({
    required String userId,
    required int month,
    required int year,
  });

  /// Get personal budget statistics.
  Future<BudgetStatsModel> getPersonalBudgetStats({
    required String userId,
    required int month,
    required int year,
  });

  /// Get historical personal budgets.
  Future<List<PersonalBudgetModel>> getPersonalBudgetHistory({
    required String userId,
    int? limit,
  });
}

/// Implementation of [BudgetRemoteDataSource] using Supabase.
class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  BudgetRemoteDataSourceImpl({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  String get _currentUserId {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('No authenticated user', 'not_authenticated');
    }
    return userId;
  }

  // ========== Group Budget Operations ==========

  @override
  Future<GroupBudgetModel> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  }) async {
    try {
      final userId = _currentUserId;

      // Upsert: insert or update if exists
      final response = await supabaseClient
          .from('group_budgets')
          .upsert(
            {
              'group_id': groupId,
              'amount': amount,
              'month': month,
              'year': year,
              'created_by': userId,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'group_id,year,month',
          )
          .select()
          .single();

      return GroupBudgetModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to set group budget: $e');
    }
  }

  @override
  Future<GroupBudgetModel?> getGroupBudget({
    required String groupId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await supabaseClient
          .from('group_budgets')
          .select()
          .eq('group_id', groupId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (response == null) return null;

      return GroupBudgetModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get group budget: $e');
    }
  }

  @override
  Future<BudgetStatsModel> getGroupBudgetStats({
    required String groupId,
    required int month,
    required int year,
  }) async {
    try {
      // Get budget for the month (if exists)
      final budget = await getGroupBudget(
        groupId: groupId,
        month: month,
        year: year,
      );

      // Get month start/end dates in user's timezone
      final monthStart = TimezoneHandler.getMonthStart(year, month);
      final monthEnd = TimezoneHandler.getMonthEnd(year, month);

      // Get all group expenses for the month
      final expensesResponse = await supabaseClient
          .from('expenses')
          .select('amount')
          .eq('group_id', groupId)
          .eq('is_group_expense', true)
          .gte('date', monthStart.toIso8601String().split('T')[0])
          .lte('date', monthEnd.toIso8601String().split('T')[0]);

      // Extract expense amounts
      final expenseAmounts = (expensesResponse as List)
          .map((e) => (e['amount'] as num).toDouble())
          .toList();

      // Calculate stats using BudgetStatsModel factory
      return BudgetStatsModel.fromQueryResult(
        budgetId: budget?.id,
        budgetAmount: budget?.amount,
        expenseAmounts: expenseAmounts,
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get group budget stats: $e');
    }
  }

  @override
  Future<List<GroupBudgetModel>> getGroupBudgetHistory({
    required String groupId,
    int? limit,
  }) async {
    try {
      var query = supabaseClient
          .from('group_budgets')
          .select()
          .eq('group_id', groupId)
          .order('year', ascending: false)
          .order('month', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => GroupBudgetModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get group budget history: $e');
    }
  }

  // ========== Personal Budget Operations ==========

  @override
  Future<PersonalBudgetModel> setPersonalBudget({
    required String userId,
    required int amount,
    required int month,
    required int year,
  }) async {
    try {
      // Upsert: insert or update if exists
      final response = await supabaseClient
          .from('personal_budgets')
          .upsert(
            {
              'user_id': userId,
              'amount': amount,
              'month': month,
              'year': year,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,year,month',
          )
          .select()
          .single();

      return PersonalBudgetModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to set personal budget: $e');
    }
  }

  @override
  Future<PersonalBudgetModel?> getPersonalBudget({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await supabaseClient
          .from('personal_budgets')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (response == null) return null;

      return PersonalBudgetModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get personal budget: $e');
    }
  }

  @override
  Future<BudgetStatsModel> getPersonalBudgetStats({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      // Get budget for the month (if exists)
      final budget = await getPersonalBudget(
        userId: userId,
        month: month,
        year: year,
      );

      // Get month start/end dates in user's timezone
      final monthStart = TimezoneHandler.getMonthStart(year, month);
      final monthEnd = TimezoneHandler.getMonthEnd(year, month);

      // Get all expenses created by this user for the month
      // (includes both personal expenses AND user's group expenses)
      final expensesResponse = await supabaseClient
          .from('expenses')
          .select('amount')
          .eq('created_by', userId)
          .gte('date', monthStart.toIso8601String().split('T')[0])
          .lte('date', monthEnd.toIso8601String().split('T')[0]);

      // Extract expense amounts
      final expenseAmounts = (expensesResponse as List)
          .map((e) => (e['amount'] as num).toDouble())
          .toList();

      // Calculate stats using BudgetStatsModel factory
      return BudgetStatsModel.fromQueryResult(
        budgetId: budget?.id,
        budgetAmount: budget?.amount,
        expenseAmounts: expenseAmounts,
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get personal budget stats: $e');
    }
  }

  @override
  Future<List<PersonalBudgetModel>> getPersonalBudgetHistory({
    required String userId,
    int? limit,
  }) async {
    try {
      var query = supabaseClient
          .from('personal_budgets')
          .select()
          .eq('user_id', userId)
          .order('year', ascending: false)
          .order('month', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => PersonalBudgetModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get personal budget history: $e');
    }
  }
}
