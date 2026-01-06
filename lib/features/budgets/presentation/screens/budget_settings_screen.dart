import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/budget_actions_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/budget_warning_indicator.dart';
import '../widgets/no_budget_set_card.dart';

/// Budget settings screen for managing group and personal budgets
class BudgetSettingsScreen extends ConsumerStatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  ConsumerState<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends ConsumerState<BudgetSettingsScreen> {
  final _groupBudgetController = TextEditingController();
  final _personalBudgetController = TextEditingController();
  bool _isSubmittingGroup = false;
  bool _isSubmittingPersonal = false;

  @override
  void dispose() {
    _groupBudgetController.dispose();
    _personalBudgetController.dispose();
    super.dispose();
  }

  Future<void> _submitGroupBudget() async {
    if (_groupBudgetController.text.isEmpty) return;

    setState(() => _isSubmittingGroup = true);

    try {
      final amount = int.parse(_groupBudgetController.text);
      final now = DateTime.now();
      final groupId = ref.read(currentGroupIdProvider);

      final result = await ref.read(budgetActionsProvider).setGroupBudget(
        groupId: groupId,
        amount: amount,
        month: now.month,
        year: now.year,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group budget updated successfully')),
          );
          _groupBudgetController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update group budget')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingGroup = false);
      }
    }
  }

  Future<void> _submitPersonalBudget() async {
    if (_personalBudgetController.text.isEmpty) return;

    setState(() => _isSubmittingPersonal = true);

    try {
      final amount = int.parse(_personalBudgetController.text);
      final now = DateTime.now();
      final userId = ref.read(currentUserIdProvider);

      final result = await ref.read(budgetActionsProvider).setPersonalBudget(
        userId: userId,
        amount: amount,
        month: now.month,
        year: now.year,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Personal budget updated successfully')),
          );
          _personalBudgetController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update personal budget')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingPersonal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupId = ref.watch(currentGroupIdProvider);
    final userId = ref.watch(currentUserIdProvider);
    final budgetState = ref.watch(budgetProvider((groupId: groupId, userId: userId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Settings'),
      ),
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Quick access to category budgets
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Budget per Categoria',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestisci i budget mensili per ogni categoria di spesa',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.push('/budget-management'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Gestisci Budget per Categoria'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Group Budget Section
                Text(
                  'Group Budget',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a monthly budget for your family group',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                if (budgetState.groupBudget != null) ...[
                  // Current group budget display
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Budget',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                budgetState.groupBudget!.formattedAmount,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          BudgetProgressBar(
                            budgetAmount: budgetState.groupStats.budgetAmount ?? 0,
                            spentAmount: budgetState.groupStats.spentAmount,
                          ),
                          const SizedBox(height: 12),
                          BudgetWarningIndicator(
                            isNearLimit: budgetState.groupStats.isNearLimit,
                            isOverBudget: budgetState.groupStats.isOverBudget,
                            remainingAmount: budgetState.groupStats.remainingAmount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  NoBudgetSetCard(
                    budgetType: 'group',
                    onSetBudget: () {
                      // Focus on text field below
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Group budget input
                TextField(
                  controller: _groupBudgetController,
                  decoration: InputDecoration(
                    labelText: 'New Budget Amount',
                    hintText: 'Enter amount in euros',
                    prefixText: '€ ',
                    border: const OutlineInputBorder(),
                    helperText: 'Whole euros only (no cents)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isSubmittingGroup ? null : _submitGroupBudget,
                  child: _isSubmittingGroup
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Group Budget'),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // Personal Budget Section
                Text(
                  'Personal Budget',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your individual spending (includes both personal expenses and your share of group expenses)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                if (budgetState.personalBudget != null) ...[
                  // Current personal budget display
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Budget',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                budgetState.personalBudget!.formattedAmount,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          BudgetProgressBar(
                            budgetAmount: budgetState.personalStats.budgetAmount ?? 0,
                            spentAmount: budgetState.personalStats.spentAmount,
                          ),
                          const SizedBox(height: 12),
                          BudgetWarningIndicator(
                            isNearLimit: budgetState.personalStats.isNearLimit,
                            isOverBudget: budgetState.personalStats.isOverBudget,
                            remainingAmount: budgetState.personalStats.remainingAmount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  NoBudgetSetCard(
                    budgetType: 'personal',
                    onSetBudget: () {
                      // Focus on text field below
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Personal budget input
                TextField(
                  controller: _personalBudgetController,
                  decoration: InputDecoration(
                    labelText: 'New Budget Amount',
                    hintText: 'Enter amount in euros',
                    prefixText: '€ ',
                    border: const OutlineInputBorder(),
                    helperText: 'Whole euros only (no cents)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isSubmittingPersonal ? null : _submitPersonalBudget,
                  child: _isSubmittingPersonal
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Personal Budget'),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
