import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
import '../app_constants.dart';

/// AI Assistant card component with gradient background
class AIAssistantCard extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const AIAssistantCard({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sageGreen, AppColors.deepForest],
          ),
          borderRadius: AppRadius.largeRadius,
          boxShadow: AppShadows.large,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Consiglio di Finn',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
