import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dashboard_stats_entity.dart';

/// Bar chart showing expense trend over time.
class TrendBarChart extends StatelessWidget {
  const TrendBarChart({
    super.key,
    required this.trend,
    required this.period,
    this.height = 200,
  });

  final List<TrendDataPoint> trend;
  final DashboardPeriod period;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Nessun dato'),
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
              'Andamento spese',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final aggregatedData = _aggregateData();

    if (aggregatedData.isEmpty) {
      return const Center(child: Text('Nessun dato'));
    }

    final maxY = aggregatedData.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final barColor = theme.colorScheme.primary;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = aggregatedData[groupIndex];
              final currencyFormat = NumberFormat.currency(
                locale: 'it_IT',
                symbol: '\u20ac',
                decimalDigits: 2,
              );
              return BarTooltipItem(
                '${_formatLabel(data.date, period)}\n${currencyFormat.format(data.total)}',
                TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= aggregatedData.length) {
                  return const SizedBox.shrink();
                }
                final data = aggregatedData[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatLabel(data.date, period),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _formatYAxis(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        barGroups: aggregatedData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.total,
                color: barColor,
                width: _getBarWidth(aggregatedData.length),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<TrendDataPoint> _aggregateData() {
    if (trend.isEmpty) return [];

    switch (period) {
      case DashboardPeriod.week:
        // Show daily data
        return trend;
      case DashboardPeriod.month:
        // Aggregate by week
        return _aggregateByWeek();
      case DashboardPeriod.year:
        // Aggregate by month
        return _aggregateByMonth();
    }
  }

  List<TrendDataPoint> _aggregateByWeek() {
    final weeks = <int, TrendDataPoint>{};

    for (final point in trend) {
      // Get week number (1-52)
      final weekOfYear = _getWeekNumber(point.date);
      final key = point.date.year * 100 + weekOfYear;

      if (weeks.containsKey(key)) {
        final existing = weeks[key]!;
        weeks[key] = TrendDataPoint(
          date: existing.date,
          total: existing.total + point.total,
          count: existing.count + point.count,
        );
      } else {
        weeks[key] = point;
      }
    }

    return weeks.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<TrendDataPoint> _aggregateByMonth() {
    final months = <int, TrendDataPoint>{};

    for (final point in trend) {
      final key = point.date.year * 100 + point.date.month;

      if (months.containsKey(key)) {
        final existing = months[key]!;
        months[key] = TrendDataPoint(
          date: existing.date,
          total: existing.total + point.total,
          count: existing.count + point.count,
        );
      } else {
        months[key] = TrendDataPoint(
          date: DateTime(point.date.year, point.date.month, 1),
          total: point.total,
          count: point.count,
        );
      }
    }

    return months.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  String _formatLabel(DateTime date, DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.week:
        return DateFormat('E', 'it_IT').format(date).substring(0, 2);
      case DashboardPeriod.month:
        return 'S${_getWeekNumber(date) - _getWeekNumber(DateTime(date.year, date.month, 1)) + 1}';
      case DashboardPeriod.year:
        return DateFormat('MMM', 'it_IT').format(date).substring(0, 3);
    }
  }

  String _formatYAxis(double value) {
    if (value >= 1000) {
      return '\u20ac${(value / 1000).toStringAsFixed(1)}k';
    }
    return '\u20ac${value.toStringAsFixed(0)}';
  }

  double _getBarWidth(int barCount) {
    if (barCount <= 7) return 24;
    if (barCount <= 12) return 18;
    return 12;
  }
}

/// Simple sparkline chart for compact display.
class TrendSparkline extends StatelessWidget {
  const TrendSparkline({
    super.key,
    required this.trend,
    this.height = 50,
    this.color,
  });

  final List<TrendDataPoint> trend;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty || trend.every((t) => t.total == 0)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Nessun dato',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final lineColor = color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.total);
              }).toList(),
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
