// Widget: Top Spending Bar Chart
// Budget Dashboard - Geometric horizontal bar chart showing top 5 categories by spending

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';
import '../../../budgets/domain/entities/unified_budget_stats_entity.dart';

/// Top spending categories displayed as horizontal bar chart
/// Shows top 5 categories with geometric bars
class TopSpendingBarChart extends StatelessWidget {
  const TopSpendingBarChart({
    super.key,
    required this.topCategories,
    this.maxItems = 5,
  });

  final List<CategoryBudgetWithStats> topCategories;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (topCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCategories = topCategories.take(maxItems).toList();
    final maxSpent = displayCategories.isNotEmpty
        ? displayCategories.map((c) => c.spentAmount).reduce((a, b) => a > b ? a : b)
        : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'TOP SPESE DEL MESE',
              style: BudgetDesignTokens.sectionLabel.copyWith(
                color: AppColors.ink,
              ),
            ),

            const SizedBox(height: 16),

            // Bar chart
            ...displayCategories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BarChartRow(
                  category: category,
                  maxValue: maxSpent,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Single bar in the chart
class _BarChartRow extends StatelessWidget {
  const _BarChartRow({
    required this.category,
    required this.maxValue,
  });

  final CategoryBudgetWithStats category;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? category.spentAmount / maxValue : 0.0;

    // Determine bar color based on budget status
    Color barColor;
    if (category.isOverBudget) {
      barColor = AppColors.terracotta;
    } else if (category.isNearLimit) {
      barColor = AppColors.gold;
    } else {
      barColor = AppColors.copper;
    }

    return Row(
      children: [
        // Category name (fixed width)
        SizedBox(
          width: 100,
          child: Text(
            category.categoryName,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(width: 12),

        // Bar
        Expanded(
          child: Stack(
            children: [
              // Background track
              Container(
                height: BudgetDesignTokens.barChartBarHeight,
                decoration: BoxDecoration(
                  color: AppColors.parchmentDark,
                  borderRadius: BorderRadius.circular(
                    BudgetDesignTokens.progressBarRadius,
                  ),
                ),
              ),

              // Filled bar (animated)
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: BudgetDesignTokens.barChartBarHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(
                      BudgetDesignTokens.progressBarRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Amount (fixed width)
        SizedBox(
          width: 70,
          child: Text(
            '€${(category.spentAmount / 100).toStringAsFixed(0)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
