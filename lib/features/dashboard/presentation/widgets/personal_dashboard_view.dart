import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/routes.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/domain/entities/income_source_entity.dart';
import '../../../budgets/presentation/providers/income_sources_provider.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../providers/dashboard_provider.dart';
import 'expenses_chart_widget.dart';

import '../../../../app/app_theme.dart';
/// Parameters for personal expenses provider
class PersonalExpensesParams {
  final String userId;
  final DashboardPeriod period;
  final int offset;

  const PersonalExpensesParams({
    required this.userId,
    required this.period,
    required this.offset,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalExpensesParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          period == other.period &&
          offset == other.offset;

  @override
  int get hashCode => userId.hashCode ^ period.hashCode ^ offset.hashCode;
}

/// Calculate date range based on period and offset
(DateTime start, DateTime end) _calculateDateRange(
  DashboardPeriod period,
  int offset,
) {
  final now = DateTime.now();

  switch (period) {
    case DashboardPeriod.week:
      final weekDay = now.weekday;
      final currentWeekStart = now.subtract(Duration(days: weekDay - 1));
      final targetWeekStart = currentWeekStart.add(Duration(days: offset * 7));
      final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));
      return (
        DateTime(targetWeekStart.year, targetWeekStart.month, targetWeekStart.day),
        DateTime(targetWeekEnd.year, targetWeekEnd.month, targetWeekEnd.day, 23, 59, 59),
      );

    case DashboardPeriod.month:
      final targetDate = DateTime(now.year, now.month + offset, 1);
      final startDate = DateTime(targetDate.year, targetDate.month, 1);
      final endDate = DateTime(targetDate.year, targetDate.month + 1, 0, 23, 59, 59);
      return (startDate, endDate);

    case DashboardPeriod.year:
      final targetYear = now.year + offset;
      return (
        DateTime(targetYear, 1, 1),
        DateTime(targetYear, 12, 31, 23, 59, 59),
      );
  }
}

/// Provider per le spese personali e di gruppo raggruppate per categoria
final personalExpensesByCategoryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, PersonalExpensesParams>((ref, params) async {
  final supabase = Supabase.instance.client;
  final (startDate, endDate) = _calculateDateRange(params.period, params.offset);

  // Query spese personali
  final personalExpenses = await supabase
      .from('expenses')
      .select('amount, category_id, expense_categories(name)')
      .eq('created_by', params.userId)
      .eq('is_group_expense', false)
      .gte('date', startDate.toIso8601String().split('T')[0])
      .lte('date', endDate.toIso8601String().split('T')[0]) as List;

  // Query spese di gruppo (create dall'utente)
  final groupExpenses = await supabase
      .from('expenses')
      .select('amount, category_id, expense_categories(name)')
      .eq('created_by', params.userId)
      .eq('is_group_expense', true)
      .gte('date', startDate.toIso8601String().split('T')[0])
      .lte('date', endDate.toIso8601String().split('T')[0]) as List;

  // Raggruppa per categoria
  final Map<String, dynamic> categoryTotals = {};

  // Processa spese personali
  for (final expense in personalExpenses) {
    final categoryId = expense['category_id'] as String?;
    if (categoryId == null) continue;

    final categoryData = expense['expense_categories'];
    final categoryName = categoryData is Map<String, dynamic>
        ? (categoryData['name'] as String? ?? 'Sconosciuta')
        : 'Sconosciuta';

    final amount = (expense['amount'] as num).toDouble();
    final amountCents = (amount * 100).round();

    if (!categoryTotals.containsKey(categoryId)) {
      categoryTotals[categoryId] = {
        'name': categoryName,
        'personal': 0,
        'group': 0,
      };
    }

    categoryTotals[categoryId]['personal'] += amountCents;
  }

  // Processa spese di gruppo
  for (final expense in groupExpenses) {
    final categoryId = expense['category_id'] as String?;
    if (categoryId == null) continue;

    final categoryData = expense['expense_categories'];
    final categoryName = categoryData is Map<String, dynamic>
        ? (categoryData['name'] as String? ?? 'Sconosciuta')
        : 'Sconosciuta';

    final amount = (expense['amount'] as num).toDouble();
    final amountCents = (amount * 100).round();

    if (!categoryTotals.containsKey(categoryId)) {
      categoryTotals[categoryId] = {
        'name': categoryName,
        'personal': 0,
        'group': 0,
      };
    }

    categoryTotals[categoryId]['group'] += amountCents;
  }

  return categoryTotals;
});

