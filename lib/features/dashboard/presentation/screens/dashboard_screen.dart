import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/presentation/providers/budget_actions_provider.dart';
import '../../../budgets/presentation/widgets/group_budget_card.dart';
import '../../../budgets/presentation/widgets/personal_budget_card.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/member_breakdown_list.dart';
import '../widgets/member_filter.dart';
import '../widgets/period_selector.dart';
import '../widgets/recent_expenses_list.dart';
import '../widgets/total_summary_card.dart';
import '../widgets/trend_bar_chart.dart';

/// Main dashboard screen with tabs for personal and group views.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final mode = _tabController.index == 0
          ? DashboardViewMode.group
          : DashboardViewMode.personal;
      ref.read(dashboardProvider.notifier).setViewMode(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final groupState = ref.watch(groupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.group),
              text: 'Gruppo',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: 'Personale',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: dashboardState.isLoading
                ? null
                : () => ref.read(dashboardProvider.notifier).refresh(),
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Group view
          _DashboardContent(
            dashboardState: dashboardState,
            members: groupState.members,
            isPersonalView: false,
            onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
            onPeriodChanged: (period) =>
                ref.read(dashboardProvider.notifier).setPeriod(period),
            onMemberFilterChanged: (memberId) =>
                ref.read(dashboardProvider.notifier).setMemberFilter(memberId),
          ),
          // Personal view
          _DashboardContent(
            dashboardState: dashboardState,
            members: groupState.members,
            isPersonalView: true,
            onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
            onPeriodChanged: (period) =>
                ref.read(dashboardProvider.notifier).setPeriod(period),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.dashboardState,
    required this.members,
    required this.isPersonalView,
    required this.onRefresh,
    required this.onPeriodChanged,
    this.onMemberFilterChanged,
  });

  final DashboardState dashboardState;
  final List<dynamic> members;
  final bool isPersonalView;
  final VoidCallback onRefresh;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final ValueChanged<String?>? onMemberFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dashboardState.status == DashboardStatus.error &&
        dashboardState.stats == null) {
      return ErrorDisplay(
        message: dashboardState.errorMessage ?? 'Errore nel caricamento',
        onRetry: onRefresh,
      );
    }

    if (dashboardState.status == DashboardStatus.loading &&
        dashboardState.stats == null) {
      return const LoadingIndicator(message: 'Caricamento dati...');
    }

    final stats = dashboardState.stats;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period selector
            Center(
              child: PeriodSelector(
                selectedPeriod: dashboardState.period,
                onPeriodChanged: onPeriodChanged,
              ),
            ),
            const SizedBox(height: 16),

            // Member filter (group view only)
            if (!isPersonalView && onMemberFilterChanged != null) ...[
              MemberFilterChips(
                members: members.cast(),
                selectedMemberId: dashboardState.selectedMemberId,
                onMemberChanged: onMemberFilterChanged!,
              ),
              const SizedBox(height: 16),
            ],

            // Error banner if we have stale data
            if (dashboardState.errorMessage != null && stats != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dati non aggiornati. Tocca per riprovare.',
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                      color: Colors.amber.shade900,
                    ),
                  ],
                ),
              ),

            // Budget cards
            if (!isPersonalView) ...[
              // Group budget card (group view only)
              Consumer(
                builder: (context, ref, child) {
                  final groupId = ref.watch(currentGroupIdProvider);
                  final userId = ref.watch(currentUserIdProvider);

                  return GroupBudgetCard(
                    groupId: groupId,
                    userId: userId,
                    onNavigateToSettings: () {
                      context.push('/budget-settings');
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Personal budget card (personal view only)
              Consumer(
                builder: (context, ref, child) {
                  final groupId = ref.watch(currentGroupIdProvider);
                  final userId = ref.watch(currentUserIdProvider);

                  return PersonalBudgetCard(
                    groupId: groupId,
                    userId: userId,
                    onNavigateToSettings: () {
                      context.push('/budget-settings');
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Recent expenses list
            Consumer(
              builder: (context, ref, child) {
                final recentExpensesAsync = isPersonalView
                    ? ref.watch(recentPersonalExpensesProvider)
                    : ref.watch(recentGroupExpensesProvider);

                return recentExpensesAsync.when(
                  data: (expenses) => RecentExpensesList(
                    expenses: expenses,
                    title: isPersonalView ? 'Le tue spese recenti' : 'Spese recenti del gruppo',
                    isLoading: false,
                    onRefresh: onRefresh,
                  ),
                  loading: () => RecentExpensesList(
                    expenses: const [],
                    title: isPersonalView ? 'Le tue spese recenti' : 'Spese recenti del gruppo',
                    isLoading: true,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),

            // Summary card
            if (stats != null) ...[
              TotalSummaryCard(
                stats: stats,
                isPersonalView: isPersonalView,
              ),
              const SizedBox(height: 16),

              // Empty state
              if (stats.isEmpty)
                EmptyDisplay(
                  icon: Icons.receipt_long,
                  message: isPersonalView
                      ? 'Non hai ancora spese in questo periodo'
                      : 'Nessuna spesa del gruppo in questo periodo',
                  actionLabel: 'Aggiungi spesa',
                  action: () {
                    // Navigate to add expense
                    Navigator.of(context).pushNamed('/add-expense');
                  },
                )
              else ...[
                // Category breakdown
                CategoryPieChart(categories: stats.byCategory),
                const SizedBox(height: 16),

                // Trend chart
                TrendBarChart(
                  trend: stats.trend,
                  period: stats.period,
                ),
                const SizedBox(height: 16),

                // Member breakdown (group view only)
                if (!isPersonalView && stats.byMember.isNotEmpty)
                  MemberBreakdownList(
                    members: stats.byMember,
                    onMemberTap: onMemberFilterChanged,
                  ),
              ],
            ],

            // Loading overlay
            if (dashboardState.isLoading && stats != null)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: InlineLoadingIndicator(
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
