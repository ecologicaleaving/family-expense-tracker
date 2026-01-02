import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../domain/entities/group_budget_entity.dart';
import '../../domain/entities/personal_budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_provider.dart';
import 'budget_repository_provider.dart';

/// Actions for budget operations
class BudgetActions {
  BudgetActions(this._ref);

  final Ref _ref;

  /// Set or update group budget
  Future<GroupBudgetEntity?> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  }) async {
    final repository = _ref.read(budgetRepositoryProvider);

    final result = await repository.setGroupBudget(
      groupId: groupId,
      amount: amount,
      month: month,
      year: year,
    );

    return result.fold(
      (failure) {
        // Handle error
        return null;
      },
      (budget) {
        // Refresh budget state
        final userId = _ref.read(currentUserIdProvider);
        _ref.read(budgetProvider((groupId: groupId, userId: userId)).notifier).loadBudgets();
        return budget;
      },
    );
  }

  /// Set or update personal budget
  Future<PersonalBudgetEntity?> setPersonalBudget({
    required String userId,
    required int amount,
    required int month,
    required int year,
  }) async {
    final repository = _ref.read(budgetRepositoryProvider);

    final result = await repository.setPersonalBudget(
      userId: userId,
      amount: amount,
      month: month,
      year: year,
    );

    return result.fold(
      (failure) {
        // Handle error
        return null;
      },
      (budget) {
        // Refresh budget state
        final groupId = _ref.read(currentGroupIdProvider);
        _ref.read(budgetProvider((groupId: groupId, userId: userId)).notifier).loadBudgets();
        return budget;
      },
    );
  }

}

/// Provider for budget actions
final budgetActionsProvider = Provider<BudgetActions>((ref) {
  return BudgetActions(ref);
});