/// Widget che mostra la vista personale completa della dashboard in una singola card
class PersonalDashboardView extends ConsumerStatefulWidget {
  const PersonalDashboardView({super.key});

  @override
  ConsumerState<PersonalDashboardView> createState() => _PersonalDashboardViewState();
}

class _PersonalDashboardViewState extends ConsumerState<PersonalDashboardView> {
  @override
  Widget build(BuildContext context) {
    final group = ref.watch(currentGroupProvider);
    final userId = ref.watch(currentUserIdProvider);
    final dashboardState = ref.watch(dashboardProvider);

    if (group == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.group_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Nessun gruppo disponibile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Crea o unisciti a un gruppo per iniziare',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Totali (Entrate e Spese)
            _TotalsSection(
              userId: userId,
              period: dashboardState.period,
              offset: dashboardState.offset,
            ),
            const SizedBox(height: 24),

            // Categorie (sempre aperto)
            Row(
              children: [
                Icon(Icons.category, color: AppColors.terracotta),
                const SizedBox(width: 8),
                Text(
                  'Categorie',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CategoriesSection(
              userId: userId,
              period: dashboardState.period,
              offset: dashboardState.offset,
            ),
            const SizedBox(height: 24),

            // Grafico a barre
            _PersonalBarChart(
              groupId: group.id,
              userId: userId,
            ),
            const SizedBox(height: 24),

            // Grafico a torta
            _PersonalPieChart(
              userId: userId,
              period: dashboardState.period,
              offset: dashboardState.offset,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sezione con totale entrate e totale spese
class _TotalsSection extends ConsumerWidget {
  const _TotalsSection({
    required this.userId,
    required this.period,
    required this.offset,
  });

  final String userId;
  final DashboardPeriod period;
  final int offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final incomeSourcesAsync = ref.watch(incomeSourcesProvider);
    final params = PersonalExpensesParams(
      userId: userId,
      period: period,
      offset: offset,
    );
    final expensesAsync = ref.watch(personalExpensesByCategoryProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.terracotta),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Riepilogo Mensile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push(AppRoutes.incomeManagement);
              },
              tooltip: 'Gestisci Entrate',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Totale Spese (personali + gruppo)
        expensesAsync.when(
          data: (categoryTotals) {
            final totalPersonal = categoryTotals.values.fold<int>(
              0,
              (sum, category) => sum + (category['personal'] as int),
            );
            final totalGroup = categoryTotals.values.fold<int>(
              0,
              (sum, category) => sum + (category['group'] as int),
            );
            final totalExpenses = totalPersonal + totalGroup;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.terracotta.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, color: AppColors.terracotta, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Spese',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyUtils.formatCentsCompact(totalExpenses),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.terracotta,
                        ),
                      ),
                      if (totalGroup > 0)
                        Text(
                          '(${CurrencyUtils.formatCentsCompact(totalGroup)} gruppo)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Errore caricamento spese'),
          ),
        ),

        const SizedBox(height: 12),

        // Totale Entrate
        incomeSourcesAsync.when(
          data: (sources) {
            final totalIncome = sources.fold<int>(
              0,
              (sum, source) => sum + source.amount,
            );

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Entrate',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyUtils.formatCentsCompact(totalIncome),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Errore caricamento entrate'),
          ),
        ),
      ],
    );
  }
}

