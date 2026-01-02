import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/presentation/providers/budget_actions_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../domain/entities/expense_entity.dart';
import 'expense_provider.dart';

/// Coordinated expense actions that integrate with budget provider
class ExpenseActions {
  ExpenseActions(this._ref);

  final Ref _ref;

  /// Create expense with budget optimistic update
  Future<ExpenseEntity?> createExpenseWithBudgetUpdate({
    required double amount,
    required DateTime date,
    required ExpenseCategory category,
    bool isGroupExpense = true,
    String? merchant,
    String? notes,
    Uint8List? receiptImage,
  }) async {
    // Create optimistic expense entity
    final optimisticExpense = ExpenseEntity(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      groupId: _ref.read(currentGroupIdProvider),
      createdBy: _ref.read(currentUserIdProvider),
      amount: amount,
      date: date,
      category: category,
      isGroupExpense: isGroupExpense,
      merchant: merchant,
      notes: notes,
    );

    // 1. IMMEDIATE: Optimistically update budget (0ms)
    final groupId = _ref.read(currentGroupIdProvider);
    final userId = _ref.read(currentUserIdProvider);
    _ref
        .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
        .optimisticallyAddExpense(optimisticExpense);

    // 2. IMMEDIATE: Optimistically update expense list
    _ref.read(expenseListProvider.notifier).addExpense(optimisticExpense);

    // 3. BACKGROUND: Actually create in Supabase
    final result = await _ref.read(expenseFormProvider.notifier).createExpense(
          amount: amount,
          date: date,
          category: category,
          merchant: merchant,
          notes: notes,
          receiptImage: receiptImage,
        );

    if (result != null) {
      // SUCCESS: Confirm sync
      _ref
          .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
          .confirmExpenseSync(optimisticExpense.id);
      _ref.read(expenseListProvider.notifier).updateExpenseInList(result);
      return result;
    } else {
      // FAILURE: Rollback
      final errorMessage = _ref.read(expenseFormProvider).errorMessage ??
          'Failed to create expense';
      _ref
          .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
          .rollbackExpense(optimisticExpense, errorMessage);
      _ref.read(expenseListProvider.notifier).removeExpenseFromList(optimisticExpense.id);
      return null;
    }
  }

  /// Update expense with budget optimistic update
  Future<ExpenseEntity?> updateExpenseWithBudgetUpdate({
    required ExpenseEntity currentExpense,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? merchant,
    String? notes,
  }) async {
    // Create updated expense entity for optimistic update
    final updatedExpense = currentExpense.copyWith(
      amount: amount,
      date: date,
      category: category,
      merchant: merchant,
      notes: notes,
    );

    // 1. IMMEDIATE: Optimistically update budget
    final groupId = _ref.read(currentGroupIdProvider);
    final userId = _ref.read(currentUserIdProvider);
    _ref
        .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
        .optimisticallyUpdateExpense(updatedExpense);

    // 2. IMMEDIATE: Optimistically update expense list
    _ref.read(expenseListProvider.notifier).updateExpenseInList(updatedExpense);

    // 3. BACKGROUND: Actually update in Supabase
    final result = await _ref.read(expenseFormProvider.notifier).updateExpense(
          expenseId: currentExpense.id,
          amount: amount,
          date: date,
          category: category,
          merchant: merchant,
          notes: notes,
        );

    if (result != null) {
      // SUCCESS: Confirm sync
      _ref
          .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
          .confirmExpenseSync(currentExpense.id);
      return result;
    } else {
      // FAILURE: Rollback
      final errorMessage = _ref.read(expenseFormProvider).errorMessage ??
          'Failed to update expense';
      _ref
          .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
          .rollbackExpense(currentExpense, errorMessage);
      _ref.read(expenseListProvider.notifier).updateExpenseInList(currentExpense);
      return null;
    }
  }

  /// Delete expense with budget optimistic update
  Future<bool> deleteExpenseWithBudgetUpdate({
    required String expenseId,
  }) async {
    // 1. IMMEDIATE: Optimistically update budget
    final groupId = _ref.read(currentGroupIdProvider);
    final userId = _ref.read(currentUserIdProvider);
    _ref
        .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
        .optimisticallyDeleteExpense(expenseId);

    // 2. IMMEDIATE: Optimistically update expense list
    _ref.read(expenseListProvider.notifier).removeExpenseFromList(expenseId);

    // 3. BACKGROUND: Actually delete in Supabase
    final success = await _ref.read(expenseFormProvider.notifier).deleteExpense(
          expenseId: expenseId,
        );

    if (success) {
      // SUCCESS: Confirm sync
      _ref
          .read(budgetProvider((groupId: groupId, userId: userId)).notifier)
          .confirmExpenseSync(expenseId);
      return true;
    } else {
      // FAILURE: Rollback (reload expense list and budgets)
      _ref.read(expenseListProvider.notifier).refresh();
      _ref.read(budgetProvider((groupId: groupId, userId: userId)).notifier).loadBudgets();
      return false;
    }
  }
}

/// Provider for coordinated expense actions
final expenseActionsProvider = Provider<ExpenseActions>((ref) {
  return ExpenseActions(ref);
});
