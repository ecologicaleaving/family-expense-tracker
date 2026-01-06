// Widget: Category Budget Card
// Feature: Italian Categories and Budget Management (004)
// Tasks: T033-T035, Extended for percentage budgets

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../budgets/presentation/providers/category_budget_provider.dart';

/// Card widget for displaying and editing a category's monthly budget
/// Supports both fixed amounts and percentage-based budgets
class CategoryBudgetCard extends ConsumerStatefulWidget {
  const CategoryBudgetCard({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.currentBudget,
    this.budgetId,
    required this.onSaveBudget,
    required this.onDeleteBudget,
    this.isGroupBudget = true,
    this.groupBudgetAmount,
    this.initialPercentage,
    this.userId,
    this.groupId,
    this.year,
    this.month,
  });

  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final int? currentBudget; // Amount in cents
  final String? budgetId;
  final Future<bool> Function(int amount) onSaveBudget;
  final Future<bool> Function() onDeleteBudget;

  // New fields for percentage support
  final bool isGroupBudget;
  final int? groupBudgetAmount; // Group budget in cents (for percentage calculation)
  final double? initialPercentage; // Initial percentage value (0-100)
  final String? userId; // For fetching previous month percentage
  final String? groupId;
  final int? year;
  final int? month;

  @override
  ConsumerState<CategoryBudgetCard> createState() => _CategoryBudgetCardState();
}

class _CategoryBudgetCardState extends ConsumerState<CategoryBudgetCard> {
  final _euroController = TextEditingController();
  final _percentageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPercentageMode = false;
  bool _isLoadingPreviousPercentage = false;

  @override
  void initState() {
    super.initState();

    // Initialize euro controller
    if (widget.currentBudget != null) {
      _euroController.text = (widget.currentBudget! / 100).toStringAsFixed(2);
    }

    // Initialize percentage mode for personal budgets
    if (!widget.isGroupBudget) {
      if (widget.initialPercentage != null) {
        _isPercentageMode = true;
        _percentageController.text = widget.initialPercentage!.toStringAsFixed(1);
        _updateEuroFromPercentage();
      } else {
        // Try to load percentage from previous month
        _loadPreviousMonthPercentage();
      }
    }
  }

