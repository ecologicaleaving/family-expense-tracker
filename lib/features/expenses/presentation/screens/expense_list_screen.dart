import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/expense_entity.dart';

import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_list_item.dart';

/// Screen showing list of expenses with filtering options.
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load expenses on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseListProvider.notifier).loadExpenses(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(expenseListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(expenseListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Le mie spese'),
        actions: [
          if (listState.hasFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => ref.read(expenseListProvider.notifier).clearFilters(),
              tooltip: 'Rimuovi filtri',
            ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filtra',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/scan-receipt'),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
      body: _buildBody(theme, listState),
    );
  }

  Widget _buildBody(ThemeData theme, ExpenseListState listState) {
    if (listState.isLoading && listState.expenses.isEmpty) {
      return const LoadingIndicator(message: 'Caricamento spese...');
    }

    if (listState.hasError && listState.expenses.isEmpty) {
      return ErrorDisplay(
        message: listState.errorMessage ?? 'Errore durante il caricamento',
        onRetry: () => ref.read(expenseListProvider.notifier).refresh(),
      );
    }

    if (listState.isEmpty) {
      return EmptyDisplay(
        message: listState.hasFilters
            ? 'Nessuna spesa corrisponde ai filtri selezionati'
            : 'Non hai ancora registrato nessuna spesa',
        icon: Icons.receipt_long_outlined,
      );
    }

    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isGroupAdminProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(expenseListProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: listState.expenses.length + (listState.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= listState.expenses.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final expense = listState.expenses[index];
          final canDelete = expense.canDelete(currentUser?.id ?? '', isAdmin);

          return Dismissible(
            key: Key(expense.id),
            direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
            // confirmDismiss: (direction) => _showDeleteConfirmDialog(context),
            onDismissed: (direction) => _handleSwipeDelete(expense),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Theme.of(context).colorScheme.error,
              child: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onError,
                size: 28,
              ),
            ),
            child: ExpenseListItem(
              expense: expense,
              onTap: () => context.go('/expense/${expense.id}'),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina spesa'),
        content: const Text(
          'Sei sicuro di voler eliminare questa spesa? L\'azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  /// Handles the swipe delete with immediate backend deletion
  Future<void> _handleSwipeDelete(ExpenseEntity expense) async {
    // Remove from UI immediately (already done by Dismissible)
    ref.read(expenseListProvider.notifier).removeExpenseFromList(expense.id);

    // Show loading snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eliminazione in corso...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Execute immediate backend deletion
    final success = await ref.read(expenseFormProvider.notifier).deleteExpense(
          expenseId: expense.id,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (success) {
      // Refresh dashboard to reflect the deleted expense
      ref.read(dashboardProvider.notifier).refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spesa eliminata'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // If delete failed, restore the item to the list
      ref.read(expenseListProvider.notifier).addExpense(expense);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Errore durante l\'eliminazione'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

class _FilterBottomSheet extends ConsumerStatefulWidget {
  const _FilterBottomSheet();

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final state = ref.read(expenseListProvider);
    if (state.filterStartDate != null && state.filterEndDate != null) {
      _dateRange = DateTimeRange(
        start: state.filterStartDate!,
        end: state.filterEndDate!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtra spese',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Date range filter
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Periodo'),
            subtitle: _dateRange != null
                ? Text(
                    '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                  )
                : const Text('Tutte le date'),
            trailing: _dateRange != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dateRange = null),
                  )
                : null,
            onTap: _selectDateRange,
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(expenseListProvider.notifier).clearFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancella filtri'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Applica'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _applyFilters() {
    ref.read(expenseListProvider.notifier).setFilterDateRange(
          _dateRange?.start,
          _dateRange?.end,
        );
    Navigator.of(context).pop();
  }
}
