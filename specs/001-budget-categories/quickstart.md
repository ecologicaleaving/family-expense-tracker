# Quick Start Guide: Budget Management & Category Customization

**Feature**: Budget Management and Category Customization
**Branch**: `001-budget-categories`
**Date**: 2025-12-31

## Overview

This guide helps developers quickly understand and implement the budget management feature. It covers setup, key concepts, and common implementation patterns.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Setup Steps](#setup-steps)
4. [First Budget Creation](#first-budget-creation)
5. [Category Management](#category-management)
6. [Expense Classification](#expense-classification)
7. [Budget Indicators](#budget-indicators)
8. [Testing Your Implementation](#testing-your-implementation)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Knowledge
- Flutter 3.0+ / Dart 3.0+
- Riverpod 2.4.0 state management
- Supabase basics (RLS, Realtime, PostgreSQL)
- Clean architecture pattern

### Environment Setup
```bash
# Verify Flutter version
flutter --version
# Expected: Flutter 3.0.0 or higher

# Verify dependencies in pubspec.yaml
grep -A 3 "supabase_flutter:" pubspec.yaml
# Expected: supabase_flutter: ^2.0.0

# Run database migrations
supabase db push
```

### Key Documents
- [spec.md](./spec.md) - Feature requirements
- [data-model.md](./data-model.md) - Database schema
- [contracts/](./contracts/) - API definitions
- [research.md](./research.md) - Technical decisions

---

## Architecture Overview

### Feature Structure

```
lib/features/
├── budgets/              # Budget management feature
│   ├── data/
│   │   ├── datasources/  # Supabase integration
│   │   ├── models/       # Data models (JSON ↔ Entity)
│   │   └── repositories/ # Repository implementations
│   ├── domain/
│   │   ├── entities/     # Business entities
│   │   └── repositories/ # Repository interfaces
│   └── presentation/
│       ├── providers/    # Riverpod state management
│       ├── screens/      # Settings, history screens
│       └── widgets/      # Progress bars, indicators
│
├── categories/           # Category management
│   ├── data/
│   ├── domain/
│   └── presentation/
│
└── expenses/            # MODIFIED: Add classification
    ├── data/
    │   └── models/
    │       └── expense_model.dart  # Add isGroupExpense field
    └── presentation/
        └── widgets/
            └── expense_type_toggle.dart  # NEW
```

### Data Flow

```
User Action (Add Expense)
    │
    ▼
┌─────────────────────────────┐
│ ExpenseFormProvider         │
│ - Validate input            │
│ - Create ExpenseEntity      │
└──────────┬──────────────────┘
           │
           ├─────────────────────────┐
           │                         │
           ▼                         ▼
┌──────────────────────┐  ┌──────────────────────┐
│ BudgetProvider       │  │ ExpenseRepository    │
│ - Optimistic update  │  │ - Save to Supabase   │
│ - Recalculate stats  │  │ - Return result      │
└──────────┬───────────┘  └──────────┬───────────┘
           │                         │
           │                         ▼
           │              ┌──────────────────────┐
           │              │ Supabase Realtime    │
           │              │ - Notify other users │
           │              └──────────┬───────────┘
           │                         │
           ▼                         ▼
┌─────────────────────────────────────────┐
│ UI Updates                              │
│ - Budget progress bar                   │
│ - Expense list                          │
│ - Warning indicators                    │
└─────────────────────────────────────────┘
```

---

## Setup Steps

### Step 1: Database Migrations

Run the migration scripts in order:

```bash
# Navigate to project root
cd /path/to/fin

# Apply Phase 1 migrations (nullable columns)
supabase db push

# Verify tables created
supabase db inspect
# Expected: group_budgets, personal_budgets, expense_categories tables
```

**What This Does:**
- Creates `group_budgets` table with monthly budgets
- Creates `personal_budgets` table for individual budgets
- Creates `expense_categories` table with default categories
- Adds `is_group_expense` column to expenses (nullable, default true)
- Sets up RLS policies for privacy

### Step 2: Add New Dependencies

```yaml
# pubspec.yaml
dependencies:
  # ... existing dependencies

  # Timezone support (for budget calculations)
  flutter_timezone: ^2.1.0
  timezone: ^0.9.2

  # Modal bottom sheets (for category deletion UX)
  wolt_modal_sheet: ^0.6.0

# Then run:
# flutter pub get
```

### Step 3: Initialize Timezone Support

```dart
// lib/main.dart
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezones BEFORE Supabase
  tz.initializeTimeZones();
  final deviceTimezone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(deviceTimezone));

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Step 4: Create Core Entities

```dart
// lib/features/budgets/domain/entities/group_budget_entity.dart
class GroupBudgetEntity extends Equatable {
  const GroupBudgetEntity({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String groupId;
  final int amount;          // Whole euros (no cents)
  final int month;           // 1-12
  final int year;            // >= 2000
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id, groupId, amount, month, year, createdBy, createdAt, updatedAt,
  ];
}
```

---

## First Budget Creation

### Scenario: Group Administrator Sets Monthly Budget

#### Step 1: Create Budget Remote Data Source

```dart
// lib/features/budgets/data/datasources/budget_remote_datasource.dart
abstract class BudgetRemoteDataSource {
  Future<GroupBudgetModel> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  });

  Future<GroupBudgetModel?> getGroupBudget({
    required String groupId,
    required int month,
    required int year,
  });
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  const BudgetRemoteDataSourceImpl(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<GroupBudgetModel> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  }) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const AppAuthException('Not authenticated', 'not_authenticated');
      }

      // Upsert budget (insert or update if exists)
      final response = await _supabaseClient
          .from('group_budgets')
          .upsert({
            'group_id': groupId,
            'amount': amount,
            'month': month,
            'year': year,
            'created_by': userId,
          })
          .select()
          .single();

      return GroupBudgetModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    }
  }

  @override
  Future<GroupBudgetModel?> getGroupBudget({
    required String groupId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _supabaseClient
          .from('group_budgets')
          .select()
          .eq('group_id', groupId)
          .eq('year', year)
          .eq('month', month)
          .maybeSingle();

      if (response == null) return null;

      return GroupBudgetModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, e.code);
    }
  }
}
```

#### Step 2: Create Budget Settings Screen

```dart
// lib/features/budgets/presentation/screens/budget_settings_screen.dart
class BudgetSettingsScreen extends ConsumerWidget {
  const BudgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupBudget = ref.watch(groupBudgetProvider);
    final personalBudget = ref.watch(personalBudgetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni Budget')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Group Budget Card (Admin Only)
          if (ref.watch(currentUserProvider).isGroupAdmin)
            _buildGroupBudgetCard(context, ref, groupBudget),

          const SizedBox(height: 24),

          // Personal Budget Card
          _buildPersonalBudgetCard(context, ref, personalBudget),
        ],
      ),
    );
  }

  Widget _buildGroupBudgetCard(
    BuildContext context,
    WidgetRef ref,
    GroupBudgetEntity? budget,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Budget del Gruppo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (budget == null)
              Text(
                'Nessun budget impostato per questo mese',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                '€${budget.amount}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: () => _showSetBudgetDialog(context, ref, isGroup: true),
              icon: const Icon(Icons.edit),
              label: Text(budget == null ? 'Imposta Budget' : 'Modifica Budget'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isGroup,
  }) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGroup ? 'Imposta Budget Gruppo' : 'Imposta Budget Personale'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Importo (€)',
            helperText: 'Budget mensile in euro (senza centesimi)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount == null || amount < 0) {
                // Show validation error
                return;
              }

              final now = DateTime.now();

              if (isGroup) {
                await ref.read(budgetActionsProvider).setGroupBudget(
                  amount: amount,
                  month: now.month,
                  year: now.year,
                );
              } else {
                await ref.read(budgetActionsProvider).setPersonalBudget(
                  amount: amount,
                  month: now.month,
                  year: now.year,
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
```

---

## Category Management

### Scenario: Admin Creates Custom Category

#### Step 1: Category Management Screen

```dart
// lib/features/categories/presentation/screens/category_management_screen.dart
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestisci Categorie'),
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryListItem(
              category: category,
              onEdit: category.isDefault
                  ? null
                  : () => _showEditCategoryDialog(context, ref, category),
              onDelete: category.isDefault
                  ? null
                  : () => _showDeleteCategoryDialog(context, ref, category),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Errore: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuova Categoria'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome categoria',
            helperText: 'Massimo 50 caratteri',
          ),
          maxLength: 50,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              await ref.read(categoryActionsProvider).createCategory(name: name);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Crea'),
          ),
        ],
      ),
    );
  }
}
```

#### Step 2: Category Deletion with Reassignment

**IMPORTANT**: Use the multi-page modal pattern from [research.md](./research.md#3-category-deletion-with-expense-reassignment).

```dart
// lib/features/categories/presentation/widgets/category_delete_flow.dart
class CategoryDeletionFlow {
  static void show({
    required BuildContext context,
    required ExpenseCategoryEntity category,
    required int affectedExpenseCount,
    required VoidCallback onDeleted,
  }) {
    WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        // Page 1: Impact Preview
        _buildImpactPreviewPage(
          context: context,
          categoryName: category.name,
          affectedCount: affectedExpenseCount,
        ),

        // Page 2: Quick Reassignment
        _buildQuickReassignmentPage(
          context: context,
          category: category,
          affectedCount: affectedExpenseCount,
          onDeleted: onDeleted,
        ),
      ],
    );
  }

  // Implementation in research.md Section 3
}
```

---

## Expense Classification

### Scenario: User Adds Personal Expense

#### Step 1: Update Expense Model

```dart
// lib/features/expenses/data/models/expense_model.dart

