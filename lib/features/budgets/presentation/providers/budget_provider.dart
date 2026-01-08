import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/budget_calculator.dart';
import '../../../../core/utils/timezone_handler.dart';
import '../../domain/entities/budget_stats_entity.dart';
import '../../domain/entities/computed_budget_totals_entity.dart';
import '../../domain/entities/group_budget_entity.dart';
import '../../domain/entities/personal_budget_entity.dart';
import '../../domain/entities/virtual_group_expenses_category_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import 'budget_repository_provider.dart';

/// State for budget management
class BudgetState {
  const BudgetState({
    required this.computedTotals,
    this.virtualGroupCategory,
    required this.groupStats,
    required this.personalStats,
    this.isLoading = false,
    this.errorMessage,
    this.pendingSyncExpenseIds = const [],
  });

  /// Computed budget totals (replaces manual groupBudget and personalBudget)
  final ComputedBudgetTotals computedTotals;

  /// Virtual "Spese di Gruppo" category (only for personal budget view)
  final VirtualGroupExpensesCategory? virtualGroupCategory;

  final BudgetStatsEntity groupStats;
  final BudgetStatsEntity personalStats;
  final bool isLoading;
  final String? errorMessage;
  final List<String> pendingSyncExpenseIds;

  /// @deprecated Use computedTotals.totalGroupBudget instead
  @Deprecated('Use computedTotals.totalGroupBudget')
  int get groupBudgetAmount => computedTotals.totalGroupBudget;

  /// @deprecated Use computedTotals.totalPersonalBudget instead
  @Deprecated('Use computedTotals.totalPersonalBudget')
  int get personalBudgetAmount => computedTotals.totalPersonalBudget;

  BudgetState copyWith({
    ComputedBudgetTotals? computedTotals,
    VirtualGroupExpensesCategory? virtualGroupCategory,
    BudgetStatsEntity? groupStats,
    BudgetStatsEntity? personalStats,
    bool? isLoading,
    String? errorMessage,
    List<String>? pendingSyncExpenseIds,
    bool clearVirtualGroupCategory = false,
  }) {
    return BudgetState(
      computedTotals: computedTotals ?? this.computedTotals,
      virtualGroupCategory: clearVirtualGroupCategory ? null : (virtualGroupCategory ?? this.virtualGroupCategory),
      groupStats: groupStats ?? this.groupStats,
      personalStats: personalStats ?? this.personalStats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pendingSyncExpenseIds: pendingSyncExpenseIds ?? this.pendingSyncExpenseIds,
    );
  }

  factory BudgetState.initial({
    required String groupId,
    required String userId,
  }) {
    final now = DateTime.now();
    return BudgetState(
      computedTotals: ComputedBudgetTotals.empty(
        groupId: groupId,
        userId: userId,
        month: now.month,
        year: now.year,
      ),
      groupStats: BudgetStatsEntity(
        spentAmount: 0,
        isOverBudget: false,
        isNearLimit: false,
        expenseCount: 0,
      ),
      personalStats: BudgetStatsEntity(
        spentAmount: 0,
        isOverBudget: false,
        isNearLimit: false,
        expenseCount: 0,
      ),
    );
  }
}

