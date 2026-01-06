// Widget: Category Alert Strip
// Budget Dashboard - Horizontal scrolling strip showing categories in alert state

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';
import '../../../budgets/domain/entities/unified_budget_stats_entity.dart';

/// Alert strip showing categories that are near limit or over budget
/// Horizontal scrolling chips with thick left border
class CategoryAlertStrip extends StatelessWidget {
  const CategoryAlertStrip({
    super.key,
    required this.alertCategories,
  });

  final List<CategoryBudgetWithStats> alertCategories;

  @override
  Widget build(BuildContext context) {
    if (alertCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(BudgetDesignTokens.cardRadius),
        border: Border(
          left: BorderSide(
            color: AppColors.terracotta,
            width: BudgetDesignTokens.alertBorderWidth,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 20,
                color: AppColors.terracotta,
              ),
              const SizedBox(width: 8),
              Text(
                'CATEGORIE IN ALLERTA',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.terracotta,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Horizontal scrolling chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: alertCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = alertCategories[index];
                return _AlertCategoryChip(category: category);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Single alert category chip
class _AlertCategoryChip extends StatelessWidget {
  const _AlertCategoryChip({
    required this.category,
  });

  final CategoryBudgetWithStats category;

  @override
  Widget build(BuildContext context) {
    final isOverBudget = category.isOverBudget;
    final chipColor = isOverBudget ? AppColors.terracotta : AppColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: chipColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category name
          Text(
            category.categoryName,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),

          const SizedBox(width: 8),

          // Percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '${category.percentageUsed.toStringAsFixed(0)}%',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
