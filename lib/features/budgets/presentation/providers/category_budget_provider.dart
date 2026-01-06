// Riverpod Provider: Category Budget Provider
// Feature: Italian Categories and Budget Management (004)
// Task: T031

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/budget_repository.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/datasources/budget_remote_datasource.dart';

/// Provider for Supabase client
final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for budget remote datasource
final budgetRemoteDataSourceProvider = Provider<BudgetRemoteDataSource>((ref) {
  return BudgetRemoteDataSourceImpl(
    supabaseClient: ref.watch(_supabaseClientProvider),
  );
});

/// Provider for budget repository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    remoteDataSource: ref.watch(budgetRemoteDataSourceProvider),
  );
});

/// State for category budgets
class CategoryBudgetState {
  const CategoryBudgetState({
    this.budgets = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<dynamic> budgets; // Using dynamic until we have proper models
  final bool isLoading;
  final String? errorMessage;

  CategoryBudgetState copyWith({
    List<dynamic>? budgets,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoryBudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier for category budgets
class CategoryBudgetNotifier extends StateNotifier<CategoryBudgetState> {
  CategoryBudgetNotifier(
    this._repository,
    this._groupId,
    this._year,
    this._month,
  ) : super(const CategoryBudgetState()) {
    loadBudgets();
  }

  final BudgetRepository _repository;
  final String _groupId;
  final int _year;
  final int _month;

  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getCategoryBudgets(
      groupId: _groupId,
      year: _year,
      month: _month,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (budgets) => state = state.copyWith(
        budgets: budgets,
        isLoading: false,
      ),
    );
  }

  Future<bool> createBudget({
    required String categoryId,
    required int amount,
    bool isGroupBudget = true, // Default to group budget for backward compatibility
  }) async {
    final result = await _repository.createCategoryBudget(
      categoryId: categoryId,
      groupId: _groupId,
      amount: amount,
      month: _month,
      year: _year,
      isGroupBudget: isGroupBudget,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        loadBudgets(); // Reload after creation
        return true;
      },
    );
  }

  Future<bool> updateBudget({
    required String budgetId,
    required int amount,
  }) async {
    final result = await _repository.updateCategoryBudget(
      budgetId: budgetId,
      amount: amount,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        loadBudgets(); // Reload after update
        return true;
      },
    );
  }

  Future<bool> deleteBudget(String budgetId) async {
    final result = await _repository.deleteCategoryBudget(budgetId);

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        loadBudgets(); // Reload after deletion
        return true;
      },
    );
  }

  // ========== Percentage Budget Operations (Feature 004 Extension) ==========

  /// Set personal percentage budget for a category
  Future<bool> setPersonalPercentageBudget({
    required String categoryId,
    required String userId,
    required double percentage,
  }) async {
    final result = await _repository.setPersonalPercentageBudget(
      categoryId: categoryId,
      groupId: _groupId,
      userId: userId,
      percentage: percentage,
      month: _month,
      year: _year,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        loadBudgets(); // Reload after setting percentage budget
        return true;
      },
    );
  }

  /// Get percentage from previous month (for auto-fill)
  Future<double?> getPreviousMonthPercentage({
    required String categoryId,
    required String userId,
  }) async {
    final result = await _repository.getPreviousMonthPercentage(
      categoryId: categoryId,
      groupId: _groupId,
      userId: userId,
      year: _year,
      month: _month,
    );

    return result.fold(
      (failure) {
        // Don't set error state for this - it's optional
        return null;
      },
      (percentage) => percentage,
    );
  }
}

/// Provider for category budgets (family pattern for different months)
final categoryBudgetProvider = StateNotifierProvider.family<
    CategoryBudgetNotifier,
    CategoryBudgetState,
    ({String groupId, int year, int month})>(
  (ref, params) {
    final repository = ref.watch(budgetRepositoryProvider);

    return CategoryBudgetNotifier(
      repository,
      params.groupId,
      params.year,
      params.month,
    );
  },
);

/// Provider for current month budgets (convenience)
final currentMonthBudgetsProvider = Provider.family<AsyncValue<List<dynamic>>, String>(
  (ref, groupId) {
    final now = DateTime.now();
    final state = ref.watch(
      categoryBudgetProvider((groupId: groupId, year: now.year, month: now.month)),
    );

    if (state.isLoading) {
      return const AsyncValue.loading();
    } else if (state.errorMessage != null) {
      return AsyncValue.error(state.errorMessage!, StackTrace.current);
    } else {
      return AsyncValue.data(state.budgets);
    }
  },
);
