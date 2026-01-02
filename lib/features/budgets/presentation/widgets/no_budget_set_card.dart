import 'package:flutter/material.dart';

/// Card displayed when no budget is set, with call-to-action button
class NoBudgetSetCard extends StatelessWidget {
  const NoBudgetSetCard({
    super.key,
    required this.onSetBudget,
    this.budgetType = 'group',
  });

  final VoidCallback onSetBudget;
  final String budgetType; // 'group' or 'personal'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = budgetType == 'group';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              isGroup ? 'No Group Budget Set' : 'No Personal Budget Set',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isGroup
                  ? 'Set a monthly budget to track your family\'s spending and get alerts when approaching the limit.'
                  : 'Set a personal budget to track your individual spending including your share of group expenses.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSetBudget,
              icon: const Icon(Icons.add),
              label: Text(isGroup ? 'Set Group Budget' : 'Set Personal Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
