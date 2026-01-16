import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';
/// Budget warning indicator for 80% threshold warning
/// Updated with Italian Brutalism design: sharp edges, thicker borders, bold geometric styling
class BudgetWarningIndicator extends StatelessWidget {
  const BudgetWarningIndicator({
    super.key,
    required this.isNearLimit,
    required this.isOverBudget,
    this.remainingAmount,
  });

  final bool isNearLimit;
  final bool isOverBudget;
  final int? remainingAmount;

  @override
  Widget build(BuildContext context) {
    // Don't show anything if budget is healthy
    if (!isNearLimit && !isOverBudget) {
      return const SizedBox.shrink();
    }

    String message;
    IconData icon;
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isOverBudget) {
      final overAmount = (remainingAmount ?? 0).abs();
      message = 'OLTRE IL BUDGET DI €$overAmount';
      icon = Icons.error;
      backgroundColor = BudgetDesignTokens.dangerBorder.withValues(alpha: 0.1);
      borderColor = BudgetDesignTokens.dangerBorder;
      textColor = BudgetDesignTokens.dangerBorder;
    } else {
      // Near limit (80%+)
      message = 'VICINO AL LIMITE';
      icon = Icons.warning;
      backgroundColor = BudgetDesignTokens.warningBorder.withValues(alpha: 0.1);
      borderColor = BudgetDesignTokens.warningBorder;
      textColor = BudgetDesignTokens.warningBorder;
    }

    return Semantics(
      label: message,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2), // Sharp, brutalist
          border: Border.all(
            color: borderColor,
            width: 2, // Thicker border
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: textColor,
              semanticLabel: isOverBudget ? 'Error' : 'Warning',
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
