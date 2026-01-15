import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
import '../app_constants.dart';

/// Transaction list item component
class TransactionListItem extends StatelessWidget {
  final String name;
  final String category;
  final double amount;
  final String emoji;
  final bool isIncome;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.name,
    required this.category,
    required this.amount,
    required this.emoji,
    this.isIncome = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.mediumRadius,
          boxShadow: AppShadows.small,
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isIncome ? AppColors.sageGreen : AppColors.terracotta)
                    .withValues(alpha: 0.15),
                borderRadius: AppRadius.smallRadius,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '€', decimalDigits: 2).format(amount.abs())}',
              style: AppTextStyles.h3.copyWith(
                color: isIncome ? AppColors.sageGreen : AppColors.terracotta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
