import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/budget_actions_provider.dart';
import '../providers/budget_provider.dart';

import '../../../../app/app_theme.dart';
/// Minimal budget settings screen for setting total monthly budgets
/// All visualization is in the unified budget dashboard
class BudgetSettingsScreen extends ConsumerStatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  ConsumerState<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends ConsumerState<BudgetSettingsScreen> {
  final _groupBudgetController = TextEditingController();
  final _personalBudgetController = TextEditingController();
  bool _isSubmittingGroup = false;
  bool _isSubmittingPersonal = false;

  @override
  void dispose() {
    _groupBudgetController.dispose();
    _personalBudgetController.dispose();
    super.dispose();
  }

  Future<void> _submitGroupBudget() async {
    if (_groupBudgetController.text.isEmpty) return;

    setState(() => _isSubmittingGroup = true);

    try {
      // Parse input as cents (user enters euros, we store cents)
      final amount = CurrencyUtils.parseCentsFromInput(_groupBudgetController.text);
      if (amount == null) {
        throw const FormatException('Importo non valido');
      }

      final now = DateTime.now();
      final groupId = ref.read(currentGroupIdProvider);

      final result = await ref.read(budgetActionsProvider).setGroupBudget(
        groupId: groupId,
        amount: amount,
        month: now.month,
        year: now.year,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget gruppo aggiornato')),
          );
          _groupBudgetController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Errore aggiornamento budget')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingGroup = false);
      }
    }
  }

  Future<void> _submitPersonalBudget() async {
    if (_personalBudgetController.text.isEmpty) return;

    setState(() => _isSubmittingPersonal = true);

    try {
      // Parse input as cents (user enters euros, we store cents)
      final amount = CurrencyUtils.parseCentsFromInput(_personalBudgetController.text);
      if (amount == null) {
        throw const FormatException('Importo non valido');
      }

      final now = DateTime.now();
      final userId = ref.read(currentUserIdProvider);

      final result = await ref.read(budgetActionsProvider).setPersonalBudget(
        userId: userId,
        amount: amount,
        month: now.month,
        year: now.year,
      );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget personale aggiornato')),
          );
          _personalBudgetController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Errore aggiornamento budget')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingPersonal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    final userId = ref.watch(currentUserIdProvider);
    final budgetState = ref.watch(budgetProvider((groupId: groupId, userId: userId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni Budget'),
        backgroundColor: AppColors.terracotta,
        foregroundColor: AppColors.cream,
      ),
      backgroundColor: AppColors.parchment,
      body: budgetState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Header
                Text(
                  'Budget Mensili',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Visualizza la composizione del tuo budget mensile',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.inkLight,
                  ),
                ),
                const SizedBox(height: 32),

                // Budget Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(4),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.terracotta,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Budget
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: AppColors.terracotta, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Budget Totale',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '€ ${(budgetState.computedTotals.totalPersonalBudget + budgetState.computedTotals.totalGroupBudget) ~/ 100}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Personal Budget
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'PERSONALE',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '€ ${budgetState.computedTotals.totalPersonalBudget ~/ 100}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Group Budget
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.group, color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'GRUPPO',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '€ ${budgetState.computedTotals.totalGroupBudget ~/ 100}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Help text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inkLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.inkLight),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Il budget personale è la parte che puoi spendere liberamente. Il budget di gruppo è condiviso con gli altri membri.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppColors.inkLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

/// Minimal budget section component
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.title,
    required this.icon,
    required this.currentAmount,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final int? currentAmount;
  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current amount display (if set)
          if (currentAmount != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Attuale',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: AppColors.inkLight,
                  ),
                ),
                Text(
                  '€ ${currentAmount! ~/ 100}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Input field
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nuovo Importo',
              hintText: 'Es: 1500',
              prefixText: '€ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: AppColors.copper, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: AppColors.copper.withValues(alpha: 0.3), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
              helperText: 'Solo euro interi (senza centesimi)',
              helperStyle: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.inkLight,
              ),
            ),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: AppColors.cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'AGGIORNA',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
