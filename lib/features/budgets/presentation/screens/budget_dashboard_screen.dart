// Screen: Budget Dashboard (Unified)
// Replaces budget_settings_screen.dart and budget_management_screen.dart
// Single unified view with all budget information

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../domain/entities/unified_budget_stats_entity.dart';
import '../providers/category_budget_provider.dart';
import '../providers/unified_budget_stats_provider.dart';
import '../widgets/budget_hero_card.dart';
import '../widgets/budget_quick_stats_bar.dart';
import '../widgets/category_alert_strip.dart';
import '../widgets/geometric_section_divider.dart';
import '../widgets/top_spending_bar_chart.dart';
import '../widgets/unified_category_card.dart';
import '../../../../shared/widgets/offline_banner.dart';

/// Unified budget dashboard showing all budget information in one screen
/// Features:
/// - Hero section with total budget remaining
/// - Alert strip for categories near limit/over budget
/// - Quick stats bar (total budgeted, spent, categories)
/// - Top spending chart
/// - Unified category grid (group + personal together)
class BudgetDashboardScreen extends ConsumerWidget {
  const BudgetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final groupId = ref.watch(currentGroupIdProvider);
    final userId = ref.watch(currentUserIdProvider);

    final statsParams = UnifiedBudgetStatsParams(
      groupId: groupId,
      userId: userId,
      year: now.year,
      month: now.month,
    );

    final statsAsync = ref.watch(unifiedBudgetStatsProvider(statsParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          // TODO: Add month selector in future iteration
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(unifiedBudgetStatsProvider(statsParams));
            },
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Errore nel caricamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(unifiedBudgetStatsProvider(statsParams));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => _BudgetDashboardContent(
          stats: stats,
          groupId: groupId,
          userId: userId,
          year: now.year,
          month: now.month,
        ),
      ),
    );
  }
}

/// Content of the budget dashboard
class _BudgetDashboardContent extends ConsumerWidget {
  const _BudgetDashboardContent({
    required this.stats,
    required this.groupId,
    required this.userId,
    required this.year,
    required this.month,
  });

  final UnifiedBudgetStatsEntity stats;
  final String groupId;
  final String userId;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(unifiedBudgetStatsProvider(
          UnifiedBudgetStatsParams(
            groupId: groupId,
            userId: userId,
            year: year,
            month: month,
          ),
        ));
      },
      child: ListView(
        children: [
          // Feature 012-expense-improvements T025: StaleDataBanner at top of dashboard
          const OfflineBanner(showStaleDataWarning: true),

          // Hero Section - Total Budget Overview
          BudgetHeroCard(
            totalBudgeted: stats.totalBudgeted,
            totalSpent: stats.totalSpent,
            alertCount: stats.alertCategoriesCount,
          ),

          const SizedBox(height: 16),

          // Alert Strip (only if there are alerts)
          if (stats.hasAlerts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryAlertStrip(
                alertCategories: stats.alertCategories,
              ),
            ),

          const SizedBox(height: 16),

          // Quick Stats Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BudgetQuickStatsBar(
              totalBudgeted: stats.totalBudgeted,
              totalSpent: stats.totalSpent,
              activeCategoriesCount: stats.activeCategoriesCount,
            ),
          ),

          const SizedBox(height: 16),

          // Top Spending Chart
          if (stats.topSpendingCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TopSpendingBarChart(
                topCategories: stats.topSpendingCategories,
              ),
            ),

          const SizedBox(height: 8),

          // Section Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: GeometricSectionDivider(
              text: 'Tutte le Categorie',
            ),
          ),

          // Unified Category Grid
          if (stats.allCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nessun budget impostato',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inizia impostando un budget per le tue categorie',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: stats.allCategories.map((category) {
                  return UnifiedCategoryCard(
                    category: category,
                    onEdit: (newAmount) async {
                      // Update budget via category budget provider
                      final notifier = ref.read(
                        categoryBudgetProvider((
                          groupId: groupId,
                          year: year,
                          month: month,
                        )).notifier,
                      );

                      return await notifier.updateBudget(
                        budgetId: category.budgetId!,
                        amount: newAmount,
                      );
                    },
                    onDelete: () async {
                      if (category.budgetId == null) return false;

                      final notifier = ref.read(
                        categoryBudgetProvider((
                          groupId: groupId,
                          year: year,
                          month: month,
                        )).notifier,
                      );

                      return await notifier.deleteBudget(category.budgetId!);
                    },
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
