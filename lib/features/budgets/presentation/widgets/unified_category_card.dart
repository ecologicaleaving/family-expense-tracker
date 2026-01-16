// Widget: Unified Category Card
// Budget Dashboard - Category budget card with G/P badge and inline editing

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../budgets/domain/entities/unified_budget_stats_entity.dart';
import 'budget_progress_bar.dart';

import '../../../../app/app_theme.dart';
/// Unified category budget card showing both group and personal budgets
/// Features:
/// - G/P badge (top-right floating circle)
/// - Color-coded left border (green/orange/red based on status)
/// - Inline expansion for editing
/// - Percentage or fixed budget display
class UnifiedCategoryCard extends StatefulWidget {
  const UnifiedCategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryBudgetWithStats category;
  final Future<bool> Function(int newAmount) onEdit;
  final Future<bool> Function() onDelete;

  @override
  State<UnifiedCategoryCard> createState() => _UnifiedCategoryCardState();
}

class _UnifiedCategoryCardState extends State<UnifiedCategoryCard> {
  bool _isExpanded = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = (widget.category.budgetAmount / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final euros = double.parse(_amountController.text);
      final cents = (euros * 100).toInt();

      final success = await widget.onEdit(cents);

      if (mounted) {
        if (success) {
          setState(() {
            _isExpanded = false;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Budget aggiornato per ${widget.category.categoryName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'aggiornamento'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina budget'),
        content: Text(
          'Vuoi eliminare il budget per "${widget.category.categoryName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    final success = await widget.onDelete();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget eliminato per ${widget.category.categoryName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'eliminazione'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine left border color based on status
    Color leftBorderColor;
    if (widget.category.isOverBudget) {
      leftBorderColor = BudgetDesignTokens.dangerBorder;
    } else if (widget.category.isNearLimit) {
      leftBorderColor = BudgetDesignTokens.warningBorder;
    } else {
      leftBorderColor = BudgetDesignTokens.healthyBorder;
    }

    // Badge color and letter
    final badgeColor = widget.category.isGroupBudget
        ? BudgetDesignTokens.groupBadgeBg
        : BudgetDesignTokens.personalBadgeBg;
    final badgeLetter = widget.category.isGroupBudget ? 'G' : 'P';

    return AnimatedContainer(
      duration: BudgetDesignTokens.expandDuration,
      curve: Curves.linear,
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main card with left border
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(BudgetDesignTokens.cardRadius),
              border: Border(
                left: BorderSide(
                  color: leftBorderColor,
                  width: BudgetDesignTokens.cardBorderWidth,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Category icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(widget.category.categoryColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Category name
                      Expanded(
                        child: Text(
                          widget.category.categoryName,
                          style: BudgetDesignTokens.categoryName,
                        ),
                      ),

                      // Edit button (only if not expanded)
                      if (!_isExpanded)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => setState(() => _isExpanded = true),
                          tooltip: 'Modifica',
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Percentage info (if applicable)
                  if (widget.category.percentageOfGroupBudget != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.copperLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${widget.category.percentageOfGroupBudget!.toStringAsFixed(1)}% del budget gruppo',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.copper,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Budget display or edit form
                  if (_isExpanded) ...[
                    // Edit form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  autofocus: true,
                                  enabled: !_isSaving,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Budget mensile',
                                    prefixText: '€ ',
                                    hintText: '500.00',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Inserisci un importo';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount <= 0) {
                                      return 'Importo non valido';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _save(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_isSaving)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else ...[
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: _save,
                                  tooltip: 'Salva',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = false;
                                      _amountController.text =
                                          (widget.category.budgetAmount / 100).toStringAsFixed(2);
                                    });
                                  },
                                  tooltip: 'Annulla',
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text('Elimina budget'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: _delete,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Budget amount display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '€${(widget.category.spentAmount / 100).toStringAsFixed(0)} / €${(widget.category.budgetAmount / 100).toStringAsFixed(0)}',
                          style: BudgetDesignTokens.cardAmount,
                        ),
                        Text(
                          '${widget.category.percentageUsed.toStringAsFixed(1)}%',
                          style: BudgetDesignTokens.percentageText.copyWith(
                            color: leftBorderColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Progress bar
                    BudgetProgressBar(
                      budgetAmount: widget.category.budgetAmount,
                      spentAmount: widget.category.spentAmount,
                    ),

                    // Remaining/over budget message
                    if (widget.category.isOverBudget) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            size: 16,
                            color: AppColors.terracotta,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'OLTRE IL BUDGET DI €${(widget.category.remainingAmount.abs() / 100).toStringAsFixed(0)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ],
                      ),
                    ] else if (widget.category.remainingAmount < (widget.category.budgetAmount * 0.2)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Rimanenti: €${(widget.category.remainingAmount / 100).toStringAsFixed(0)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkLight,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // G/P Badge (floating top-right)
          Positioned(
            top: -8,
            right: 8,
            child: Container(
              width: BudgetDesignTokens.badgeSize,
              height: BudgetDesignTokens.badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.parchment,
                  width: 3,
                ),
                boxShadow: const [
                  BudgetDesignTokens.sharpShadow,
                ],
              ),
              child: Center(
                child: Text(
                  badgeLetter,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BudgetDesignTokens.badgeFg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
