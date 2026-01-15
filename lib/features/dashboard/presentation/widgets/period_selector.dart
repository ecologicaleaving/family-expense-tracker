import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dashboard_stats_entity.dart';

/// Widget for selecting dashboard time period.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DashboardPeriod>(
      segments: DashboardPeriod.values
          .map((period) => ButtonSegment<DashboardPeriod>(
                value: period,
                label: Text(period.label),
              ))
          .toList(),
      selected: {selectedPeriod},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) {
          onPeriodChanged(selection.first);
        }
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Chip-based period selector variant.
class PeriodChipSelector extends StatelessWidget {
  const PeriodChipSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: DashboardPeriod.values.map((period) {
        final isSelected = period == selectedPeriod;
        return ChoiceChip(
          label: Text(period.label),
          selected: isSelected,
          onSelected: (_) => onPeriodChanged(period),
        );
      }).toList(),
    );
  }
}

/// Widget for navigating between periods (prev/next).
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.period,
    required this.offset,
    required this.onPrevious,
    required this.onNext,
  });

  final DashboardPeriod period;
  final int offset;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  String _getPeriodLabel() {
    final now = DateTime.now();

    switch (period) {
      case DashboardPeriod.week:
        final weekDay = now.weekday;
        final currentWeekStart = now.subtract(Duration(days: weekDay - 1));
        final targetWeekStart = currentWeekStart.add(Duration(days: offset * 7));
        final targetWeekEnd = targetWeekStart.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'it').format(targetWeekStart)} - ${DateFormat('d MMM', 'it').format(targetWeekEnd)}';
      case DashboardPeriod.month:
        // Use DateTime constructor to handle month overflow/underflow
        final targetDate = DateTime(now.year, now.month + offset, 1);
        return DateFormat('MMMM yyyy', 'it').format(targetDate);
      case DashboardPeriod.year:
        return (now.year + offset).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoNext = offset < 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          tooltip: 'Precedente',
        ),
        const SizedBox(width: 8),
        Text(
          _getPeriodLabel(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: canGoNext ? onNext : null,
          tooltip: 'Successivo',
        ),
      ],
    );
  }
}
