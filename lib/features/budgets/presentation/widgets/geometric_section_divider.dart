// Widget: Geometric Section Divider
// Budget Dashboard - Italian Brutalism Design

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

/// Geometric section divider with centered text and extending lines
/// Used to separate sections in the budget dashboard
class GeometricSectionDivider extends StatelessWidget {
  const GeometricSectionDivider({
    super.key,
    required this.text,
    this.color,
    this.thickness,
  });

  final String text;
  final Color? color;
  final double? thickness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? AppColors.copper;
    final dividerThickness = thickness ?? BudgetDesignTokens.sectionDividerThickness;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Left line
          Expanded(
            child: Container(
              height: dividerThickness,
              color: dividerColor,
            ),
          ),

          // Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text.toUpperCase(),
              style: BudgetDesignTokens.sectionLabel.copyWith(
                color: dividerColor,
              ),
            ),
          ),

          // Right line
          Expanded(
            child: Container(
              height: dividerThickness,
              color: dividerColor,
            ),
          ),
        ],
      ),
    );
  }
}
