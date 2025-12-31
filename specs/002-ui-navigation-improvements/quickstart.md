# Quickstart Guide: UI Navigation and Settings Reorganization

**Feature**: 002-ui-navigation-improvements
**Date**: 2025-12-31
**Audience**: Developers implementing this feature

---

## Overview

This guide helps you set up, develop, and test the UI navigation improvements. You'll learn how to:
1. Set up your development environment
2. Test the new 3-tab navigation structure
3. Verify state preservation across tabs
4. Test unsaved changes guards
5. Validate recent expenses functionality

---

## Prerequisites

- Flutter SDK 3.0.0+ installed
- Android Studio / VS Code with Flutter extensions
- Android emulator or iOS simulator running
- Supabase project configured (`.env` file with credentials)
- Git branch `002-ui-navigation-improvements` checked out

---

## Quick Setup (5 minutes)

### 1. Get Dependencies

```bash
cd /path/to/Fin
flutter pub get
```

### 2. Run Code Generation

The project uses Riverpod code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Start the App

```bash
flutter run
```

**Expected behavior after implementation:**
- App launches to login screen
- After login, main navigation screen shows 3 tabs: Dashboard, Spese, Impostazioni
- Bottom navigation persists across all screens

---

## Development Workflow

### Phase 1: Settings Menu Consolidation

**Goal**: Replace 4-tab navigation with 3-tab structure and create Settings screen.

#### 1.1 Update Main Navigation Screen

**File**: `lib/features/auth/presentation/screens/main_navigation_screen.dart`

**Changes:**
- Change `_screens` list from 4 items to 3 items
- Change `_destinations` list from 4 items to 3 items
- Remove `ProfileScreen()` and `GroupDetailsScreen()` from screens list
- Add `SettingsScreen()` as third tab

**Before:**
```dart
final List<Widget> _screens = const [
  DashboardScreen(),
  ExpenseListScreen(),
  GroupDetailsScreen(),
  ProfileScreen(),
];
```

**After:**
```dart
final List<Widget> _screens = const [
  DashboardScreen(),
  ExpenseListScreen(),
  SettingsScreen(),
];
```

#### 1.2 Create Settings Screen

**File**: `lib/features/auth/presentation/screens/settings_screen.dart`

**Template:**
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profilo'),
            subtitle: const Text('Gestisci il tuo profilo personale'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/home/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Gruppo'),
            subtitle: const Text('Gestisci il gruppo familiare'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/home/group'),
          ),
        ],
      ),
    );
  }
}
```

#### 1.3 Update Routes

**File**: `lib/app/routes.dart`

**Add sub-routes to `/home` route:**
```dart
GoRoute(
  path: '/home',
  builder: (context, state) => const MainNavigationScreen(),
  routes: [
    GoRoute(
      path: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: 'group',
      builder: (context, state) => const GroupDetailsScreen(),
    ),
    // ... existing routes
  ],
),
```

#### 1.4 Test Phase 1

**Manual testing:**
1. Launch app and log in
2. Verify 3 tabs in bottom navigation: Dashboard, Spese, Impostazioni
3. Tap "Impostazioni" tab
4. Verify Settings screen shows Profilo and Gruppo options
5. Tap "Profilo" → verify Profile screen opens
6. Tap back → verify returns to Settings screen
7. Tap "Gruppo" → verify Group screen opens
8. Tap bottom nav "Dashboard" → verify navigates to Dashboard

**Expected result**: ✅ Navigation works, bottom nav visible on all screens

---

### Phase 2: State Preservation

**Goal**: Preserve tab state when switching between tabs.

#### 2.1 Implement IndexedStack

**File**: `lib/features/auth/presentation/screens/main_navigation_screen.dart`

**Current implementation already uses IndexedStack** (check if this is true in your codebase):
```dart
body: IndexedStack(
  index: _currentIndex,
  children: _screens,
),
```

**If not using IndexedStack, replace body with:**
```dart
body: IndexedStack(
  index: _currentIndex,
  children: _screens,
),
```

#### 2.2 Test State Preservation

**Manual testing:**
1. Launch app, navigate to "Spese" tab
2. Scroll down the expense list
3. Note the scroll position (e.g., "Expense 20" visible at top)
4. Switch to "Dashboard" tab
5. Switch back to "Spese" tab
6. Verify scroll position is preserved (still showing "Expense 20" at top)

**Test with filters (if applicable):**
1. Apply filter on Dashboard (e.g., select "This Month")
2. Switch to "Spese" tab
3. Switch back to "Dashboard" tab
4. Verify filter is still "This Month"

**Expected result**: ✅ Scroll positions and filters preserved across tab switches

---

### Phase 3: Unsaved Changes Guard

**Goal**: Prevent accidental navigation away from forms with unsaved changes.

#### 3.1 Create UnsavedChangesDialog

**File**: `lib/shared/widgets/unsaved_changes_dialog.dart`

```dart
import 'package:flutter/material.dart';

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifiche non salvate'),
      content: const Text(
        'Hai modifiche non salvate. Vuoi uscire senza salvare?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Esci senza salvare'),
        ),
      ],
    );
  }
}
```

#### 3.2 Create NavigationGuard Mixin

**File**: `lib/shared/widgets/navigation_guard.dart`

```dart
import 'package:flutter/material.dart';
import 'unsaved_changes_dialog.dart';