// ADD to existing ExpenseModel class:

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    // ... existing fields
    super.isGroupExpense = true,  // ← ADD with default
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      // ... existing fields
      // ← ADD with null-coalescing for backward compatibility
      isGroupExpense: json['is_group_expense'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ... existing fields
      'is_group_expense': isGroupExpense,  // ← ADD
    };
  }
}
```

#### Step 2: Expense Type Toggle Widget

```dart
// lib/features/expenses/presentation/widgets/expense_type_toggle.dart
class ExpenseTypeToggle extends StatelessWidget {
  const ExpenseTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value; // true = group, false = personal
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: true,
          label: Text('Gruppo'),
          icon: Icon(Icons.groups),
        ),
        ButtonSegment<bool>(
          value: false,
          label: Text('Personale'),
          icon: Icon(Icons.person),
        ),
      ],
      selected: {value},
      onSelectionChanged: (Set<bool> newSelection) {
        onChanged(newSelection.first);
      },
    );
  }
}
```

#### Step 3: Integrate in Expense Form

```dart
// lib/features/expenses/presentation/screens/manual_expense_screen.dart

// ADD to ManualExpenseScreen state:
class _ManualExpenseScreenState extends State<ManualExpenseScreen> {
  // ... existing fields
  bool _isGroupExpense = true;  // ← ADD

