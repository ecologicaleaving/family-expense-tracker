import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_provider.dart';
import 'budget_progress_bar.dart';
import 'budget_warning_indicator.dart';
import 'no_budget_set_card.dart';

/// Personal budget card for displaying on dashboard
class PersonalBudgetCard extends ConsumerWidget {
  const PersonalBudgetCard({
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
    if (budgetState.personalBudget == null) {
      return NoBudgetSetCard(
        budgetType: 'personal',
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
                        Icons.person_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Personal Budget',
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
                budgetAmount: budgetState.personalStats.budgetAmount ?? 0,
                spentAmount: budgetState.personalStats.spentAmount,
              ),
              const SizedBox(height: 12),
              BudgetWarningIndicator(
                isNearLimit: budgetState.personalStats.isNearLimit,
                isOverBudget: budgetState.personalStats.isOverBudget,
                remainingAmount: budgetState.personalStats.remainingAmount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
