import 'package:flutter/material.dart';

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
