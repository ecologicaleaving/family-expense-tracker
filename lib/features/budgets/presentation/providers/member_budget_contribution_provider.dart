// Riverpod Provider: Member Budget Contribution Provider
// Feature: Italian Categories and Budget Management (004)
// Provides list of group members with their percentage budget contributions

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../budgets/presentation/providers/category_budget_provider.dart';
import '../../data/models/member_budget_contribution_model.dart';

/// Provider for group members with percentage contributions for a specific category
final memberBudgetContributionProvider = FutureProvider.family<
    List<MemberBudgetContributionModel>,
    ({
      String groupId,
      String categoryId,
      int year,
      int month,
    })>(
  (ref, params) async {
    final repository = ref.watch(budgetRepositoryProvider);

    final result = await repository.getGroupMembersWithPercentages(
      groupId: params.groupId,
      categoryId: params.categoryId,
      year: params.year,
      month: params.month,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (members) => (members as List)
          .map((json) => MemberBudgetContributionModel.fromJson(json))
          .toList(),
    );
  },
);

/// Convenience provider for current month member contributions
final currentMonthMemberContributionProvider = FutureProvider.family<
    List<MemberBudgetContributionModel>,
    ({String groupId, String categoryId})>(
  (ref, params) {
    final now = DateTime.now();

    return ref.watch(
      memberBudgetContributionProvider((
        groupId: params.groupId,
        categoryId: params.categoryId,
        year: now.year,
        month: now.month,
      )).future,
    );
  },
);
