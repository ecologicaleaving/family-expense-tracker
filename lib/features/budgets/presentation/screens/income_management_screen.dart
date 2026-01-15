import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/income_sources_provider.dart';
import '../providers/budget_summary_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/income_source_list_item.dart';
import '../../domain/entities/income_source_entity.dart';
import 'package:uuid/uuid.dart';
import '../widgets/income_type_selector.dart';
import '../../../../shared/widgets/currency_input_field.dart';
import '../../domain/usecases/add_income_source_usecase.dart';
import '../../domain/usecases/update_income_source_usecase.dart';
import '../../domain/usecases/delete_income_source_usecase.dart';
import '../providers/budget_repository_provider.dart';
import '../../../../core/errors/failures.dart';

/// Screen for managing multiple income sources
///
/// Implements User Story 2: Multiple Income Source Management
/// - View all income sources in a list
/// - Add new income sources
/// - Edit existing income sources
/// - Delete income sources
/// - See total income summary
///
/// Features:
/// - Real-time total income calculation
/// - Swipe-to-delete with confirmation
/// - Edit dialog for quick updates
/// - Empty state guidance
class IncomeManagementScreen extends ConsumerStatefulWidget {
  const IncomeManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IncomeManagementScreen> createState() => _IncomeManagementScreenState();
}

class _IncomeManagementScreenState extends ConsumerState<IncomeManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Force sync from Supabase to local DB on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        print('🔄 [IncomeManagementScreen] Forcing sync from Supabase for userId: $userId');
        ref.read(budgetRepositoryProvider).getIncomeSources(userId).then((result) {
          result.fold(
            (failure) => print('❌ [IncomeManagementScreen] Sync failed: $failure'),
            (sources) => print('✅ [IncomeManagementScreen] Synced ${sources.length} income sources'),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeSourcesAsync = ref.watch(incomeSourcesProvider);
    final totalIncomeAsync = ref.watch(totalIncomeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Sources'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Total Income Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: theme.primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Total Monthly Income',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                totalIncomeAsync.when(
                  data: (total) => Text(
                    total.toCurrencyString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading total'),
                ),
              ],
            ),
          ),

          // Income Sources List
          Expanded(
            child: incomeSourcesAsync.when(
              data: (sources) {
                if (sources.isEmpty) {
                  return _buildEmptyState(context, ref);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sources.length,
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    return SwipeableIncomeSourceListItem(
                      incomeSource: source,
                      onEdit: () => _showEditDialog(context, ref, source),
                      onDelete: () => _deleteIncomeSource(context, ref, source),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading income sources'),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              'No Income Sources',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first income source to start tracking your budget',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Income Source'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    // Capture ScaffoldMessenger before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => _IncomeSourceDialog(
        title: 'Add Income Source',
        onSave: (type, customName, amount) async {
          final userId = ref.read(authProvider).user?.id;
          if (userId == null) return;

          final newSource = IncomeSourceEntity(
            id: const Uuid().v4(),
            userId: userId,
            type: type,
            customTypeName: customName,
            amount: amount,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final repository = ref.read(budgetRepositoryProvider);
          final useCase = AddIncomeSourceUseCase(repository);

          final result = await useCase(newSource);

          result.fold(
            (failure) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            (source) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Income source added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    IncomeSourceEntity source,
  ) async {
    // Capture ScaffoldMessenger before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => _IncomeSourceDialog(
        title: 'Edit Income Source',
        initialType: source.type,
        initialCustomName: source.customTypeName,
        initialAmount: source.amount,
        onSave: (type, customName, amount) async {
          final updatedSource = IncomeSourceEntity(
            id: source.id,
            userId: source.userId,
            type: type,
            customTypeName: customName,
            amount: amount,
            createdAt: source.createdAt,
            updatedAt: DateTime.now(),
          );

          final repository = ref.read(budgetRepositoryProvider);
          final useCase = UpdateIncomeSourceUseCase(repository);

          final result = await useCase(updatedSource);

          result.fold(
            (failure) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            (source) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Income source updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteIncomeSource(
    BuildContext context,
    WidgetRef ref,
    IncomeSourceEntity source,
  ) async {
    final repository = ref.read(budgetRepositoryProvider);
    final useCase = DeleteIncomeSourceUseCase(repository);

    final result = await useCase(source.id);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income source deleted'),
          ),
        );
      },
    );
  }
}

/// Dialog for adding/editing income sources
class _IncomeSourceDialog extends StatefulWidget {
  final String title;
  final IncomeType? initialType;
  final String? initialCustomName;
  final int? initialAmount;
  final Future<void> Function(IncomeType, String?, int) onSave;

  const _IncomeSourceDialog({
    required this.title,
    this.initialType,
    this.initialCustomName,
    this.initialAmount,
    required this.onSave,
  });

  @override
  State<_IncomeSourceDialog> createState() => _IncomeSourceDialogState();
}

class _IncomeSourceDialogState extends State<_IncomeSourceDialog> {
  late IncomeType? _selectedType;
  late String? _customName;
  late int? _amount;
  late int? _initialAmountForField; // Separate initial value for CurrencyInputField

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _customName = widget.initialCustomName;
    _amount = widget.initialAmount;
    _initialAmountForField = widget.initialAmount; // Set once and never change
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IncomeTypeSelector(
              selectedType: _selectedType,
              customTypeName: _customName,
              onTypeChanged: (type) {
                debugPrint('Type changed to: $type');
                setState(() {
                  _selectedType = type as IncomeType?;
                  // Clear custom name when switching to non-custom type
                  if (_selectedType != IncomeType.custom) {
                    debugPrint('Type is not custom, clearing _customName');
                    _customName = null;
                  }
                  debugPrint('After type change - _customName: $_customName');
                });
              },
              onCustomTypeNameChanged: (name) {
                debugPrint('Custom name changed: "$name" (isEmpty: ${name.isEmpty})');
                setState(() {
                  // Convert empty string to null for proper validation
                  _customName = (name.isEmpty) ? null : name;
                  debugPrint('_customName set to: $_customName (isNull: ${_customName == null})');
                });
              },
            ),
            const SizedBox(height: 16),
            CurrencyInputField(
              initialValue: _initialAmountForField, // Use separate initial value
              label: 'Monthly Amount',
              onChanged: (cents) {
                // Update value and rebuild to enable/disable Save button
                setState(() {
                  _amount = cents;
                });
              },
              isRequired: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  bool _canSave() {
    if (_selectedType == null) return false;
    if (_amount == null || _amount! <= 0) return false;
    if (_selectedType == IncomeType.custom) {
      if (_customName == null || _customName!.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (_canSave()) {
      // Force customName to null if type is not custom
      final customNameToSave = _selectedType == IncomeType.custom ? _customName : null;

      // Debug log
      debugPrint('===== SAVING INCOME SOURCE =====');
      debugPrint('Type: $_selectedType');
      debugPrint('Custom Name: $customNameToSave (isNull: ${customNameToSave == null})');
      debugPrint('Amount: $_amount');

      // Wait for save operation to complete before closing dialog
      await widget.onSave(_selectedType!, customNameToSave, _amount!);

      // Only close dialog if still mounted
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
