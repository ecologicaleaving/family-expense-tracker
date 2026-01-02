import 'package:flutter/material.dart';

import '../../../../core/utils/budget_calculator.dart';

/// Budget progress bar widget with percentage calculation and color coding
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.budgetAmount,
    required this.spentAmount,
    this.height = 8.0,
    this.showPercentage = true,
  });

  final int budgetAmount;
  final int spentAmount;
  final double height;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = BudgetCalculator.calculatePercentageUsed(
      budgetAmount,
      spentAmount,
    );
    final isOverBudget = BudgetCalculator.isOverBudget(budgetAmount, spentAmount);
    final isNearLimit = BudgetCalculator.isNearLimit(budgetAmount, spentAmount);

    // Determine color based on budget status
    Color progressColor;
    if (isOverBudget) {
      progressColor = theme.colorScheme.error;
    } else if (isNearLimit) {
      progressColor = Colors.orange;
    } else {
      progressColor = theme.colorScheme.primary;
    }

    // Cap percentage at 100% for progress bar display
    final displayPercentage = percentage > 100 ? 100.0 : percentage;

    return Semantics(
      label: 'Budget progress: ${percentage.toStringAsFixed(1)}% used, ${BudgetCalculator.formatAmount(spentAmount)} spent of ${BudgetCalculator.formatAmount(budgetAmount)} budget',
      value: '${percentage.toStringAsFixed(0)}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: displayPercentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: height,
              semanticsLabel: 'Budget usage progress indicator',
              semanticsValue: '${percentage.toStringAsFixed(0)} percent',
            ),
          ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% used',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${BudgetCalculator.formatAmount(spentAmount)} / ${BudgetCalculator.formatAmount(budgetAmount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
      ),
    );
  }
}
