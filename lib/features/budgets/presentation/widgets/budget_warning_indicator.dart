import 'package:flutter/material.dart';

/// Budget warning indicator for 80% threshold warning
class BudgetWarningIndicator extends StatelessWidget {
  const BudgetWarningIndicator({
    super.key,
    required this.isNearLimit,
    required this.isOverBudget,
    this.remainingAmount,
  });

  final bool isNearLimit;
  final bool isOverBudget;
  final int? remainingAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show anything if budget is healthy
    if (!isNearLimit && !isOverBudget) {
      return const SizedBox.shrink();
    }

    String message;
    IconData icon;
    Color backgroundColor;
    Color textColor;

    if (isOverBudget) {
      final overAmount = (remainingAmount ?? 0).abs();
      message = 'Over budget by €$overAmount';
      icon = Icons.error_outline;
      backgroundColor = theme.colorScheme.errorContainer;
      textColor = theme.colorScheme.onErrorContainer;
    } else {
      // Near limit (80%+)
      message = 'Approaching budget limit';
      icon = Icons.warning_amber_outlined;
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
    }

    return Semantics(
      label: message,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: textColor,
              semanticLabel: isOverBudget ? 'Error' : 'Warning',
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
