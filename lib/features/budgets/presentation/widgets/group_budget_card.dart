import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_provider.dart';
import 'budget_progress_bar.dart';
import 'budget_warning_indicator.dart';
import 'no_budget_set_card.dart';

/// Group budget card for displaying on dashboard
class GroupBudgetCard extends ConsumerWidget {
  const GroupBudgetCard({
    super.key,
    required this.groupId,
    required this.userId,
    this.onNavigateToSettings,
  });

  final String groupId;
  final String userId;
  final VoidCallback? onNavigateToSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetState = ref.watch(budgetProvider((groupId: groupId, userId: userId)));

    if (budgetState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // No budget set
    if (budgetState.groupBudget == null) {
      return NoBudgetSetCard(
        budgetType: 'group',
        onSetBudget: onNavigateToSettings ?? () {},
      );
    }

    // Budget is set - show progress
    return Card(
      child: InkWell(
        onTap: onNavigateToSettings,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Group Budget',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (onNavigateToSettings != null)
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              BudgetProgressBar(
                budgetAmount: budgetState.groupStats.budgetAmount ?? 0,
                spentAmount: budgetState.groupStats.spentAmount,
              ),
              const SizedBox(height: 12),
              BudgetWarningIndicator(
                isNearLimit: budgetState.groupStats.isNearLimit,
                isOverBudget: budgetState.groupStats.isOverBudget,
                remainingAmount: budgetState.groupStats.remainingAmount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