  Future<void> _loadPreviousMonthPercentage() async {
    if (widget.userId == null || widget.groupId == null ||
        widget.year == null || widget.month == null) {
      return;
    }

    setState(() => _isLoadingPreviousPercentage = true);

    try {
      final notifier = ref.read(
        categoryBudgetProvider((
          groupId: widget.groupId!,
          year: widget.year!,
          month: widget.month!,
        )).notifier,
      );

      final prevPercentage = await notifier.getPreviousMonthPercentage(
        categoryId: widget.categoryId,
        userId: widget.userId!,
      );

      if (mounted && prevPercentage != null) {
        setState(() {
          _percentageController.text = prevPercentage.toStringAsFixed(1);
          _isPercentageMode = true;
        });
        _updateEuroFromPercentage();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPreviousPercentage = false);
      }
    }
  }

  @override
  void didUpdateWidget(CategoryBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentBudget != oldWidget.currentBudget && !_isEditing) {
      if (widget.currentBudget != null) {
        _euroController.text = (widget.currentBudget! / 100).toStringAsFixed(2);
      } else {
        _euroController.clear();
      }
    }

    if (widget.initialPercentage != oldWidget.initialPercentage && !_isEditing) {
      if (widget.initialPercentage != null) {
        _percentageController.text = widget.initialPercentage!.toStringAsFixed(1);
        _updateEuroFromPercentage();
      }
    }
  }

  @override
  void dispose() {
    _euroController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  /// Two-way binding: Update euro field when percentage changes
  void _onPercentageChanged(String percentageStr) {
    if (!_isPercentageMode || widget.groupBudgetAmount == null) return;

    final percentage = double.tryParse(percentageStr);
    if (percentage != null && percentage >= 0 && percentage <= 100) {
      final personalBudgetCents = (widget.groupBudgetAmount! * percentage) / 100;
      final personalBudgetEuros = personalBudgetCents / 100;
      _euroController.text = personalBudgetEuros.toStringAsFixed(2);
    }
  }

  /// Two-way binding: Update percentage field when euro changes
  void _onEuroChanged(String euroStr) {
    if (!_isPercentageMode || widget.groupBudgetAmount == null || widget.groupBudgetAmount == 0) {
      return;
    }

    final euros = double.tryParse(euroStr);
    if (euros != null && euros >= 0) {
      final percentage = (euros * 100 * 100) / widget.groupBudgetAmount!;
      if (percentage >= 0 && percentage <= 100) {
        _percentageController.text = percentage.toStringAsFixed(1);
      }
    }
  }

  void _updateEuroFromPercentage() {
    _onPercentageChanged(_percentageController.text);
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final euros = double.parse(_euroController.text);
      final cents = (euros * 100).toInt();

      // If percentage mode and we have the necessary data, save as percentage budget
      if (_isPercentageMode &&
          !widget.isGroupBudget &&
          widget.userId != null &&
          widget.groupId != null &&
          widget.year != null &&
          widget.month != null) {

        final percentage = double.parse(_percentageController.text);

        final notifier = ref.read(
          categoryBudgetProvider((
            groupId: widget.groupId!,
            year: widget.year!,
            month: widget.month!,
          )).notifier,
        );

        final success = await notifier.setPersonalPercentageBudget(
          categoryId: widget.categoryId,
          userId: widget.userId!,
          percentage: percentage,
        );

        if (mounted) {
          if (success) {
            setState(() {
              _isEditing = false;
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Budget percentuale salvato per ${widget.categoryName}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Errore nel salvare il budget percentuale'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Save as fixed budget
        final success = await widget.onSaveBudget(cents);

        if (mounted) {
          if (success) {
            setState(() {
              _isEditing = false;
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Budget salvato per ${widget.categoryName}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Errore nel salvare il budget'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina budget'),
        content: Text(
          'Vuoi eliminare il budget per "${widget.categoryName}"?',
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

    try {
      final success = await widget.onDeleteBudget();

      if (mounted) {
        if (success) {
          setState(() {
            _euroController.clear();
            _percentageController.clear();
            _isEditing = false;
            _isSaving = false;
            _isPercentageMode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Budget eliminato per ${widget.categoryName}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nell\'eliminare il budget'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBudget = widget.currentBudget != null;
    final canUsePercentage = !widget.isGroupBudget && widget.groupBudgetAmount != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(widget.categoryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.categoryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasBudget && !_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Modifica budget',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Show group budget info for personal budgets
            if (!widget.isGroupBudget && widget.groupBudgetAmount != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Budget gruppo: €${(widget.groupBudgetAmount! / 100).toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Toggle between fixed and percentage mode (only for personal budgets)
            if (canUsePercentage && (_isEditing || !hasBudget)) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Euro fisso'),
                    icon: Icon(Icons.euro, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Percentuale'),
                    icon: Icon(Icons.percent, size: 16),
                  ),
                ],
                selected: {_isPercentageMode},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isPercentageMode = newSelection.first;
                    if (_isPercentageMode) {
                      _updateEuroFromPercentage();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Budget input or display
            if (_isEditing || !hasBudget)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Percentage input (if percentage mode)
                    if (_isPercentageMode && canUsePercentage) ...[
                      TextFormField(
                        controller: _percentageController,
                        autofocus: _isEditing && _isPercentageMode,
                        enabled: !_isSaving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,1}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Percentuale del budget gruppo',
                          suffixText: '%',
                          hintText: '40.0',
                          border: OutlineInputBorder(),
                          helperText: 'Imposta la tua percentuale del budget gruppo',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci una percentuale';
                          }
                          final percentage = double.tryParse(value);
                          if (percentage == null) {
                            return 'Percentuale non valida';
                          }
                          if (percentage < 0 || percentage > 100) {
                            return 'La percentuale deve essere tra 0 e 100';
                          }
                          if (percentage == 0) {
                            return 'La percentuale deve essere maggiore di zero';
                          }
                          return null;
                        },
                        onChanged: _onPercentageChanged,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Euro input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _euroController,
                            autofocus: _isEditing && !_isPercentageMode,
                            enabled: !_isSaving,
                            readOnly: _isPercentageMode && canUsePercentage,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: _isPercentageMode && canUsePercentage
                                  ? 'Budget calcolato'
                                  : 'Budget mensile',
                              prefixText: '€ ',
                              hintText: '500.00',
                              border: const OutlineInputBorder(),
                              helperText: _isPercentageMode && canUsePercentage
                                  ? 'Calcolato automaticamente dalla percentuale'
                                  : hasBudget
                                      ? 'Modifica il budget mensile'
                                      : 'Imposta un budget mensile per questa categoria',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Inserisci un importo';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null) {
                                return 'Importo non valido';
                              }
                              if (amount < 0) {
                                return 'L\'importo non può essere negativo';
                              }
                              if (!_isPercentageMode && amount == 0) {
                                return 'L\'importo deve essere maggiore di zero';
                              }
                              if (amount > 999999.99) {
                                return 'Importo troppo elevato';
                              }
                              return null;
                            },
                            onChanged: _isPercentageMode ? null : _onEuroChanged,
                            onFieldSubmitted: (_) => _saveBudget(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isSaving || _isLoadingPreviousPercentage)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: _saveBudget,
                            tooltip: 'Salva',
                          ),
                          if (_isEditing && hasBudget)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _euroController.text =
                                      (widget.currentBudget! / 100).toStringAsFixed(2);
                                  if (widget.initialPercentage != null) {
                                    _percentageController.text =
                                        widget.initialPercentage!.toStringAsFixed(1);
                                  }
                                });
                              },
                              tooltip: 'Annulla',
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget mensile',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '€ ${(widget.currentBudget! / 100).toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (widget.initialPercentage != null) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                '${widget.initialPercentage!.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  if (hasBudget)
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Elimina'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: _deleteBudget,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
