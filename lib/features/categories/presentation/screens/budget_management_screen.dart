// Screen: Budget Management
// Feature: Italian Categories and Budget Management (004)
// Tasks: T032-T035, Extended for percentage budgets

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/presentation/providers/category_budget_provider.dart';
import '../../../budgets/presentation/providers/member_budget_contribution_provider.dart';
import '../../../budgets/presentation/widgets/budget_change_notification_banner.dart';
import '../../../budgets/presentation/widgets/member_contribution_info_widget.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/category_budget_card.dart';

/// Screen for managing monthly budgets for each category
class BudgetManagementScreen extends ConsumerStatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  ConsumerState<BudgetManagementScreen> createState() =>
      _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends ConsumerState<BudgetManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final groupId = ref.watch(currentGroupIdProvider);

    // Watch categories and budgets
    final categoryState = ref.watch(categoryProvider(groupId));
    final budgetState = ref.watch(
      categoryBudgetProvider((
        groupId: groupId,
        year: now.year,
        month: now.month,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget per Categoria'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.primaryContainer,
                child: Text(
                  _getMonthYearText(now),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Spese Gruppo'),
                  Tab(text: 'Spese Personali'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: categoryState.isLoading || budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryState.errorMessage != null
              ? _buildErrorState(
                  context,
                  ref,
                  groupId,
                  categoryState.errorMessage!,
                )
              : budgetState.errorMessage != null
                  ? _buildErrorState(
                      context,
                      ref,
                      groupId,
                      budgetState.errorMessage!,
                    )
                  : Column(
                      children: [
                        // Budget change notifications (shown when group budgets change)
                        BudgetChangeNotificationBanner(
                          groupId: groupId,
                          year: now.year,
                          month: now.month,
                        ),

                        // Tab views
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Group budgets tab
                              _buildBudgetList(
                                context,
                                ref,
                                groupId,
                                categoryState,
                                budgetState,
                                now,
                                isGroupBudget: true,
                              ),
                              // Personal budgets tab
                              _buildBudgetList(
                                context,
                                ref,
                                groupId,
                                categoryState,
                                budgetState,
                                now,
                                isGroupBudget: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String errorMessage,
  ) {
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
              'Errore nel caricamento',
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
                ref.read(categoryProvider(groupId).notifier).loadCategories();
                ref
                    .read(categoryBudgetProvider((
                      groupId: groupId,
                      year: DateTime.now().year,
                      month: DateTime.now().month,
                    )).notifier)
                    .loadBudgets();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetList(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    CategoryState categoryState,
    CategoryBudgetState budgetState,
    DateTime now, {
    required bool isGroupBudget,
  }) {
    final theme = Theme.of(context);
    final categories = categoryState.categories;

    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nessuna categoria disponibile',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Le categorie verranno visualizzate qui',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informazioni',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGroupBudget
                          ? 'Imposta un budget mensile per ogni categoria di spese di gruppo. '
                              'Il budget si applica solo alle spese condivise con la famiglia.'
                          : 'Imposta un budget mensile per ogni categoria di spese personali. '
                              'Il budget si applica solo alle tue spese personali.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final category = categories[index - 1];

        // Find budget for this category and budget type
        final budget = _findBudgetForCategory(
          budgetState.budgets,
          category.id,
          isGroupBudget,
        );

        // For personal budgets, find the group budget to enable percentage calculation
        final groupBudget = !isGroupBudget
            ? _findBudgetForCategory(
                budgetState.budgets,
                category.id,
                true, // Find group budget
              )
            : null;

        // Get user ID for personal budgets
        final userId = !isGroupBudget ? ref.watch(currentUserIdProvider) : null;

        // Extract percentage if budget is percentage type
        final percentageValue =
            budget != null && budget['budget_type'] == 'PERCENTAGE'
                ? (budget['percentage_of_group'] as num?)?.toDouble()
                : null;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CategoryBudgetCard(
                categoryId: category.id,
                categoryName: category.name,
                categoryColor: theme.colorScheme.primaryContainer.toARGB32(),
                currentBudget: budget?['amount'] as int?,
                budgetId: budget?['id'] as String?,
                isGroupBudget: isGroupBudget,
                groupBudgetAmount: groupBudget?['amount'] as int?,
                initialPercentage: percentageValue,
                userId: userId,
                groupId: groupId,
                year: now.year,
                month: now.month,
                onSaveBudget: (amount) async {
                  final budgetNotifier = ref.read(
                    categoryBudgetProvider((
                      groupId: groupId,
                      year: now.year,
                      month: now.month,
                    )).notifier,
                  );

                  if (budget != null) {
                    // Update existing budget
                    return await budgetNotifier.updateBudget(
                      budgetId: budget['id'] as String,
                      amount: amount,
                    );
                  } else {
                    // Create new budget
                    return await budgetNotifier.createBudget(
                      categoryId: category.id,
                      amount: amount,
                      isGroupBudget: isGroupBudget,
                    );
                  }
                },
                onDeleteBudget: () async {
                  if (budget == null) return false;

                  final budgetNotifier = ref.read(
                    categoryBudgetProvider((
                      groupId: groupId,
                      year: now.year,
                      month: now.month,
                    )).notifier,
                  );

                  return await budgetNotifier
                      .deleteBudget(budget['id'] as String);
                },
              ),
            ),

            // Show member contributions for group budgets
            if (isGroupBudget) ...[
              Consumer(
                builder: (context, ref, child) {
                  final membersAsync = ref.watch(
                    memberBudgetContributionProvider((
                      groupId: groupId,
                      categoryId: category.id,
                      year: now.year,
                      month: now.month,
                    )),
                  );

                  return membersAsync.when(
                    data: (members) => members.isNotEmpty &&
                            members.any((m) => m.hasPercentageBudget)
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MemberContributionInfoWidget(
                              members: members,
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Map<String, dynamic>? _findBudgetForCategory(
    List<dynamic> budgets,
    String categoryId,
    bool isGroupBudget,
  ) {
    try {
      return budgets.firstWhere(
        (b) =>
            b['category_id'] == categoryId &&
            (b['is_group_budget'] ?? true) == isGroupBudget,
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _getMonthYearText(DateTime date) {
    const monthNames = [
      'Gennaio',
      'Febbraio',
      'Marzo',
      'Aprile',
      'Maggio',
      'Giugno',
      'Luglio',
      'Agosto',
      'Settembre',
      'Ottobre',
      'Novembre',
      'Dicembre',
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }
}
