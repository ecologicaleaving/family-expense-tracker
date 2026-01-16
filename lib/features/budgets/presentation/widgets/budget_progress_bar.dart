import 'package:flutter/material.dart';

import '../../../../core/utils/budget_calculator.dart';

import '../../../../app/app_theme.dart';
/// Budget progress bar widget with percentage calculation and color coding
/// Updated with Italian Brutalism design: thicker (12px), sharper (2px radius), segmented colors
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.budgetAmount,
    required this.spentAmount,
    this.height,
    this.showPercentage = false, // Default false for dashboard cards
  });

  final int budgetAmount;
  final int spentAmount;
  final double? height;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barHeight = height ?? BudgetDesignTokens.progressBarHeight;
    final percentage = BudgetCalculator.calculatePercentageUsed(
      budgetAmount,
      spentAmount,
    );
    final isOverBudget = BudgetCalculator.isOverBudget(budgetAmount, spentAmount);
    final isNearLimit = BudgetCalculator.isNearLimit(budgetAmount, spentAmount);

    // Determine color based on budget status (segmented, not gradient)
    // Healthy: copper, Warning: gold, Danger: terracotta
    Color progressColor;
    if (isOverBudget) {
      progressColor = BudgetDesignTokens.dangerBorder; // terracotta
    } else if (isNearLimit) {
      progressColor = BudgetDesignTokens.warningBorder; // gold
    } else {
      progressColor = BudgetDesignTokens.healthyBorder; // copper
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
          // Sharp brutalist progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(BudgetDesignTokens.progressBarRadius), // 2px, sharper
            child: LinearProgressIndicator(
              value: displayPercentage / 100,
              backgroundColor: AppColors.parchmentDark,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: barHeight, // 12px, thicker
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
