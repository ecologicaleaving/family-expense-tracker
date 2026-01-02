import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/budget_calculator.dart';
import '../../../../core/utils/timezone_handler.dart';
import '../../domain/entities/budget_stats_entity.dart';
import '../../domain/entities/group_budget_entity.dart';
import '../../domain/entities/personal_budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import 'budget_repository_provider.dart';

/// State for budget management
class BudgetState {
  const BudgetState({
    this.groupBudget,
    this.personalBudget,
    required this.groupStats,
    required this.personalStats,
    this.isLoading = false,
    this.errorMessage,
    this.pendingSyncExpenseIds = const [],
  });

  final GroupBudgetEntity? groupBudget;
  final PersonalBudgetEntity? personalBudget;
  final BudgetStatsEntity groupStats;
  final BudgetStatsEntity personalStats;
  final bool isLoading;
  final String? errorMessage;
  final List<String> pendingSyncExpenseIds;

  BudgetState copyWith({
    GroupBudgetEntity? groupBudget,
    PersonalBudgetEntity? personalBudget,
    BudgetStatsEntity? groupStats,
    BudgetStatsEntity? personalStats,
    bool? isLoading,
    String? errorMessage,
    List<String>? pendingSyncExpenseIds,
  }) {
    return BudgetState(
      groupBudget: groupBudget ?? this.groupBudget,
      personalBudget: personalBudget ?? this.personalBudget,
      groupStats: groupStats ?? this.groupStats,
      personalStats: personalStats ?? this.personalStats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pendingSyncExpenseIds: pendingSyncExpenseIds ?? this.pendingSyncExpenseIds,
    );
  }

  factory BudgetState.initial() {
    return BudgetState(
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
  ) : super(BudgetState.initial()) {
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

      // Load group budget
      final groupBudgetResult = await _repository.getGroupBudget(
        groupId: _groupId,
        month: month,
        year: year,
      );

      // Load personal budget
      final personalBudgetResult = await _repository.getPersonalBudget(
        userId: _userId,
        month: month,
        year: year,
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

      groupBudgetResult.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
        (groupBudget) {
          personalBudgetResult.fold(
            (failure) => state = state.copyWith(
              isLoading: false,
              errorMessage: failure.message,
            ),
            (personalBudget) {
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
                        groupBudget: groupBudget,
                        personalBudget: personalBudget,
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
    final groupExpenses = currentMonthExpenses
        .where((e) => e.isGroupExpense)
        .map((e) => e.amount)
        .toList();

    final groupSpent = BudgetCalculator.calculateSpentAmount(groupExpenses);
    final groupBudgetAmount = state.groupBudget?.amount ?? 0;

    final groupStats = BudgetStatsEntity(
      budgetId: state.groupBudget?.id,
      budgetAmount: state.groupBudget?.amount,
      spentAmount: groupSpent,
      remainingAmount: state.groupBudget != null
          ? BudgetCalculator.calculateRemainingAmount(
              groupBudgetAmount,
              groupSpent,
            )
          : null,
      percentageUsed: state.groupBudget != null
          ? BudgetCalculator.calculatePercentageUsed(
              groupBudgetAmount,
              groupSpent,
            )
          : null,
      isOverBudget: state.groupBudget != null
          ? BudgetCalculator.isOverBudget(groupBudgetAmount, groupSpent)
          : false,
      isNearLimit: state.groupBudget != null
          ? BudgetCalculator.isNearLimit(groupBudgetAmount, groupSpent)
          : false,
      expenseCount: groupExpenses.length,
    );

    // Calculate personal budget stats (user's expenses: both personal + group)
    final personalExpenses = currentMonthExpenses
        .where((e) => e.createdBy == _userId)
        .map((e) => e.amount)
        .toList();

    final personalSpent = BudgetCalculator.calculateSpentAmount(personalExpenses);
    final personalBudgetAmount = state.personalBudget?.amount ?? 0;

    final personalStats = BudgetStatsEntity(
      budgetId: state.personalBudget?.id,
      budgetAmount: state.personalBudget?.amount,
      spentAmount: personalSpent,
      remainingAmount: state.personalBudget != null
          ? BudgetCalculator.calculateRemainingAmount(
              personalBudgetAmount,
              personalSpent,
            )
          : null,
      percentageUsed: state.personalBudget != null
          ? BudgetCalculator.calculatePercentageUsed(
              personalBudgetAmount,
              personalSpent,
            )
          : null,
      isOverBudget: state.personalBudget != null
          ? BudgetCalculator.isOverBudget(personalBudgetAmount, personalSpent)
          : false,
      isNearLimit: state.personalBudget != null
          ? BudgetCalculator.isNearLimit(personalBudgetAmount, personalSpent)
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
