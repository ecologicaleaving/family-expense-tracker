import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import 'personal_dashboard_view.dart';

import '../../../../app/app_theme.dart';
/// Grafico a torta spese personali con click su categoria
class PersonalExpensesPieChart extends ConsumerStatefulWidget {
  const PersonalExpensesPieChart({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<PersonalExpensesPieChart> createState() =>
      _PersonalExpensesPieChartState();
}

class _PersonalExpensesPieChartState
    extends ConsumerState<PersonalExpensesPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryExpensesAsync =
        ref.watch(personalExpensesByCategoryProvider(widget.userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: AppColors.terracotta,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spese per Categoria',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            categoryExpensesAsync.when(
              data: (categoryTotals) {
                if (categoryTotals.isEmpty) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Nessuna spesa personale questo mese',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  );
                }

                // Converti in lista ordinata per importo
                final categories = categoryTotals.entries.toList()
                  ..sort((a, b) =>
                      (b.value['total'] as int).compareTo(a.value['total'] as int));

                return SizedBox(
                  height: 250,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  setState(() => _touchedIndex = -1);
                                  return;
                                }

                                final index =
                                    response.touchedSection!.touchedSectionIndex;

                                // Mostra bottom sheet con spese della categoria
                                if (event is FlTapUpEvent) {
                                  final categoryEntry = categories[index];
                                  final categoryId = categoryEntry.key;
                                  final categoryName = categoryEntry.value['name'] as String;

                                  _showExpensesBottomSheet(
                                    context,
                                    categoryId,
                                    categoryName,
                                  );
                                }

                                setState(() => _touchedIndex = index);
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildSections(categories),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildLegend(categories, theme),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Errore caricamento dati',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      List<MapEntry<String, dynamic>> categories) {
    // Colori per le categorie
    final colors = [
      AppColors.terracotta,
      const Color(0xFF8B7355),
      const Color(0xFFD4A373),
      const Color(0xFFA0826D),
      const Color(0xFF6F4E37),
      const Color(0xFFB08968),
    ];

    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryData = entry.value;
      final total = categoryData.value['total'] as int;
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: total.toDouble(),
        title: '', // Empty, will show in legend
        radius: isTouched ? 65 : 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(
      List<MapEntry<String, dynamic>> categories, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final categoryData = categories[index];
        final categoryName = categoryData.value['name'] as String;
        final total = categoryData.value['total'] as int;

        final colors = [
          AppColors.terracotta,
          const Color(0xFF8B7355),
          const Color(0xFFD4A373),
          const Color(0xFFA0826D),
          const Color(0xFF6F4E37),
          const Color(0xFFB08968),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      CurrencyUtils.formatCents(total),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpensesBottomSheet(
    BuildContext context,
    String categoryId,
    String categoryName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _CategoryExpensesSheet(
            categoryId: categoryId,
            categoryName: categoryName,
            userId: widget.userId,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

/// Bottom sheet con elenco spese della categoria
class _CategoryExpensesSheet extends ConsumerWidget {
  const _CategoryExpensesSheet({
    required this.categoryId,
    required this.categoryName,
    required this.userId,
    required this.scrollController,
  });

  final String categoryId;
  final String categoryName;
  final String userId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesByCategoryProvider(
      (userId: userId, categoryId: categoryId),
    ));

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spese del mese',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista spese
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Text(
                      'Nessuna spesa in questa categoria',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.terracotta.withOpacity(0.1),
                        child: Icon(
                          Icons.receipt,
                          color: AppColors.terracotta,
                        ),
                      ),
                      title: Text(
                        expense.merchant ?? 'Spesa',
                        style: theme.textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        DateFormat('d MMM yyyy', 'it').format(expense.date),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        expense.formattedAmount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/expense/${expense.id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Errore caricamento spese',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
