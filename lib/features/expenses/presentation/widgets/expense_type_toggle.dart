import 'package:flutter/material.dart';

/// Toggle widget for selecting expense type (Group or Personal).
///
/// Uses Material 3 SegmentedButton for a modern, accessible toggle.
class ExpenseTypeToggle extends StatelessWidget {
  const ExpenseTypeToggle({
    super.key,
    required this.isGroupExpense,
    required this.onChanged,
    this.enabled = true,
  });

  final bool isGroupExpense;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: true,
          label: Text('Group'),
          icon: Icon(Icons.group),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text('Personal'),
          icon: Icon(Icons.person),
        ),
      ],
      selected: {isGroupExpense},
      onSelectionChanged: enabled ? (Set<bool> newSelection) {
        if (newSelection.isNotEmpty) {
          onChanged(newSelection.first);
        }
      } : null,
      showSelectedIcon: false,
    );
  }
}
