// Widget: Budget Change Notification Banner
// Feature: Italian Categories and Budget Management (004)
// Shows notifications when group budget changes affect user's percentage budgets

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_change_notification_provider.dart';

/// Banner widget to display budget change notifications
class BudgetChangeNotificationBanner extends ConsumerWidget {
  const BudgetChangeNotificationBanner({
    super.key,
    required this.groupId,
    required this.year,
    required this.month,
  });

  final String groupId;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(
      budgetChangeNotificationProvider((
        groupId: groupId,
        year: year,
        month: month,
        userId: null, // Will use current user from auth
      )),
    );

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.error.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.onErrorContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget modificati',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'I budget di gruppo sono cambiati, i tuoi budget personali sono stati ricalcolati',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(
                color: theme.colorScheme.error.withOpacity(0.2),
                height: 1,
              ),

              // Notifications list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => Divider(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isIncrease = notification.isIncrease;

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isIncrease
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: isIncrease
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    title: Text(
                      notification.categoryName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Budget gruppo: ${notification.formattedOldGroupBudget} → ${notification.formattedNewGroupBudget}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Tuo budget (${notification.percentageValue.toStringAsFixed(1)}%): '
                          '${notification.formattedOldPersonalBudget} → ${notification.formattedNewPersonalBudget}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        isIncrease ? '+' : '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isIncrease
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      backgroundColor: isIncrease
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
              ),

              // Dismiss button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Ho capito'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    onPressed: () {
                      // Invalidate the provider to clear notifications
                      ref.invalidate(budgetChangeNotificationProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