  @override
  Widget build(BuildContext context) {
    return Form(
      child: ListView(
        children: [
          // ... existing fields (amount, category, etc.)

          // ← ADD: Expense Type Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo di spesa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ExpenseTypeToggle(
                  value: _isGroupExpense,
                  onChanged: (value) {
                    setState(() => _isGroupExpense = value);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _isGroupExpense
                      ? 'Visibile a tutti i membri del gruppo'
                      : 'Visibile solo a te',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ... submit button
        ],
      ),
    );
  }

  Future<void> _submitExpense() async {
    // ... validation

    await ref.read(expenseFormProvider.notifier).createExpense(
      amount: _amount,
      date: _selectedDate,
      category: _selectedCategory,
      isGroupExpense: _isGroupExpense,  // ← INCLUDE
      // ... other fields
    );
  }
}
```

---

## Budget Indicators

### Scenario: Show Budget Progress on Dashboard

#### Step 1: Budget Progress Bar Widget

```dart
// lib/features/budgets/presentation/widgets/budget_progress_bar.dart
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.stats,
    this.height = 12,
  });

  final BudgetStats stats;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = stats.percentageUsed.clamp(0.0, 100.0);

    Color progressColor;
    if (stats.isOverBudget) {
      progressColor = theme.colorScheme.error;
    } else if (stats.isNearLimit) {
      progressColor = theme.colorScheme.tertiary; // Warning amber
    } else {
      progressColor = theme.colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€${stats.spentAmount} di €${stats.budgetAmount}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: height,
          ),
        ),
        if (stats.isOptimistic)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Sincronizzazione...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
