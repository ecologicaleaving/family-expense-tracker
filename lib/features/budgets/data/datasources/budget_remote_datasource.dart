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

  // ========== Category Budget Operations (Feature 004) ==========

  /// Get all category budgets for a specific month.
  Future<List> getCategoryBudgets({
    required String groupId,
    required int year,
    required int month,
  });

  /// Get a single category budget.
  Future<dynamic> getCategoryBudget({
    required String categoryId,
    required String groupId,
    required int year,
    required int month,
  });

  /// Create a new category budget.
  Future<dynamic> createCategoryBudget({
    required String categoryId,
    required String groupId,
    required int amount,
    required int month,
    required int year,
    bool isGroupBudget = true,
  });

  /// Update a category budget.
  Future<dynamic> updateCategoryBudget({
    required String budgetId,
    required int amount,
  });

  /// Delete a category budget.
  Future<void> deleteCategoryBudget(String budgetId);

  /// Get category budget stats (via RPC).
  Future<dynamic> getCategoryBudgetStats({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  });

  /// Get overall group budget stats (via RPC).
  Future<dynamic> getOverallGroupBudgetStats({
    required String groupId,
    required int year,
    required int month,
  });

  // ========== Percentage Budget Operations (Feature 004 Extension) ==========

  /// Get group members with their percentage contributions (via RPC).
  Future<List> getGroupMembersWithPercentages({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  });

  /// Calculate percentage budget (via RPC).
  Future<int> calculatePercentageBudget({
    required int groupBudgetAmount,
    required double percentage,
  });

  /// Get budget change notifications (via RPC).
  Future<List> getBudgetChangeNotifications({
    required String groupId,
    required int year,
    required int month,
    String? userId,
  });

  /// Set personal percentage budget.
  Future<dynamic> setPersonalPercentageBudget({
    required String categoryId,
    required String groupId,
    required String userId,
    required double percentage,
    required int month,
    required int year,
  });

  /// Get percentage from previous month.
  Future<double?> getPreviousMonthPercentage({
    required String categoryId,
    required String groupId,
    required String userId,
    required int year,
    required int month,
  });

  /// Get percentage history.
  Future<List> getPercentageHistory({
    required String categoryId,
    required String groupId,
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

  // ========== Category Budget Operations (Feature 004) ==========

  @override
  Future<List> getCategoryBudgets({
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabaseClient
          .from('category_budgets')
          .select('*, expense_categories(name)')
          .eq('group_id', groupId)
          .eq('year', year)
          .eq('month', month)
          .order('expense_categories(name)', ascending: true);

      return response as List;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get category budgets: $e');
    }
  }

  @override
  Future<dynamic> getCategoryBudget({
    required String categoryId,
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabaseClient
          .from('category_budgets')
          .select()
          .eq('category_id', categoryId)
          .eq('group_id', groupId)
          .eq('year', year)
          .eq('month', month)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get category budget: $e');
    }
  }

  @override
  Future<dynamic> createCategoryBudget({
    required String categoryId,
    required String groupId,
    required int amount,
    required int month,
    required int year,
    bool isGroupBudget = true,
  }) async {
    try {
      final userId = _currentUserId;

      final response = await supabaseClient.from('category_budgets').insert({
        'category_id': categoryId,
        'group_id': groupId,
        'amount': amount,
        'month': month,
        'year': year,
        'created_by': userId,
        'is_group_budget': isGroupBudget,
        // For personal budgets, set user_id (required by check constraint)
        if (!isGroupBudget) 'user_id': userId,
      }).select().single();

      return response;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to create category budget: $e');
    }
  }

  @override
  Future<dynamic> updateCategoryBudget({
    required String budgetId,
    required int amount,
  }) async {
    try {
      final response = await supabaseClient
          .from('category_budgets')
          .update({'amount': amount, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', budgetId)
          .select()
          .single();

      return response;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to update category budget: $e');
    }
  }

  @override
  Future<void> deleteCategoryBudget(String budgetId) async {
    try {
      await supabaseClient.from('category_budgets').delete().eq('id', budgetId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to delete category budget: $e');
    }
  }

  @override
  Future<dynamic> getCategoryBudgetStats({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'get_category_budget_stats',
        params: {
          'p_group_id': groupId,
          'p_category_id': categoryId,
          'p_year': year,
          'p_month': month,
        },
      ).single();

      return response;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get category budget stats: $e');
    }
  }

  @override
  Future<dynamic> getOverallGroupBudgetStats({
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'get_overall_group_budget_stats',
        params: {
          'p_group_id': groupId,
          'p_year': year,
          'p_month': month,
        },
      ).single();

      return response;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get overall budget stats: $e');
    }
  }

  // ========== Percentage Budget Operations (Feature 004 Extension) ==========

  @override
  Future<List> getGroupMembersWithPercentages({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'get_group_members_with_percentages',
        params: {
          'p_group_id': groupId,
          'p_category_id': categoryId,
          'p_year': year,
          'p_month': month,
        },
      );

      return response as List;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get group members with percentages: $e');
    }
  }

  @override
  Future<int> calculatePercentageBudget({
    required int groupBudgetAmount,
    required double percentage,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'calculate_percentage_budget',
        params: {
          'p_group_budget_amount': groupBudgetAmount,
          'p_percentage': percentage,
        },
      );

      return response as int;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to calculate percentage budget: $e');
    }
  }

  @override
  Future<List> getBudgetChangeNotifications({
    required String groupId,
    required int year,
    required int month,
    String? userId,
  }) async {
    try {
      final response = await supabaseClient.rpc(
        'get_budget_change_notifications',
        params: {
          'p_group_id': groupId,
          'p_year': year,
          'p_month': month,
          if (userId != null) 'p_user_id': userId,
        },
      );

      return response as List;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get budget change notifications: $e');
    }
  }

  @override
  Future<dynamic> setPersonalPercentageBudget({
    required String categoryId,
    required String groupId,
    required String userId,
    required double percentage,
    required int month,
    required int year,
  }) async {
    try {
      final currentUserId = _currentUserId;

      // First, get the current group budget to calculate amount
      final groupBudget = await getCategoryBudget(
        categoryId: categoryId,
        groupId: groupId,
        year: year,
        month: month,
      );

      int calculatedAmount = 0;
      if (groupBudget != null && groupBudget['amount'] != null) {
        calculatedAmount = await calculatePercentageBudget(
          groupBudgetAmount: groupBudget['amount'] as int,
          percentage: percentage,
        );
      }

      // Check if budget exists
      final existingBudget = await supabaseClient
          .from('category_budgets')
          .select()
          .eq('category_id', categoryId)
          .eq('group_id', groupId)
          .eq('year', year)
          .eq('month', month)
          .eq('user_id', userId)
          .eq('is_group_budget', false)
          .maybeSingle();

      final response = await supabaseClient.from('category_budgets').upsert({
        if (existingBudget != null) 'id': existingBudget['id'],
        'category_id': categoryId,
        'group_id': groupId,
        'user_id': userId,
        'year': year,
        'month': month,
        'amount': calculatedAmount, // Fallback amount
        'is_group_budget': false,
        'budget_type': 'PERCENTAGE',
        'percentage_of_group': percentage,
        'calculated_amount': calculatedAmount,
        'created_by': currentUserId,
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return response;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to set personal percentage budget: $e');
    }
  }

  @override
  Future<double?> getPreviousMonthPercentage({
    required String categoryId,
    required String groupId,
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      // Calculate previous month
      int prevMonth = month - 1;
      int prevYear = year;
      if (prevMonth < 1) {
        prevMonth = 12;
        prevYear = year - 1;
      }

      final response = await supabaseClient
          .from('category_budgets')
          .select('percentage_of_group')
          .eq('category_id', categoryId)
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .eq('year', prevYear)
          .eq('month', prevMonth)
          .eq('is_group_budget', false)
          .eq('budget_type', 'PERCENTAGE')
          .maybeSingle();

      if (response == null) return null;

      final percentageValue = response['percentage_of_group'];
      return percentageValue != null ? (percentageValue as num).toDouble() : null;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get previous month percentage: $e');
    }
  }

  @override
  Future<List> getPercentageHistory({
    required String categoryId,
    required String groupId,
    required String userId,
    int? limit,
  }) async {
    try {
      var query = supabaseClient
          .from('budget_percentage_history')
          .select()
          .eq('category_id', categoryId)
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .order('changed_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return response as List;
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    } catch (e) {
      throw ServerException('Failed to get percentage history: $e');
    }
  }
}
