import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/budget_composition_provider.dart';
import '../widgets/budget_overview_card.dart';
import '../widgets/category_budget_tile.dart';
import '../widgets/editable_section.dart';
import '../widgets/validation_alert_banner.dart';

/// Unified budget management screen
///
/// Replaces the previous 3 separate screens:
/// - budget_settings_screen.dart
/// - budget_dashboard_screen.dart
/// - budget_management_screen.dart
///
/// Features:
/// - Group budget editing
/// - Category budgets with member contributions
/// - Drill-down expandable categories
/// - Validation alerts
/// - Real-time sync
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);

    final params = BudgetCompositionParams(
      groupId: groupId,
      year: _selectedYear,
      month: _selectedMonth,
    );

    final compositionAsync = ref.watch(budgetCompositionProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getMonthYearTitle(),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.terracotta,
        foregroundColor: AppColors.cream,
        actions: [
          // Month selector
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showMonthPicker(context),
            tooltip: 'Seleziona mese',
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(budgetCompositionProvider(params).notifier).refresh();
            },
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      backgroundColor: AppColors.parchment,
      body: compositionAsync.when(
        loading: () => const LoadingIndicator(message: 'Caricamento budget...'),
        error: (error, stack) {
          debugPrint('Budget composition error: $error');
          debugPrint('Stack trace: $stack');
          return ErrorDisplay(
            icon: Icons.error_outline,
            title: 'Errore caricamento budget',
            message: error.toString(),
            onRetry: () {
              ref.read(budgetCompositionProvider(params).notifier).refresh();
            },
          );
        },
        data: (composition) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(budgetCompositionProvider(params).notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Validation alerts
              if (composition.hasIssues)
                ValidationAlertBanner(issues: composition.issues),

              // Overview card
              BudgetOverviewCard(composition: composition),

              const SizedBox(height: 24),

              // Group budget section
              _buildSectionHeader('Budget Gruppo'),
              const SizedBox(height: 12),
              EditableSection(
                label: 'Budget Mensile Gruppo',
                value: composition.groupBudget?.amount,
                icon: Icons.groups,
                color: AppColors.terracotta,
                placeholder: 'Imposta budget gruppo',
                helperText: 'Budget totale mensile per la famiglia',
                onSave: (amount) async {
                  await ref
                      .read(budgetCompositionProvider(params).notifier)
                      .setGroupBudget(amount);
                },
              ),

              const SizedBox(height: 24),

              // Category budgets section
              _buildSectionHeader(
                'Budget per Categoria',
                subtitle:
                    '${composition.categoryBudgets.length} ${composition.categoryBudgets.length == 1 ? "categoria" : "categorie"}',
              ),
              const SizedBox(height: 12),

              // Categories list
              if (composition.categoryBudgets.isEmpty)
                _buildEmptyState()
              else
                ...composition.categoryBudgets.map((categoryBudget) {
                  // Expand alert categories by default
                  final shouldExpand = categoryBudget.stats.isOverBudget ||
                      categoryBudget.stats.isNearLimit;

                  return CategoryBudgetTile(
                    key: ValueKey(categoryBudget.categoryId),
                    categoryBudget: categoryBudget,
                    params: params,
                    initiallyExpanded: shouldExpand,
                  );
                }),

              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.parchmentDark,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 48,
            color: AppColors.inkFaded,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun budget per categoria',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.inkLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inizia aggiungendo un budget per le tue categorie',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.inkFaded,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMonthYearTitle() {
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
    return 'Budget ${monthNames[_selectedMonth - 1]} $_selectedYear';
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
        currentMonth: now.month,
        currentYear: now.year,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedMonth = result['month']!;
        _selectedYear = result['year']!;
      });
    }
  }
}

/// Month picker dialog
class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.initialMonth,
    required this.initialYear,
    required this.currentMonth,
    required this.currentYear,
  });

  final int initialMonth;
  final int initialYear;
  final int currentMonth;
  final int currentYear;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic',
    ];

    return AlertDialog(
      title: Text(
        'Seleziona Mese',
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() => _selectedYear--);
                  },
                ),
                Text(
                  '$_selectedYear',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() => _selectedYear++);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Month grid
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected =
                    month == _selectedMonth && _selectedYear == widget.initialYear;
                final isCurrent = month == widget.currentMonth &&
                    _selectedYear == widget.currentYear;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedMonth = month);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.terracotta
                          : isCurrent
                              ? AppColors.terracotta.withValues(alpha: 0.2)
                              : AppColors.parchment,
                      borderRadius: BorderRadius.circular(4),
                      border: isCurrent && !isSelected
                          ? Border.all(color: AppColors.terracotta, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monthNames[index],
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.cream : AppColors.ink,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annulla',
            style: GoogleFonts.dmSans(),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'month': _selectedMonth,
              'year': _selectedYear,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.terracotta,
            foregroundColor: AppColors.cream,
          ),
          child: Text(
            'Conferma',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
