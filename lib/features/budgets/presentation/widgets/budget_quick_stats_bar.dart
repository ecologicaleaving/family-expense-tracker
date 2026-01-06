// Widget: Budget Quick Stats Bar
// Budget Dashboard - 3-column stats display with vertical dividers

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';

/// Quick stats bar showing 3 key metrics in columns
/// - Total Budgeted
/// - Total Spent
/// - Active Categories Count
class BudgetQuickStatsBar extends StatelessWidget {
  const BudgetQuickStatsBar({
    super.key,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.activeCategoriesCount,
  });

  final int totalBudgeted; // in cents
  final int totalSpent; // in cents
  final int activeCategoriesCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: BudgetDesignTokens.quickStatsHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(BudgetDesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          // Total Budgeted
          Expanded(
            child: _StatColumn(
              label: 'TOTALE BUDGET',
              value: '€${(totalBudgeted / 100).toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
            ),
          ),

          // Vertical divider
          Container(
            width: 2,
            height: 48,
            color: AppColors.copper,
          ),

          // Total Spent
          Expanded(
            child: _StatColumn(
              label: 'SPESO',
              value: '€${(totalSpent / 100).toStringAsFixed(0)}',
              icon: Icons.trending_up,
            ),
          ),

          // Vertical divider
          Container(
            width: 2,
            height: 48,
            color: AppColors.copper,
          ),

          // Active Categories
          Expanded(
            child: _StatColumn(
              label: 'CATEGORIE',
              value: activeCategoriesCount.toString(),
              icon: Icons.category,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single stat column widget
class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.copper,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkFaded,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
