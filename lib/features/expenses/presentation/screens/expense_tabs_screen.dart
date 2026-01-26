import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/presentation/widgets/category_dropdown.dart';
import '../providers/expense_provider.dart';
import 'expense_list_screen.dart';

/// Screen with tabs for Personal and Group expenses
class ExpenseTabsScreen extends ConsumerStatefulWidget {
  const ExpenseTabsScreen({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  ConsumerState<ExpenseTabsScreen> createState() => _ExpenseTabsScreenState();
}

class _ExpenseTabsScreenState extends ConsumerState<ExpenseTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context) {
    ExpenseFilterBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spese'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Spese personali'),
            Tab(text: 'Spese di gruppo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Personal expenses only
          ExpenseListScreen(showGroupExpensesOnly: false),
          // Tab 2: Group expenses (all group expenses)
          ExpenseListScreen(showGroupExpensesOnly: true),
        ],
      ),
    );
  }
}