mixin UnsavedChangesGuard<T extends StatefulWidget> on State<T> {
  bool get hasUnsavedChanges;

  Future<bool> confirmDiscardChanges(BuildContext context) async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UnsavedChangesDialog(),
    );

    return result ?? false;
  }

  Widget buildWithNavigationGuard(BuildContext context, Widget child) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldPop = await confirmDiscardChanges(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
```

#### 3.3 Apply to Manual Expense Screen

**File**: `lib/features/expenses/presentation/screens/manual_expense_screen.dart`

**Add mixin and implement:**
```dart
class _ManualExpenseScreenState extends ConsumerState<ManualExpenseScreen>
    with UnsavedChangesGuard {

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _initialValues;

  @override
  void initState() {
    super.initState();
    // Capture initial form values
    _initialValues = _getCurrentFormValues();
  }

  @override
  bool get hasUnsavedChanges {
    if (_initialValues == null) return false;
    return _getCurrentFormValues() != _initialValues;
  }

  Map<String, dynamic> _getCurrentFormValues() {
    return {
      'amount': _amountController.text,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'date': _selectedDate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return buildWithNavigationGuard(
      context,
      Scaffold(
        // ... existing scaffold content
      ),
    );
  }
}
```

#### 3.4 Test Unsaved Changes Guard

**Manual testing:**
1. Launch app, tap FAB to add new expense
2. Enter amount "50" and description "Test"
3. Press device back button
4. Verify dialog appears: "Modifiche non salvate. Vuoi uscire senza salvare?"
5. Tap "Annulla" → verify stays on expense screen
6. Press back button again
7. Tap "Esci senza salvare" → verify returns to previous screen

**Test with bottom navigation:**
1. Add new expense, enter data
2. Tap "Dashboard" bottom nav button
3. Verify unsaved changes dialog appears
4. Tap "Esci senza salvare" → verify navigates to Dashboard

**Expected result**: ✅ Dialog prevents accidental data loss

---

### Phase 4: Recent Expenses on Dashboard

**Goal**: Display 5-10 most recent expenses on Dashboard with tap navigation.

#### 4.1 Create Domain Entity

**File**: `lib/features/dashboard/domain/entities/recent_expense_entity.dart`

```dart
import 'package:equatable/equatable.dart';

class RecentExpenseEntity extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final String description;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final String createdBy;
  final String? createdByName;

  const RecentExpenseEntity({
    required this.id,
    required this.amount,
    required this.currency,
    required this.description,
    required this.category,
    required this.date,
    required this.createdAt,
    required this.createdBy,
    this.createdByName,
  });

  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        description,
        category,
        date,
        createdAt,
        createdBy,
        createdByName,
      ];
}
```

#### 4.2 Update DashboardProvider

**File**: `lib/features/dashboard/presentation/providers/dashboard_provider.dart`

**Add to state:**
```dart
class DashboardState {
  // ... existing fields
  final List<RecentExpenseEntity> recentExpenses;
  final bool recentExpensesLoading;

