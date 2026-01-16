import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/budget_composition_entity.dart';
import '../providers/budget_composition_provider.dart';
import '../widgets/category_budget_tile.dart';

import '../../../../app/app_theme.dart';
/// Personal budget detail screen showing user's personal allocations
class PersonalBudgetDetailScreen extends ConsumerWidget {
  const PersonalBudgetDetailScreen({
    super.key,
    required this.composition,
    required this.currentUserId,
  });

  final BudgetComposition composition;
  final String currentUserId;

  /// Calculate personal budget for current user
  int _calculatePersonalBudget() {
    int total = 0;
    for (final categoryBudget in composition.categoryBudgets) {
      final userContribution = categoryBudget.memberContributions
          .where((c) => c.userId == currentUserId)
          .firstOrNull;
      if (userContribution != null) {
        total += userContribution.calculatedAmount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalBudget = _calculatePersonalBudget();

    // Filter categories where user has contributions
    final personalCategories = composition.categoryBudgets
        .where((cat) => cat.memberContributions.any((c) => c.userId == currentUserId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budget Personale',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.parchment,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Il Tuo Budget',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  CurrencyUtils.formatCents(personalBudget),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Budget personale mensile',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inkLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.inkLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Questo è il budget che puoi spendere liberamente nelle categorie assegnate.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.inkLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Categories Section
          Text(
            'Le Tue Categorie',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),

          if (personalCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'Nessuna categoria personale',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.inkFaded,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...personalCategories.map((category) {
              // Create params for the provider
              final params = BudgetCompositionParams(
                groupId: composition.groupId,
                year: composition.year,
                month: composition.month,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CategoryBudgetTile(
                  key: ValueKey(category.categoryId),
                  categoryBudget: category,
                  params: params,
                  initiallyExpanded: false,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
