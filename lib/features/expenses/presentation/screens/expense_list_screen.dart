import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/expense_entity.dart';

import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/widgets/category_dropdown.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_list_item.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// Screen showing list of expenses with filtering options.
class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({
    super.key,
    this.showGroupExpensesOnly,
  });

  final bool? showGroupExpensesOnly;

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedMonths = {};
  bool _initialExpansionDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data - load multiple pages to ensure we have past months
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listState = ref.read(expenseListProvider);

      // Debug: check if there are date filters
      if (listState.filterStartDate != null || listState.filterEndDate != null) {
        print('⚠️ [ExpenseList] Date filters active: ${listState.filterStartDate} to ${listState.filterEndDate}');
      }

      if (listState.expenses.isEmpty && !listState.isLoading) {
        // Load first batch
        await ref.read(expenseListProvider.notifier).loadExpenses(refresh: true);

        // Load second batch to ensure we have previous months
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await ref.read(expenseListProvider.notifier).loadMore();
        }
      }
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

  /// Group expenses by month and year
  Map<String, List<ExpenseEntity>> _groupExpensesByMonth(List<ExpenseEntity> expenses) {
    final grouped = <String, List<ExpenseEntity>>{};

    for (final expense in expenses) {
      final date = expense.date;
      final key = DateFormat('yyyy-MM').format(date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(expense);
    }

    // Sort keys in descending order (newest first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, grouped[key]!)),
    );
  }

  /// Get current month key (yyyy-MM)
  String get _currentMonthKey => DateFormat('yyyy-MM').format(DateTime.now());

  /// Format month key for display
  String _formatMonthHeader(String monthKey) {
    final date = DateTime.parse('$monthKey-01');
    return DateFormat('MMMM yyyy', 'it_IT').format(date);
  }

  /// Calculate total amount for a list of expenses
  double _calculateTotal(List<ExpenseEntity> expenses) {
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(expenseListProvider);
    final theme = Theme.of(context);

    return _buildBody(theme, listState);
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

    // Group expenses by month
    final groupedExpenses = _groupExpensesByMonth(listState.expenses);

    // Set current month as expanded on first load
    if (!_initialExpansionDone && groupedExpenses.isNotEmpty) {
      _initialExpansionDone = true;
      _expandedMonths.add(_currentMonthKey);
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '\u20ac',
      decimalDigits: 2,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(expenseListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: groupedExpenses.length + (listState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= groupedExpenses.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final monthKey = groupedExpenses.keys.elementAt(index);
          final monthExpenses = groupedExpenses[monthKey]!;
          final monthTotal = _calculateTotal(monthExpenses);
          final isExpanded = _expandedMonths.contains(monthKey);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Month header (always visible)
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedMonths.remove(monthKey);
                      } else {
                        _expandedMonths.add(monthKey);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    color: theme.colorScheme.primaryContainer,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatMonthHeader(monthKey),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(monthTotal),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              '${monthExpenses.length} ${monthExpenses.length == 1 ? 'spesa' : 'spese'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
                // Expense list (collapsible)
                if (isExpanded)
                  ...monthExpenses.asMap().entries.map((entry) {
                    final i = entry.key;
                    final expense = entry.value;
                    final canDelete = expense.canDelete(currentUser?.id ?? '', isAdmin);

                    return Column(
                      children: [
                        Dismissible(
                          key: Key(expense.id),
                          direction: canDelete ? DismissDirection.endToStart : DismissDirection.none,
                          confirmDismiss: (direction) => _showDeleteConfirmDialog(context, expense),
                          onDismissed: (direction) => _handleSwipeDelete(expense),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: theme.colorScheme.error,
                            child: Icon(
                              Icons.delete,
                              color: theme.colorScheme.onError,
                              size: 28,
                            ),
                          ),
                          child: ExpenseListItem(
                            expense: expense,
                            onTap: () => context.go('/expense/${expense.id}'),
                          ),
                        ),
                        if (i < monthExpenses.length - 1)
                          const Divider(height: 1),
                      ],
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, ExpenseEntity expense) {
    return DeleteConfirmationDialog.show(
      context,
      expenseName: expense.merchant ?? expense.formattedAmount,
      isReimbursable: expense.isPendingReimbursement,
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
    ExpenseFilterBottomSheet.show(context);
  }
}

class ExpenseFilterBottomSheet extends ConsumerStatefulWidget {
  const ExpenseFilterBottomSheet({super.key});

  @override
  ConsumerState<ExpenseFilterBottomSheet> createState() => _ExpenseFilterBottomSheetState();

  /// Show the filter bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExpenseFilterBottomSheet(),
    );
  }
}

class _ExpenseFilterBottomSheetState extends ConsumerState<ExpenseFilterBottomSheet> {
  DateTimeRange? _dateRange;
  String? _selectedCategoryId;

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
    _selectedCategoryId = state.filterCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final groupId = authState.user?.groupId;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtra spese',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Category filter
            if (groupId != null) ...[
              CategoryDropdownMRU(
                value: _selectedCategoryId,
                onChanged: (categoryId) => setState(() => _selectedCategoryId = categoryId),
                label: 'Categoria',
                hint: 'Tutte le categorie',
              ),
              const SizedBox(height: 16),
            ],

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
    // Apply category filter (null to clear)
    ref.read(expenseListProvider.notifier).setFilterCategory(_selectedCategoryId);

    // Apply date range filter
    ref.read(expenseListProvider.notifier).setFilterDateRange(
          _dateRange?.start,
          _dateRange?.end,
        );
    Navigator.of(context).pop();
  }
}
