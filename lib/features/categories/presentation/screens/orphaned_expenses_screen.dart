// Screen: Orphaned Expenses Management
// Feature: Italian Categories and Budget Management (004)
// Tasks: T066-T077

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../expenses/presentation/providers/orphaned_expenses_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/category_picker_dialog.dart';

class OrphanedExpensesScreen extends ConsumerStatefulWidget {
  const OrphanedExpensesScreen({super.key});

  @override
  ConsumerState<OrphanedExpensesScreen> createState() =>
      _OrphanedExpensesScreenState();
}

class _OrphanedExpensesScreenState
    extends ConsumerState<OrphanedExpensesScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    final orphanedState = ref.watch(orphanedExpensesProvider(groupId));
    final orphanedExpenses = orphanedState.expenses;
    final isLoading = orphanedState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} selezionati')
            : const Text('Spese senza categoria'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      _selectedIds.addAll(
                        orphanedExpenses.map((e) => e.id),
                      );
                    });
                  },
                ),
              ]
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orphanedState.errorMessage != null
              ? _buildErrorState(orphanedState.errorMessage!, groupId)
              : orphanedExpenses.isEmpty
                  ? _buildEmptyState()
                  : _buildExpenseList(orphanedExpenses),
      bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
          ? _buildBottomActionSheet()
          : null,
    );
  }

  Widget _buildErrorState(String errorMessage, String groupId) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Errore',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(orphanedExpensesProvider(groupId).notifier)
                    .loadOrphanedExpenses();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Tutte le spese sono categorizzate!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Non ci sono spese senza categoria',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List expenses) {
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final id = expense.id;
        final isSelected = _selectedIds.contains(id);

        return ListTile(
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(id);
                      } else {
                        _selectedIds.remove(id);
                      }
                    });
                  },
                )
              : null,
          title: Text(expense.merchant ?? 'Spesa'),
          subtitle: Text(
            '€${expense.amount.toStringAsFixed(2)} - '
            '${_formatDate(expense.date)}',
          ),
          trailing: _isSelectionMode ? null : const Icon(Icons.chevron_right),
          selected: isSelected,
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedIds.add(id);
            });
          },
          onTap: _isSelectionMode
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(id);
                    } else {
                      _selectedIds.add(id);
                    }
                  });
                }
              : null,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _buildBottomActionSheet() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton(
          onPressed: _isProcessing ? null : _showCategoryPicker,
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assegna categoria'),
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker() async {
    final groupId = ref.read(currentGroupIdProvider);
    final categoryState = ref.read(categoryProvider(groupId));

    if (categoryState.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caricamento categorie in corso...'),
        ),
      );
      return;
    }

    if (categoryState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${categoryState.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final categoryId = await showCategoryPicker(
      context: context,
      categories: categoryState.categories,
      title: 'Seleziona categoria',
    );

    if (categoryId != null && mounted) {
      await _batchUpdateCategory(categoryId);
    }
  }

  Future<void> _batchUpdateCategory(String categoryId) async {
    setState(() => _isProcessing = true);

    try {
      final groupId = ref.read(currentGroupIdProvider);
      final success = await ref
          .read(orphanedExpensesProvider(groupId).notifier)
          .batchReassignToCategory(
            expenseIds: _selectedIds.toList(),
            newCategoryId: categoryId,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedIds.length} spese aggiornate'),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _isSelectionMode = false;
            _selectedIds.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nessuna spesa aggiornata'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