/// Sezione categorie
class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection({
    required this.userId,
    required this.period,
    required this.offset,
  });

  final String userId;
  final DashboardPeriod period;
  final int offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final params = PersonalExpensesParams(
      userId: userId,
      period: period,
      offset: offset,
    );
    final expensesAsync = ref.watch(personalExpensesByCategoryProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        expensesAsync.when(
          data: (categoryTotals) {
            if (categoryTotals.isEmpty) {
              return Center(
                child: Text(
                  'Nessuna spesa personale questo mese',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }

            final categories = categoryTotals.entries.toList()
              ..sort((a, b) {
                final totalA = (a.value['personal'] as int) + (a.value['group'] as int);
                final totalB = (b.value['personal'] as int) + (b.value['group'] as int);
                return totalB.compareTo(totalA);
              });

            return Column(
              children: categories.map((entry) {
                final categoryName = entry.value['name'] as String;
                final categoryId = entry.key;
                final personalSpent = entry.value['personal'] as int;
                final groupSpent = entry.value['group'] as int;
                final totalSpent = personalSpent + groupSpent;

                return InkWell(
                  onTap: () {
                    _showExpensesBottomSheet(context, ref, categoryId, categoryName, userId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            categoryName,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.formatCentsCompact(totalSpent),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (groupSpent > 0)
                              Text(
                                '(${CurrencyUtils.formatCentsCompact(groupSpent)} gruppo)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(
            'Errore caricamento categorie',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ),
      ],
    );
  }

  void _showExpensesBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
    String categoryName,
    String userId,
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
            userId: userId,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

/// Grafico a barre personalizzato per vista personale
class _PersonalBarChart extends ConsumerStatefulWidget {
  const _PersonalBarChart({
    required this.groupId,
    required this.userId,
  });

  final String groupId;
  final String userId;

  @override
  ConsumerState<_PersonalBarChart> createState() => _PersonalBarChartState();
}

class _PersonalBarChartState extends ConsumerState<_PersonalBarChart> {
  ChartPeriod _selectedPeriod = ChartPeriod.week;
  int _offset = 0;

  void _changePeriod(ChartPeriod newPeriod) {
    setState(() {
      _selectedPeriod = newPeriod;
      _offset = 0;
    });
  }

  String _getPeriodLabel() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case ChartPeriod.week:
        final weekDay = now.weekday;
        final currentWeekStart = now.subtract(Duration(days: weekDay - 1));
        final targetWeekStart = currentWeekStart.add(Duration(days: _offset * 7));
        final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'it').format(targetWeekStart)} - ${DateFormat('d MMM', 'it').format(targetWeekEnd)}';
      case ChartPeriod.month:
        final targetMonth = now.month + _offset;
        final targetYear = now.year + (targetMonth - 1) ~/ 12;
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        final date = DateTime(targetYear, normalizedMonth);
        return DateFormat('MMMM yyyy', 'it').format(date);
      case ChartPeriod.year:
        return (now.year + _offset).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final params = ExpenseChartParams(
      groupId: widget.groupId,
      userId: widget.userId,
      period: _selectedPeriod,
      isPersonalView: true,
      offset: _offset,
    );
    final dataAsync = ref.watch(expensesByPeriodProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: AppColors.terracotta),
            const SizedBox(width: 8),
            Text(
              'Andamento Spese',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selector periodo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PeriodChip(
              label: 'Settimana',
              isSelected: _selectedPeriod == ChartPeriod.week,
              onTap: () => _changePeriod(ChartPeriod.week),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: 'Mese',
              isSelected: _selectedPeriod == ChartPeriod.month,
              onTap: () => _changePeriod(ChartPeriod.month),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: 'Anno',
              isSelected: _selectedPeriod == ChartPeriod.year,
              onTap: () => _changePeriod(ChartPeriod.year),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Navigation controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _offset--),
              tooltip: 'Precedente',
            ),
            Expanded(
              child: Text(
                _getPeriodLabel(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _offset < 0 ? () => setState(() => _offset++) : null,
              tooltip: 'Successivo',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Chart
        dataAsync.when(
          data: (data) => SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Nessuna spesa nel periodo',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(data),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final amount = rod.toY.round();
                            return BarTooltipItem(
                              CurrencyUtils.formatCents(amount),
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  data[index]['label'],
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                '€${(value / 100).toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxY(data) / 5,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data
                          .asMap()
                          .entries
                          .map(
                            (entry) => BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value['value'].toDouble(),
                                  color: AppColors.terracotta,
                                  width: _selectedPeriod == ChartPeriod.month ? 6 : 16,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
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
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100;
    final maxValue = data.map((e) => e['value'] as int).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return 100;
    return ((maxValue / 100).ceil() * 10).toDouble() * 10;
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.terracotta : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cream : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Grafico a torta
class _PersonalPieChart extends ConsumerStatefulWidget {
  const _PersonalPieChart({
    required this.userId,
    required this.period,
    required this.offset,
  });

  final String userId;
  final DashboardPeriod period;
  final int offset;

  @override
  ConsumerState<_PersonalPieChart> createState() => _PersonalPieChartState();
}

class _PersonalPieChartState extends ConsumerState<_PersonalPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final params = PersonalExpensesParams(
      userId: widget.userId,
      period: widget.period,
      offset: widget.offset,
    );
    final categoryExpensesAsync =
        ref.watch(personalExpensesByCategoryProvider(params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart, color: AppColors.terracotta),
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

            final categories = categoryTotals.entries.toList()
              ..sort((a, b) {
                final totalA = (a.value['personal'] as int) + (a.value['group'] as int);
                final totalB = (b.value['personal'] as int) + (b.value['group'] as int);
                return totalB.compareTo(totalA);
              });

            return Column(
              children: [
                // Pie chart at full width
                SizedBox(
                  height: 200,
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

                          final index = response.touchedSection!.touchedSectionIndex;

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
                const SizedBox(height: 16),
                // Horizontal scrollable legend
                _buildHorizontalLegend(categories, theme),
              ],
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
    );
  }

  List<PieChartSectionData> _buildSections(
      List<MapEntry<String, dynamic>> categories) {
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
      final personal = categoryData.value['personal'] as int;
      final group = categoryData.value['group'] as int;
      final total = personal + group;
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: total.toDouble(),
        title: '',
        radius: isTouched ? 65 : 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildHorizontalLegend(
      List<MapEntry<String, dynamic>> categories, ThemeData theme) {
    final colors = [
      AppColors.terracotta,
      const Color(0xFF8B7355),
      const Color(0xFFD4A373),
      const Color(0xFFA0826D),
      const Color(0xFF6F4E37),
      const Color(0xFFB08968),
    ];

    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final categoryData = categories[index];
          final categoryName = categoryData.value['name'] as String;
          final personal = categoryData.value['personal'] as int;
          final group = categoryData.value['group'] as int;
          final total = personal + group;
          final color = colors[index % colors.length];

          return Container(
            constraints: const BoxConstraints(
              minWidth: 100,
              maxWidth: 140,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              color: color.withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyUtils.formatCents(total),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (group > 0)
                  Text(
                    '(${CurrencyUtils.formatCents(group)} gruppo)',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(
      List<MapEntry<String, dynamic>> categories, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final categoryData = categories[index];
        final categoryName = categoryData.value['name'] as String;
        final personal = categoryData.value['personal'] as int;
        final group = categoryData.value['group'] as int;
        final total = personal + group;

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
                          expense.isGroupExpense ? Icons.group : Icons.person,
                          color: AppColors.terracotta,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              expense.merchant ?? 'Spesa',
                              style: theme.textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('d MMM yyyy', 'it').format(expense.date),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (expense.categoryName != null)
                            Text(
                              expense.categoryName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                        ],
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
