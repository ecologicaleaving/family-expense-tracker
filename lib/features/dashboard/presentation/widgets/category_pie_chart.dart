import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/constants.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

/// Pie chart showing expense breakdown by category.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.categories,
    this.height = 200,
  });

  final List<CategoryBreakdown> categories;
  final double height;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('Nessuna spesa nel periodo'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spese per categoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Pie chart at full width
            SizedBox(
              height: widget.height,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: _buildSections(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal scrollable legend
            _buildHorizontalLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final color = _getCategoryColor(category.category);

      return PieChartSectionData(
        color: color,
        value: category.total,
        title: '${category.percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildHorizontalLegend() {
    final currencyFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '\u20ac',
      decimalDigits: 0,
    );

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final color = _getCategoryColor(category.category);

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
                        _getCategoryLabel(category.category),
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
                  currencyFormat.format(category.total),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${category.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    final currencyFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '\u20ac',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.categories.map((category) {
          final color = _getCategoryColor(category.category);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryLabel(category.category),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currencyFormat.format(category.total),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final categoryEnum = ExpenseCategory.values.firstWhere(
      (e) => e.apiValue == category,
      orElse: () => ExpenseCategory.altro,
    );
    return categoryEnum.color;
  }

  String _getCategoryLabel(String category) {
    final categoryEnum = ExpenseCategory.values.firstWhere(
      (e) => e.apiValue == category,
      orElse: () => ExpenseCategory.altro,
    );
    return categoryEnum.label;
  }
}

/// Simple horizontal bar chart alternative for categories.
class CategoryBarList extends StatelessWidget {
  const CategoryBarList({
    super.key,
    required this.categories,
  });

  final List<CategoryBreakdown> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('Nessuna spesa'));
    }

    final maxTotal = categories.first.total; // Already sorted by total
    final currencyFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '\u20ac',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spese per categoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final color = _getCategoryColor(category.category);
              final percentage = maxTotal > 0 ? category.total / maxTotal : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category.category),
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getCategoryLabel(category.category),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          currencyFormat.format(category.total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final categoryEnum = ExpenseCategory.values.firstWhere(
      (e) => e.apiValue == category,
      orElse: () => ExpenseCategory.altro,
    );
    return categoryEnum.color;
  }

  String _getCategoryLabel(String category) {
    final categoryEnum = ExpenseCategory.values.firstWhere(
      (e) => e.apiValue == category,
      orElse: () => ExpenseCategory.altro,
    );
    return categoryEnum.label;
  }

  IconData _getCategoryIcon(String category) {
    final categoryEnum = ExpenseCategory.values.firstWhere(
      (e) => e.apiValue == category,
      orElse: () => ExpenseCategory.altro,
    );
    return categoryEnum.icon;
  }
}
