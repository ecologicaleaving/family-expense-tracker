// Riverpod Provider: Budget Change Notification Provider
// Feature: Italian Categories and Budget Management (004)
// Provides notifications about budget changes affecting user's percentage budgets

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/presentation/providers/category_budget_provider.dart';
import '../../data/models/budget_change_notification_model.dart';

/// Provider for budget change notifications for current user
final budgetChangeNotificationProvider = FutureProvider.family<
    List<BudgetChangeNotificationModel>,
    ({
      String groupId,
      int year,
      int month,
      String? userId,
    })>(
  (ref, params) async {
    final repository = ref.watch(budgetRepositoryProvider);

    // Use provided userId or get from auth
    final userId = params.userId ?? ref.watch(currentUserIdProvider);

    final result = await repository.getBudgetChangeNotifications(
      groupId: params.groupId,
      year: params.year,
      month: params.month,
      userId: userId,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (notifications) => (notifications as List)
          .map((json) => BudgetChangeNotificationModel.fromJson(json))
          .toList(),
    );
  },
);

/// Convenience provider for current month budget change notifications
final currentMonthBudgetChangeNotificationsProvider =
    FutureProvider.family<List<BudgetChangeNotificationModel>, String>(
  (ref, groupId) {
    final now = DateTime.now();

    return ref.watch(
      budgetChangeNotificationProvider((
        groupId: groupId,
        year: now.year,
        month: now.month,
        userId: null, // Will use current user from auth
      )).future,
    );
  },
);