```

#### Step 2: Warning Indicator

```dart
// lib/features/budgets/presentation/widgets/budget_warning_indicator.dart
class BudgetWarningIndicator extends StatelessWidget {
  const BudgetWarningIndicator({
    super.key,
    required this.stats,
  });

  final BudgetStats stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.isNearLimit && !stats.isOverBudget) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final (icon, color, message) = stats.isOverBudget
        ? (Icons.error_outline, theme.colorScheme.error, 'Budget superato!')
        : (Icons.warning_amber_rounded, theme.colorScheme.tertiary, 'Vicino al limite (80%)');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### Step 3: Integrate in Dashboard

```dart
// lib/features/dashboard/presentation/screens/dashboard_screen.dart

@override
Widget build(BuildContext context, WidgetRef ref) {
  final budgetState = ref.watch(budgetProvider);

  return Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Group Budget Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget del Gruppo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                if (budgetState.groupBudget.budgetAmount > 0)
                  BudgetProgressBar(stats: budgetState.groupBudget)
                else
                  const Text('Nessun budget impostato'),

                const SizedBox(height: 12),
                BudgetWarningIndicator(stats: budgetState.groupBudget),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Personal Budget Card (similar structure)
        // ...
      ],
    ),
  );
}
```

---

## Testing Your Implementation

### Unit Tests

```dart
// test/features/budgets/data/repositories/budget_repository_test.dart
void main() {
  group('BudgetRepository', () {
    late BudgetRepository repository;
    late MockBudgetRemoteDataSource mockRemoteDataSource;

    setUp(() {
      mockRemoteDataSource = MockBudgetRemoteDataSource();
      repository = BudgetRepositoryImpl(mockRemoteDataSource);
    });

    test('setGroupBudget returns budget on success', () async {
      // Arrange
      final budget = GroupBudgetModel(
        id: 'test-id',
        groupId: 'group-1',
        amount: 1000,
        month: 12,
        year: 2025,
        createdBy: 'user-1',
      );

      when(() => mockRemoteDataSource.setGroupBudget(
        groupId: any(named: 'groupId'),
        amount: any(named: 'amount'),
        month: any(named: 'month'),
        year: any(named: 'year'),
      )).thenAnswer((_) async => budget);

      // Act
      final result = await repository.setGroupBudget(
        groupId: 'group-1',
        amount: 1000,
        month: 12,
        year: 2025,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (budgetEntity) => expect(budgetEntity.amount, 1000),
      );
    });

    test('getBudgetStats calculates percentage correctly', () async {
      // Test budget calculation logic
      // ...
    });
  });
}
```

### Integration Tests

```dart
// test/integration/budget_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Admin can set group budget and see it on dashboard', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to budget settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Tap "Imposta Budget" button
    await tester.tap(find.text('Imposta Budget'));
    await tester.pumpAndSettle();

    // Enter budget amount
    await tester.enterText(find.byType(TextField), '1000');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // Navigate back to dashboard
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify budget appears on dashboard
    expect(find.text('€1000'), findsOneWidget);
    expect(find.byType(BudgetProgressBar), findsOneWidget);
  });

  testWidgets('User can add personal expense and budget updates', (tester) async {
    // Test optimistic update <2s requirement
    final startTime = DateTime.now();

    // Add expense
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount_field')), '50');
    await tester.tap(find.byKey(const Key('personal_expense_toggle')));
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // Verify budget updated
    expect(find.textContaining('€50'), findsOneWidget);

    final endTime = DateTime.now();
    final latency = endTime.difference(startTime);

    expect(latency.inMilliseconds, lessThan(2000));
  });
}
```

