import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/budget_validation_issue_entity.dart';

import '../../../../app/app_theme.dart';
/// Banner widget that displays budget validation issues
///
/// Shows errors (red) and warnings (orange) in a prominent banner
/// at the top of the budget screen.
///
/// Example:
/// ```dart
/// ValidationAlertBanner(issues: composition.issues)
/// ```
class ValidationAlertBanner extends StatelessWidget {
  const ValidationAlertBanner({
    super.key,
    required this.issues,
    this.onDismiss,
  });

  final List<BudgetValidationIssue> issues;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();

    final errors = issues.where((i) => i.isError).toList();
    final warnings = issues.where((i) => i.isWarning).toList();
    final hasErrors = errors.isNotEmpty;

    // Determine banner color and icon based on severity
    final bannerColor = hasErrors ? AppColors.error : AppColors.warning;
    final backgroundColor = hasErrors
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.warning.withValues(alpha: 0.1);
    final icon = hasErrors ? Icons.error : Icons.warning;
    final title = hasErrors ? 'ERRORI BUDGET' : 'AVVISI BUDGET';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: bannerColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                icon,
                color: bannerColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: bannerColor,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: bannerColor.withValues(alpha: 0.6),
                  onPressed: onDismiss,
                  tooltip: 'Nascondi',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Errors list
          if (errors.isNotEmpty) ...[
            ...errors.map((issue) => _IssueRow(
                  issue: issue,
                  color: AppColors.error,
                )),
            if (warnings.isNotEmpty) const SizedBox(height: 8),
          ],

          // Warnings list
          if (warnings.isNotEmpty)
            ...warnings.map((issue) => _IssueRow(
                  issue: issue,
                  color: AppColors.warning,
                )),
        ],
      ),
    );
  }
}

/// Row displaying a single validation issue
class _IssueRow extends StatelessWidget {
  const _IssueRow({
    required this.issue,
    required this.color,
  });

  final BudgetValidationIssue issue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              issue.message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
