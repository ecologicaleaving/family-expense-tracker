import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/icon_matching_service.dart';
import '../../domain/entities/expense_entity.dart';
import '../screens/expense_tabs_screen.dart';

/// Widget showing expense summary grouped by category
class ExpenseCategorySummary extends StatefulWidget {
  const ExpenseCategorySummary({
    super.key,
    required this.expenses,
    required this.filter,
  });

  final List<ExpenseEntity> expenses;
  final ExpenseFilter filter;

  @override
  State<ExpenseCategorySummary> createState() => _ExpenseCategorySummaryState();
}

class _ExpenseCategorySummaryState extends State<ExpenseCategorySummary> {
  bool _isExpanded = false;

  /// Get the first name for an expense's payer
  String _getPersonName(ExpenseEntity expense) {
    final fullName = expense.paidByName ?? expense.createdByName ?? '';
    if (fullName.isEmpty) return 'Sconosciuto';
    return fullName.split(' ').first;
  }

  /// Build per-person totals for all expenses
  Widget _buildPersonTotals(ThemeData theme, NumberFormat currencyFormat, double totalAmount) {
    // Group expenses by person
    final personTotals = <String, double>{};
    for (final expense in widget.expenses) {
      final name = _getPersonName(expense);
      personTotals[name] = (personTotals[name] ?? 0.0) + expense.amount;
    }

    // Sort by name
    final sortedPersons = personTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    final showTotal = sortedPersons.length > 1;

    // Use Wrap for horizontal layout with automatic wrapping
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Each person as a compact chip
        for (final person in sortedPersons)
          Text(
            '${person.key}: ${currencyFormat.format(person.value)}',
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        // Total if multiple persons
        if (showTotal)
          Text(
            '• Tot.: ${currencyFormat.format(totalAmount)}',
            style: textStyle?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ],
    );
  }

  /// Build per-person totals for a specific category
  Widget _buildCategoryPersonTotals(
    String categoryName,
    ThemeData theme,
    NumberFormat currencyFormat,
    double categoryTotal,
  ) {
    // Filter expenses by category
    final categoryExpenses = widget.expenses.where(
      (expense) => (expense.categoryName ?? 'Altro') == categoryName,
    ).toList();

    // Group by person
    final personTotals = <String, double>{};
    for (final expense in categoryExpenses) {
      final name = _getPersonName(expense);
      personTotals[name] = (personTotals[name] ?? 0.0) + expense.amount;
    }

    // Sort by name
    final sortedPersons = personTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 11,
    );

    final showTotal = sortedPersons.length > 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Each person on its own line
          for (final person in sortedPersons)
            Text(
              '${person.key}: ${currencyFormat.format(person.value)}',
              style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          // Total if multiple persons
          if (showTotal)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Tot.: ${currencyFormat.format(categoryTotal)}',
                style: textStyle?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '\u20ac',
      decimalDigits: 2,
    );

    // Group expenses by category
    final categoryTotals = <String, double>{};
    for (final expense in widget.expenses) {
      final category = expense.categoryName ?? 'Altro';
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + expense.amount;
    }

    // Sort by amount descending
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAmount = categoryTotals.values.fold<double>(0.0, (sum, amount) => sum + amount);

    if (sortedCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.pie_chart,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spesa per Categoria',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildPersonTotals(theme, currencyFormat, totalAmount),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 350,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sortedCategories.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final categoryName = entry.key;
                final amount = entry.value;
                final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          IconMatchingService.getDefaultIconForCategory(categoryName),
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    categoryName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            _buildCategoryPersonTotals(
                              categoryName,
                              theme,
                              currencyFormat,
                              amount,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ),
          ],
        ],
      ),
    );
  }
}