  DashboardState({
    // ... existing parameters
    this.recentExpenses = const [],
    this.recentExpensesLoading = false,
  });
}
```

**Add method to notifier:**
```dart
Future<void> loadRecentExpenses() async {
  state = state.copyWith(recentExpensesLoading: true);

  try {
    final expenses = await _repository.getRecentExpenses(limit: 10);
    state = state.copyWith(
      recentExpenses: expenses,
      recentExpensesLoading: false,
    );
  } catch (e) {
    state = state.copyWith(recentExpensesLoading: false);
    // Handle error
  }
}
```

#### 4.3 Create Recent Expenses Widget

**File**: `lib/features/dashboard/presentation/widgets/recent_expenses_list.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/recent_expense_entity.dart';

class RecentExpensesList extends StatelessWidget {
  final List<RecentExpenseEntity> expenses;
  final VoidCallback onSeeAll;

  const RecentExpensesList({
    super.key,
    required this.expenses,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Nessuna spesa recente',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spese recenti',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('Vedi tutte'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(_getCategoryIcon(expense.category)),
                ),
                title: Text(
                  expense.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _formatDate(expense.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  '€ ${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                onTap: () => context.push('/home/expense/${expense.id}'),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Oggi';
    if (difference.inDays == 1) return 'Ieri';
    if (difference.inDays < 7) return '${difference.inDays} giorni fa';

    return '${date.day}/${date.month}/${date.year}';
  }
}
```

#### 4.4 Add to Dashboard Screen

**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

**Add recent expenses section:**
```dart
child: Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // ... existing period selector

    // Recent expenses section (NEW)
    RecentExpensesList(
      expenses: dashboardState.recentExpenses,
      onSeeAll: () {
        // Switch to Expenses tab
        _tabController.animateTo(1);
      },
    ),
    const SizedBox(height: 16),

    // ... existing summary card, charts, etc.
  ],
),
```

#### 4.5 Test Recent Expenses

**Manual testing:**
1. Launch app, navigate to Dashboard
2. Verify "Spese recenti" section appears
3. If no expenses exist, verify shows "Nessuna spesa recente"
4. Create a new expense via FAB
5. Return to Dashboard
6. Verify new expense appears in recent expenses list
7. Verify list shows max 10 items (if more than 10 expenses exist)
8. Tap an expense in the list
9. Verify navigates to expense detail screen
10. Tap "Vedi tutte" button
11. Verify switches to Expenses tab

**Test text truncation:**
1. Create expense with very long description: "Very long description that should be truncated with ellipsis to fit in one line"
2. Verify description shows ellipsis (...) in recent expenses list
3. Tap expense to view details
4. Verify full description shown in detail screen

**Expected result**: ✅ Recent expenses display correctly with navigation

---

## Testing Checklist

### Unit Tests

- [ ] RecentExpenseModel.fromJson() parses Supabase JSON correctly
- [ ] RecentExpenseModel.toEntity() converts to domain entity
- [ ] DashboardRepository.getRecentExpenses() returns correct data
- [ ] UnsavedChangesGuard mixin detects dirty form state

### Widget Tests

- [ ] SettingsScreen renders Profilo and Gruppo options
- [ ] RecentExpensesList renders empty state when no expenses
- [ ] RecentExpensesList renders expense items with truncated text
- [ ] UnsavedChangesDialog shows correct buttons and text

### Integration Tests

- [ ] Switching tabs preserves scroll position
- [ ] Switching tabs preserves filter selections
- [ ] Unsaved changes dialog appears when navigating away from dirty form
- [ ] Recent expense tap navigates to detail screen
- [ ] "Vedi tutte" button switches to Expenses tab
- [ ] Bottom navigation visible on all screens (Dashboard, Settings, Profile, Group)

### Manual Smoke Tests

- [ ] App launches and shows login screen
- [ ] After login, 3-tab bottom navigation visible
- [ ] Tapping each tab shows correct screen
- [ ] Settings screen shows Profile and Group options
- [ ] Profile screen accessible from Settings
- [ ] Group screen accessible from Settings
- [ ] Recent expenses load on Dashboard
- [ ] Can navigate to expense detail from recent expenses
- [ ] Unsaved changes dialog prevents accidental data loss

---

## Common Issues & Troubleshooting

### Issue: Bottom Navigation Not Showing on Deep Screens

**Symptom**: When navigating to Profile or Group from Settings, bottom nav disappears.

**Cause**: Profile/Group screens may have their own Scaffold that hides parent navigation.

**Solution**: Ensure child routes don't use Scaffold, or use nested navigation with persistent bottom nav.

### Issue: Tab State Not Preserved

**Symptom**: Switching tabs causes screens to reload from scratch.

**Cause**: Not using IndexedStack or widgets being disposed.

**Solution**: Verify `body: IndexedStack(...)` in main_navigation_screen.dart.

### Issue: Unsaved Changes Dialog Not Appearing

**Symptom**: Can navigate away from form without seeing dialog.

**Cause**: `hasUnsavedChanges` getter returning false incorrectly.

**Solution**: Add debug print in `hasUnsavedChanges` to verify form state comparison.

```dart
@override
bool get hasUnsavedChanges {
  final current = _getCurrentFormValues();
  print('Initial: $_initialValues');
  print('Current: $current');
  print('Has changes: ${current != _initialValues}');
  return current != _initialValues;
}
```

### Issue: Recent Expenses Not Loading

**Symptom**: Dashboard shows loading forever or "Nessuna spesa recente" even when expenses exist.

**Cause**: Supabase query failing or RLS policy blocking access.

**Solution**: Check Supabase logs, verify RLS policies allow reading expenses for current group.

```sql
-- Test query manually in Supabase SQL editor
SELECT e.*, p.display_name as created_by_name
FROM expenses e
LEFT JOIN profiles p ON e.created_by = p.id
WHERE e.group_id = 'your-group-id' AND e.deleted_at IS NULL
ORDER BY e.created_at DESC
LIMIT 10;
```

### Issue: Text Not Truncating with Ellipsis

**Symptom**: Long descriptions overflow instead of showing "..."

**Cause**: Missing `maxLines` or `overflow` properties on Text widget.

**Solution**: Ensure Text widget has both properties:

```dart
Text(
  expense.description,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

---

## Performance Profiling

### Measure Navigation Performance

**Using Flutter DevTools:**

1. Launch app with Flutter DevTools open
2. Go to Performance tab
3. Record a trace
4. Switch between tabs multiple times
5. Stop recording
6. Verify frame rendering time <16ms (60fps)
7. Verify no dropped frames during transitions

**Expected benchmarks:**
- Tab switch: <100ms
- Recent expenses load: <500ms
- Unsaved changes dialog: <50ms

### Memory Profiling

**Check IndexedStack memory usage:**

1. Launch app with DevTools Memory view
2. Navigate to all 3 tabs
3. Take heap snapshot
4. Verify total memory <50MB (reasonable for 3 tabs with data)
5. Switch tabs and verify no memory leaks (memory shouldn't keep growing)

---

## Deployment Checklist

Before merging to main:

- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] All integration tests pass
- [ ] Manual testing on Android device complete
- [ ] Manual testing on iOS device complete
- [ ] Performance benchmarks meet targets (<300ms navigation, <1s data load)
- [ ] Memory usage acceptable (<10MB overhead for IndexedStack)
- [ ] Code review completed
- [ ] Documentation updated (if public API changes)
- [ ] Changelog entry added

---

## Quick Reference Commands

```bash
# Get dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run specific test file
flutter test test/features/dashboard/presentation/widgets/recent_expenses_list_test.dart

# Run with code coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Launch app
flutter run

# Launch app in profile mode (for performance testing)
flutter run --profile

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

---

## Next Steps

After implementing this feature:

1. Run `/speckit.tasks` to generate detailed implementation task list
2. Execute tasks in priority order (P1 → P2 → P3)
3. Test each phase before moving to next
4. Update this quickstart guide if you discover better patterns

---

**Quickstart Complete**: You're ready to implement the UI navigation improvements! 🚀