/// Budget provider for managing budget state
class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier(
    this._repository,
    this._supabaseClient,
    this._groupId,
    this._userId,
  ) : super(BudgetState.initial(groupId: _groupId, userId: _userId)) {
    _init();
  }

  final BudgetRepository _repository;
  final SupabaseClient _supabaseClient;
  final String _groupId;
  final String _userId;

  RealtimeChannel? _expensesChannel;
  List<ExpenseEntity> _cachedExpenses = [];

  Future<void> _init() async {
    await loadBudgets();
    _subscribeToRealtimeChanges();
  }

  /// Load budgets and stats for current month
  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final now = DateTime.now();
      final month = now.month;
      final year = now.year;

      // Load computed budget totals (replaces getGroupBudget/getPersonalBudget)
      final computedTotalsResult = await _repository.getComputedBudgetTotals(
        groupId: _groupId,
        userId: _userId,
        year: year,
        month: month,
      );

      // Calculate virtual group expenses category for personal budget view
      final virtualCategoryResult = await _repository.calculateVirtualGroupCategory(
        groupId: _groupId,
        userId: _userId,
        year: year,
        month: month,
      );

      // Load group budget stats
      final groupStatsResult = await _repository.getGroupBudgetStats(
        groupId: _groupId,
        month: month,
        year: year,
      );

      // Load personal budget stats
      final personalStatsResult = await _repository.getPersonalBudgetStats(
        userId: _userId,
        month: month,
        year: year,
      );

      // Process results
      computedTotalsResult.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (computedTotals) {
          virtualCategoryResult.fold(
            (failure) {
              // Virtual category is optional, continue with null
              groupStatsResult.fold(
                (failure) => state = state.copyWith(
                  isLoading: false,
                  errorMessage: failure.message,
                ),
                (groupStats) {
                  personalStatsResult.fold(
                    (failure) => state = state.copyWith(
                      isLoading: false,
                      errorMessage: failure.message,
                    ),
                    (personalStats) {
                      state = state.copyWith(
                        computedTotals: computedTotals,
                        virtualGroupCategory: null, // Failed to load
                        groupStats: groupStats,
                        personalStats: personalStats,
                        isLoading: false,
                      );
                    },
                  );
                },
              );
            },
            (virtualCategory) {
              groupStatsResult.fold(
                (failure) => state = state.copyWith(
                  isLoading: false,
                  errorMessage: failure.message,
                ),
                (groupStats) {
                  personalStatsResult.fold(
                    (failure) => state = state.copyWith(
                      isLoading: false,
                      errorMessage: failure.message,
                    ),
                    (personalStats) {
                      state = state.copyWith(
                        computedTotals: computedTotals,
                        virtualGroupCategory: virtualCategory,
                        groupStats: groupStats,
                        personalStats: personalStats,
                        isLoading: false,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load budgets: $e',
      );
    }
  }

  /// Optimistically add expense (instant UI update)
  void optimisticallyAddExpense(ExpenseEntity expense) {
    final pendingIds = [...state.pendingSyncExpenseIds, expense.id];
    state = state.copyWith(pendingSyncExpenseIds: pendingIds);

    // Add to cache
    _cachedExpenses = [expense, ..._cachedExpenses];

    // Recalculate budget with optimistic data
    _recalculateBudgetStats(isOptimistic: true);
  }

  /// Optimistically update expense
  void optimisticallyUpdateExpense(ExpenseEntity expense) {
    final pendingIds = [...state.pendingSyncExpenseIds, expense.id];
    state = state.copyWith(pendingSyncExpenseIds: pendingIds);

    // Update in cache
    _cachedExpenses = _cachedExpenses.map((e) {
      return e.id == expense.id ? expense : e;
    }).toList();

    // Recalculate budget
    _recalculateBudgetStats(isOptimistic: true);
  }

  /// Optimistically delete expense
  void optimisticallyDeleteExpense(String expenseId) {
    final pendingIds = [...state.pendingSyncExpenseIds, expenseId];
    state = state.copyWith(pendingSyncExpenseIds: pendingIds);

    // Remove from cache
    _cachedExpenses = _cachedExpenses.where((e) => e.id != expenseId).toList();

    // Recalculate budget
    _recalculateBudgetStats(isOptimistic: true);
  }

  /// Confirm sync completed
  void confirmExpenseSync(String expenseId) {
    final pendingIds = state.pendingSyncExpenseIds
        .where((id) => id != expenseId)
        .toList();

    state = state.copyWith(
      pendingSyncExpenseIds: pendingIds,
      errorMessage: null,
    );

    if (pendingIds.isEmpty) {
      _recalculateBudgetStats(isOptimistic: false);
    }
  }

  /// Rollback on sync failure
  void rollbackExpense(ExpenseEntity expense, String errorMessage) {
    final pendingIds = state.pendingSyncExpenseIds
        .where((id) => id != expense.id)
        .toList();

    // Remove from cache
    _cachedExpenses = _cachedExpenses
        .where((e) => e.id != expense.id)
        .toList();

    state = state.copyWith(
      pendingSyncExpenseIds: pendingIds,
      errorMessage: errorMessage,
    );

    _recalculateBudgetStats(isOptimistic: false);
  }

  /// Recalculate budget statistics from cached expenses
  void _recalculateBudgetStats({bool isOptimistic = false}) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Filter expenses for current month
    final currentMonthExpenses = _cachedExpenses.where((e) {
      return e.date.year == currentYear && e.date.month == currentMonth;
    }).toList();

    // Calculate group budget stats
    // Convert expense amounts from euros to cents for consistency with budget storage
    final groupExpenses = currentMonthExpenses
        .where((e) => e.isGroupExpense)
        .map((e) => e.amount)
        .toList();

    final groupSpentCents = groupExpenses.fold<int>(
      0,
      (sum, euroAmount) => sum + (euroAmount * 100).round(),
    );
    final groupBudgetAmount = state.groupBudget?.amount ?? 0;

    final groupStats = BudgetStatsEntity(
      budgetId: state.groupBudget?.id,
      budgetAmount: state.groupBudget?.amount,
      spentAmount: groupSpentCents,
      remainingAmount: state.groupBudget != null
          ? groupBudgetAmount - groupSpentCents
          : null,
      percentageUsed: state.groupBudget != null
          ? (groupBudgetAmount > 0 ? (groupSpentCents / groupBudgetAmount * 100) : 0.0)
          : null,
      isOverBudget: state.groupBudget != null
          ? groupSpentCents >= groupBudgetAmount
          : false,
      isNearLimit: state.groupBudget != null
          ? (groupBudgetAmount > 0 && (groupSpentCents / groupBudgetAmount) >= 0.8)
          : false,
      expenseCount: groupExpenses.length,
    );

    // Calculate personal budget stats (user's expenses: both personal + group)
    // Convert expense amounts from euros to cents for consistency with budget storage
    final personalExpenses = currentMonthExpenses
        .where((e) => e.createdBy == _userId)
        .map((e) => e.amount)
        .toList();

    final personalSpentCents = personalExpenses.fold<int>(
      0,
      (sum, euroAmount) => sum + (euroAmount * 100).round(),
    );
    final personalBudgetAmount = state.personalBudget?.amount ?? 0;

    final personalStats = BudgetStatsEntity(
      budgetId: state.personalBudget?.id,
      budgetAmount: state.personalBudget?.amount,
      spentAmount: personalSpentCents,
      remainingAmount: state.personalBudget != null
          ? personalBudgetAmount - personalSpentCents
          : null,
      percentageUsed: state.personalBudget != null
          ? (personalBudgetAmount > 0 ? (personalSpentCents / personalBudgetAmount * 100) : 0.0)
          : null,
      isOverBudget: state.personalBudget != null
          ? personalSpentCents >= personalBudgetAmount
          : false,
      isNearLimit: state.personalBudget != null
          ? (personalBudgetAmount > 0 && (personalSpentCents / personalBudgetAmount) >= 0.8)
          : false,
      expenseCount: personalExpenses.length,
    );

    state = state.copyWith(
      groupStats: groupStats,
      personalStats: personalStats,
    );
  }

  /// Subscribe to Supabase realtime for multi-device sync
  void _subscribeToRealtimeChanges() {
    _expensesChannel = _supabaseClient
        .channel('expenses-changes-$_groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: _groupId,
          ),
          callback: _handleRealtimeChange,
        )
        .subscribe();
  }

  /// Handle incoming realtime events from other devices
  void _handleRealtimeChange(PostgresChangePayload payload) {
    final now = DateTime.now();

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        // Only process if not pending locally
        final expenseId = payload.newRecord['id'] as String;
        if (!state.pendingSyncExpenseIds.contains(expenseId)) {
          // Reload budgets to get updated stats
          loadBudgets();
        }
        break;

      case PostgresChangeEvent.update:
        final expenseId = payload.newRecord['id'] as String;
        if (!state.pendingSyncExpenseIds.contains(expenseId)) {
          loadBudgets();
        }
        break;

      case PostgresChangeEvent.delete:
        final expenseId = payload.oldRecord['id'] as String;
        if (!state.pendingSyncExpenseIds.contains(expenseId)) {
          loadBudgets();
        }
        break;

      case PostgresChangeEvent.all:
        // Handle 'all' events by reloading
        loadBudgets();
        break;
    }
  }

  @override
  void dispose() {
    _expensesChannel?.unsubscribe();
    super.dispose();
  }
}

/// Provider for budget state
final budgetProvider = StateNotifierProvider.family<BudgetNotifier, BudgetState, ({String groupId, String userId})>(
  (ref, params) {
    final supabaseClient = Supabase.instance.client;
    final repository = ref.watch(budgetRepositoryProvider);

    return BudgetNotifier(
      repository,
      supabaseClient,
      params.groupId,
      params.userId,
    );
  },
);
