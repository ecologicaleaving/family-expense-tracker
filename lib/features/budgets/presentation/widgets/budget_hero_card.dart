// Widget: Budget Hero Card
// Budget Dashboard - Hero section with total budget display

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/utils/budget_calculator.dart';

/// Hero section displaying total budget overview
/// Full-width terracotta block with large amount display
class BudgetHeroCard extends StatelessWidget {
  const BudgetHeroCard({
    super.key,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.alertCount,
  });

  final int totalBudgeted; // in cents
  final int totalSpent; // in cents
  final int alertCount; // number of categories in alert state

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = totalBudgeted - totalSpent;
    final percentageUsed = totalBudgeted > 0
        ? BudgetCalculator.calculatePercentageUsed(totalBudgeted, totalSpent)
        : 0.0;
    final isOverBudget = totalSpent >= totalBudgeted && totalBudgeted > 0;
    final hasAlerts = alertCount > 0;

    return Container(
      height: BudgetDesignTokens.heroHeight,
      decoration: const BoxDecoration(
        color: AppColors.terracotta,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(BudgetDesignTokens.cardRadius),
          bottomRight: Radius.circular(BudgetDesignTokens.cardRadius),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with label and alert indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'BUDGET RIMANENTE',
                style: BudgetDesignTokens.labelHero,
              ),

              // Alert indicator
              if (hasAlerts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 16,
                        color: AppColors.cream,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$alertCount ${alertCount == 1 ? 'ALLERTA' : 'ALLERTA'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Main amount display
          if (totalBudgeted > 0) ...[
            Text(
              isOverBudget
                  ? '-€${(remaining.abs() / 100).toStringAsFixed(2)}'
                  : '€${(remaining / 100).toStringAsFixed(2)}',
              style: BudgetDesignTokens.amountHero.copyWith(
                color: isOverBudget
                    ? AppColors.cream.withValues(alpha: 0.7)
                    : AppColors.cream,
              ),
            ),
          ] else ...[
            Text(
              'Nessun budget',
              style: BudgetDesignTokens.amountHero.copyWith(
                fontSize: 28,
              ),
            ),
          ],

          const Spacer(),

          // Copper divider line
          Container(
            height: 2,
            color: AppColors.copper,
          ),

          const SizedBox(height: 12),

          // Bottom stats row
          if (totalBudgeted > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Spent / Budget
                Text(
                  'Speso: €${(totalSpent / 100).toStringAsFixed(0)} / €${(totalBudgeted / 100).toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cream.withValues(alpha: 0.9),
                  ),
                ),

                // Percentage
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? AppColors.cream.withValues(alpha: 0.2)
                        : AppColors.copper.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${percentageUsed.toStringAsFixed(1)}%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              'Imposta un budget per iniziare',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.cream.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
