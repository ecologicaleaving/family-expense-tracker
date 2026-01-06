import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/utils/currency_utils.dart';

/// Reusable widget for inline editing of budget amounts
///
/// Supports two modes:
/// - Display mode: Shows value with edit icon
/// - Edit mode: Shows TextField with Save/Cancel buttons
///
/// Example:
/// ```dart
/// EditableSection(
///   label: "Budget Gruppo",
///   value: 500000, // in cents
///   onSave: (newAmount) async { await saveBudget(newAmount); },
///   onDelete: canDelete ? () async { await deleteBudget(); } : null,
/// )
/// ```
class EditableSection extends StatefulWidget {
  const EditableSection({
    super.key,
    required this.label,
    this.value,
    required this.onSave,
    this.onDelete,
    this.icon,
    this.color,
    this.helperText,
    this.placeholder = 'Inserisci importo',
  });

  final String label;
  final int? value; // Amount in cents, null if not set
  final Future<void> Function(int amount) onSave;
  final Future<void> Function()? onDelete;
  final IconData? icon;
  final Color? color;
  final String? helperText;
  final String placeholder;

  @override
  State<EditableSection> createState() => _EditableSectionState();
}

class _EditableSectionState extends State<EditableSection> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _errorMessage = null;
      // Pre-fill with current value (in euros)
      if (widget.value != null) {
        final euros = CurrencyUtils.centsToEuro(widget.value!);
        _controller.text = euros.toStringAsFixed(0);
      } else {
        _controller.clear();
      }
    });
    // Focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _errorMessage = null;
      _controller.clear();
    });
  }

  Future<void> _saveValue() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Inserisci un importo');
      return;
    }

    final cents = CurrencyUtils.parseCentsFromInput(input);
    if (cents == null) {
      setState(() => _errorMessage = 'Importo non valido');
      return;
    }

    if (cents <= 0) {
      setState(() => _errorMessage = 'L\'importo deve essere positivo');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(cents);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _controller.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Errore: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _deleteValue() async {
    if (widget.onDelete == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Conferma eliminazione',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Sei sicuro di voler eliminare questo budget?',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annulla', style: GoogleFonts.dmSans()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Elimina', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await widget.onDelete!();
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Errore eliminazione: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionColor = widget.color ?? AppColors.copper;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.parchmentDark,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: sectionColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.inkLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Display mode or Edit mode
          if (!_isEditing) ...[
            // Display mode
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value != null
                        ? CurrencyUtils.formatCents(widget.value!)
                        : widget.placeholder,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.value != null ? sectionColor : AppColors.inkFaded,
                    ),
                  ),
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit),
                  iconSize: 20,
                  color: sectionColor,
                  onPressed: _isSaving ? null : _startEditing,
                  tooltip: 'Modifica',
                ),
                // Delete button
                if (widget.onDelete != null && widget.value != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: AppColors.error,
                    onPressed: _isSaving ? null : _deleteValue,
                    tooltip: 'Elimina',
                  ),
              ],
            ),
          ] else ...[
            // Edit mode
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_isSaving,
              decoration: InputDecoration(
                hintText: 'Es: 1500',
                prefixText: '€ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: BorderSide(color: sectionColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: BorderSide(
                    color: sectionColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2),
                  borderSide: BorderSide(color: sectionColor, width: 2),
                ),
                errorText: _errorMessage,
                errorStyle: GoogleFonts.dmSans(fontSize: 11),
                helperText: widget.helperText ?? 'Solo euro interi (senza centesimi)',
                helperStyle: GoogleFonts.dmSans(fontSize: 11),
              ),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmitted: (_) => _saveValue(),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkLight,
                      side: const BorderSide(color: AppColors.parchmentDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: Text(
                      'ANNULLA',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveValue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sectionColor,
                      foregroundColor: AppColors.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'SALVA',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