### RLS Testing (Supabase SQL Editor)

```sql
-- Test personal expense privacy
BEGIN;

-- Create personal expense as User A
SET LOCAL request.jwt.claims TO '{"sub": "user-a-uuid"}';
INSERT INTO expenses (id, group_id, created_by, amount, category, is_group_expense, date)
VALUES (gen_random_uuid(), 'group-1', 'user-a-uuid', 50, 'food', false, CURRENT_DATE);

-- Try to view as User B (should fail)
SET LOCAL request.jwt.claims TO '{"sub": "user-b-uuid"}';
SELECT COUNT(*) FROM expenses WHERE is_group_expense = false;
-- Expected: 0 (can only see own personal expenses)

ROLLBACK;
```

---

## Troubleshooting

### Common Issues

#### 1. "NULL value in column 'is_group_expense' violates not-null constraint"

**Cause**: Phase 2 migration deployed too early

**Solution**:
```sql
-- Rollback Phase 2
ALTER TABLE expenses ALTER COLUMN is_group_expense DROP NOT NULL;

-- Wait for all users to update to new app version
-- Then re-deploy Phase 2
```

#### 2. Budget stats not updating after expense added

**Cause**: Realtime subscription not active or budget provider not watching expenses

**Solution**:
```dart
// Verify Supabase realtime enabled
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';

// Check Flutter provider subscription
final budgetState = ref.watch(budgetProvider);
print('Pending syncs: ${budgetState.pendingSyncExpenseIds.length}');
```

#### 3. Category deletion fails with "expenses still exist"

**Cause**: Batch reassignment not completing

**Solution**:
```dart
// Check PostgreSQL function exists
SELECT routine_name
FROM information_schema.routines
WHERE routine_name = 'batch_update_expense_category';

// Verify admin permissions
SELECT is_group_admin FROM profiles WHERE id = auth.uid();
```

#### 4. Timezone showing wrong month expenses

**Cause**: Timezone not set in user profile

**Solution**:
```dart
// Detect and save timezone on app start
final timezone = await FlutterTimezone.getLocalTimezone();
await supabase
    .from('profiles')
    .update({'timezone': timezone})
    .eq('id', userId);
```

#### 5. Performance: Budget queries taking >2 seconds

**Cause**: Missing indexes

**Solution**:
```sql
-- Verify indexes exist
SELECT indexname FROM pg_indexes WHERE tablename = 'expenses';

-- Expected indexes:
-- idx_expenses_group_date
-- idx_expenses_is_group_expense
-- idx_expenses_created_by_is_group
```

---

## Next Steps

After completing this quick start:

1. ✅ Review [spec.md](./spec.md) for detailed requirements
2. ✅ Study [data-model.md](./data-model.md) for schema details
3. ✅ Check [contracts/](./contracts/) for full API definitions
4. ✅ Read [research.md](./research.md) for technical decisions
5. ⏳ Implement features following task list in `tasks.md` (after `/speckit.tasks`)

---

## Resources

### Internal Documentation
- [spec.md](./spec.md) - Feature specification
- [plan.md](./plan.md) - Implementation plan
- [data-model.md](./data-model.md) - Database schema
- [research.md](./research.md) - Technical research
- [contracts/budget-api.md](./contracts/budget-api.md) - Budget API
- [contracts/category-api.md](./contracts/category-api.md) - Category API
- [contracts/expense-api.md](./contracts/expense-api.md) - Expense extensions

### External Resources
- [Supabase Docs: RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Riverpod Docs](https://riverpod.dev/docs/introduction/getting_started)
- [Flutter Timezone Package](https://pub.dev/packages/flutter_timezone)
- [Wolt Modal Sheet](https://pub.dev/packages/wolt_modal_sheet)

---

**Version**: 1.0.0
**Last Updated**: 2025-12-31
**Status**: Phase 1 Complete - Ready for Implementation
