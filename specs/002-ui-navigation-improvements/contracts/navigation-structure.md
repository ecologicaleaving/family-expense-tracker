# Navigation Structure Contract

**Feature**: 002-ui-navigation-improvements
**Date**: 2025-12-31
**Purpose**: Define navigation routes, tab structure, and state preservation interfaces

---

## Bottom Navigation Structure

### Tab Configuration

```dart
enum NavigationTab {
  dashboard,  // Index 0
  expenses,   // Index 1
  settings,   // Index 2
}

class NavigationTabConfig {
  final NavigationTab tab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  const NavigationTabConfig({
    required this.tab,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}
```

### Tab Definitions

| Index | Tab | Label | Icon | Screen | Route |
|-------|-----|-------|------|--------|-------|
| 0 | Dashboard | "Dashboard" | Icons.dashboard_outlined | DashboardScreen | /home (tab=0) |
| 1 | Expenses | "Spese" | Icons.receipt_long_outlined | ExpenseListScreen | /home (tab=1) |
| 2 | Settings | "Impostazioni" | Icons.settings_outlined | SettingsScreen | /home (tab=2) |

**Implementation:**

```dart
final List<NavigationTabConfig> navigationTabs = [
  NavigationTabConfig(
    tab: NavigationTab.dashboard,
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    screen: const DashboardScreen(),
  ),
  NavigationTabConfig(
    tab: NavigationTab.expenses,
    label: 'Spese',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    screen: const ExpenseListScreen(),
  ),
  NavigationTabConfig(
    tab: NavigationTab.settings,
    label: 'Impostazioni',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    screen: const SettingsScreen(),
  ),
];
```

---

## Route Structure

### Main Routes

```dart
final router = GoRouter(
  routes: [
    // ... existing routes (login, register, etc.)

    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(),
      routes: [
        // Settings sub-routes (accessible from Settings tab)
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'group',
          builder: (context, state) => const GroupDetailsScreen(),
        ),

        // Expense sub-routes (accessible from Dashboard or Expenses tab)
        GoRoute(
          path: 'expense/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ExpenseDetailScreen(expenseId: id);
          },
        ),

        // ... other existing routes
      ],
    ),
  ],
);
```

### Route Definitions

| Route | Description | Parent | Access From |
|-------|-------------|--------|-------------|
| `/home` | Main navigation screen (3 tabs) | Root | App entry after auth |
| `/home/profile` | User profile screen | /home | Settings tab |
| `/home/group` | Group details screen | /home | Settings tab |
| `/home/expense/:id` | Expense detail screen | /home | Dashboard recent expenses, Expenses list |
| `/home/add-expense` | Manual expense entry | /home | FAB button (existing) |
| `/home/scan-receipt` | Receipt scanner | /home | FAB button (existing) |
| `/home/upload-file` | File upload | /home | FAB button (existing) |

### Routing Behavior

**Bottom Navigation Persistence:**
- Bottom navigation bar is part of `MainNavigationScreen` scaffold
- All child routes (profile, group, expense detail) are pushed on top of main navigation
- Bottom nav remains visible during deep navigation (per spec requirement)
- Users can always tap bottom nav to return to main tabs

**Example Navigation Flow:**
```
User on Dashboard (Tab 0)
  → Tap recent expense
    → Navigate to /home/expense/123 (pushed on navigation stack)
      → Bottom nav still visible
        → User taps "Impostazioni" (Tab 2)
          → Navigate back to /home, switch to Settings tab
```

---

## Settings Screen Navigation

### Settings Menu Structure

```dart
class SettingsOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final VoidCallback onTap;

  const SettingsOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.onTap,
  });
}

final List<SettingsOption> settingsOptions = [
  SettingsOption(
    title: 'Profilo',
    subtitle: 'Gestisci il tuo profilo personale',
    icon: Icons.person,
    route: '/home/profile',
    onTap: () => context.push('/home/profile'),
  ),
  SettingsOption(
    title: 'Gruppo',
    subtitle: 'Gestisci il gruppo familiare',
    icon: Icons.group,
    route: '/home/group',
    onTap: () => context.push('/home/group'),
  ),
  // Future: Add more settings options
];
```

### Settings Screen Layout

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        children: [
          for (final option in settingsOptions)
            ListTile(
              leading: Icon(option.icon),
              title: Text(option.title),
              subtitle: Text(option.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: option.onTap,
            ),
        ],
      ),
    );
  }
}
```

---

## State Preservation Contract

### Interface Definition

```dart
abstract class TabStatePreserver {
  /// Save current tab state before switching tabs
  void saveTabState(int tabIndex, Map<String, dynamic> state);

  /// Restore tab state after switching back
  Map<String, dynamic>? restoreTabState(int tabIndex);

  /// Clear tab state (e.g., on logout)
  void clearAllTabStates();
}
```

### Implementation (using IndexedStack)

**Note:** IndexedStack automatically preserves widget state, so explicit state save/restore is not needed for basic use cases.

For advanced scenarios (e.g., persisting state across app restarts):

```dart
class NavigationStateManager implements TabStatePreserver {
  final Map<int, Map<String, dynamic>> _tabStates = {};

  @override
  void saveTabState(int tabIndex, Map<String, dynamic> state) {
    _tabStates[tabIndex] = Map.from(state);
  }

  @override
  Map<String, dynamic>? restoreTabState(int tabIndex) {
    return _tabStates[tabIndex];
  }

  @override
  void clearAllTabStates() {
    _tabStates.clear();
  }
}
```

### State to Preserve

| Tab | State Elements | Storage |
|-----|----------------|---------|
| Dashboard | - Selected period (week/month/year)<br>- Selected member filter<br>- Scroll position | Widget state + IndexedStack |
| Expenses | - Scroll position<br>- Search query (if added)<br>- Filter selections | Widget state + IndexedStack |
| Settings | - Scroll position | Widget state + IndexedStack |

**Persistence Strategy:**
- **Session-level**: IndexedStack keeps widgets mounted → automatic state preservation
- **App restart**: Not required by spec, state reset is acceptable
- **Background/foreground**: IndexedStack maintains state if app not killed

---

## Recent Expenses Data Contract

### Repository Interface

```dart
abstract class DashboardRepository {
  /// Fetch recent expenses for the current user's group
  ///
  /// [limit] - Maximum number of expenses to return (default: 10, max: 10)
  /// Returns list ordered by creation time (most recent first)
  /// Throws [ServerException] on network errors
  /// Throws [CacheException] on local storage errors
  Future<List<RecentExpenseEntity>> getRecentExpenses({int limit = 10});

  /// Refresh recent expenses (clears cache and refetches)
  Future<List<RecentExpenseEntity>> refreshRecentExpenses();
}
```

### Data Source Interface

```dart
abstract class DashboardRemoteDataSource {
  /// Fetch recent expenses from Supabase
  ///
  /// SQL Query:
  /// ```sql
  /// SELECT e.*, p.display_name as created_by_name
  /// FROM expenses e
  /// LEFT JOIN profiles p ON e.created_by = p.id
  /// WHERE e.group_id = :groupId AND e.deleted_at IS NULL
  /// ORDER BY e.created_at DESC
  /// LIMIT :limit
  /// ```
  ///
  /// [groupId] - Current user's group ID
  /// [limit] - Maximum results (default: 10)
  /// Returns List<Map<String, dynamic>> JSON
  Future<List<Map<String, dynamic>>> fetchRecentExpenses({
    required String groupId,
    int limit = 10,
  });
}
```

### Response Format

**Supabase JSON Response:**

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "amount": 50.00,
    "currency": "EUR",
    "description": "Pranzo al ristorante",
    "category": "Food",
    "date": "2025-12-31",
    "created_at": "2025-12-31T12:30:00Z",
    "created_by": "user-123",
    "created_by_name": "Mario Rossi"
  },
  // ... up to 10 items
]
```

**Transformed to RecentExpenseEntity:**

```dart
RecentExpenseEntity(
  id: '550e8400-e29b-41d4-a716-446655440000',
  amount: 50.00,
  currency: 'EUR',
  description: 'Pranzo al ristorante',
  category: 'Food',
  date: DateTime(2025, 12, 31),
  createdAt: DateTime.parse('2025-12-31T12:30:00Z'),
  createdBy: 'user-123',
  createdByName: 'Mario Rossi',
)
```

---

## Navigation Guard Contract

### Interface Definition

```dart
/// Mixin for screens that need to guard against unsaved changes
mixin UnsavedChangesGuard<T extends StatefulWidget> on State<T> {
  /// Override this to indicate if the screen has unsaved changes
  bool get hasUnsavedChanges;

  /// Show dialog to confirm discarding unsaved changes
  ///
  /// Returns true if user confirms discard, false otherwise
  Future<bool> confirmDiscardChanges(BuildContext context) async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UnsavedChangesDialog(),
    );

    return result ?? false;
  }

  /// Wrap widget with PopScope to guard navigation
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

### Dialog Contract

```dart
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

### Usage Example

```dart
class _ManualExpenseScreenState extends State<ManualExpenseScreen>
    with UnsavedChangesGuard {

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  Map<String, dynamic>? _initialValues;

  @override
  bool get hasUnsavedChanges {
    if (_initialValues == null) return false;

    final current = {
      'amount': _amountController.text,
      'description': _descriptionController.text,
    };

    return current != _initialValues;
  }

  @override
  Widget build(BuildContext context) {
    return buildWithNavigationGuard(
      context,
      Scaffold(
        appBar: AppBar(title: const Text('Nuova Spesa')),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _amountController, ...),
              TextFormField(controller: _descriptionController, ...),
              // ... more fields
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Error Handling Contract

### Deleted Expense Handling

**Interface:**

```dart
/// Exception thrown when attempting to access a deleted expense
class ExpenseNotFoundException implements Exception {
  final String expenseId;
  final String message;

  const ExpenseNotFoundException({
    required this.expenseId,
    this.message = 'Expense not found or has been deleted',
  });

  @override
  String toString() => 'ExpenseNotFoundException: $message (ID: $expenseId)';
}
```

**Error Flow:**

```dart
// In expense detail screen or recent expense tap handler
Future<void> _navigateToExpenseDetail(String expenseId) async {
  try {
    // Attempt to fetch expense details
    final expense = await ref.read(expenseProvider(expenseId).future);

    // Navigate if successful
    if (context.mounted) {
      context.push('/home/expense/$expenseId');
    }
  } on ExpenseNotFoundException catch (e) {
    // Show user-friendly message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questa spesa è stata eliminata da un altro membro'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Refresh recent expenses list to remove stale item
      ref.read(dashboardProvider.notifier).refreshRecentExpenses();
    }
  } catch (e) {
    // Generic error handling
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
    }
  }
}
```

---

## Performance Contracts

### Query Performance

**Recent Expenses Query:**
- **Target**: <500ms for 10 items
- **Method**: Indexed query on `created_at` column
- **Fallback**: If >500ms, reduce limit to 5 items

**Tab Switching:**
- **Target**: <300ms transition
- **Method**: IndexedStack pre-renders all tabs
- **Measurement**: Use Flutter DevTools Performance view

### Memory Constraints

**IndexedStack Memory Overhead:**
- **Acceptable**: <10MB for 3 tabs
- **Monitoring**: Profile with Flutter DevTools Memory view
- **Mitigation**: If >10MB, dispose heavy widgets when tab not visible

---

## Testing Contracts

### Navigation Tests

```dart
// Test bottom nav switching preserves state
testWidgets('switching tabs preserves scroll position', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to Expenses tab, scroll down
  await tester.tap(find.text('Spese'));
  await tester.pumpAndSettle();
  await tester.drag(find.byType(ListView), const Offset(0, -500));
  await tester.pumpAndSettle();

  final scrollPositionBefore = tester.getTopLeft(find.text('Expense 10')).dy;

  // Switch to Dashboard and back
  await tester.tap(find.text('Dashboard'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Spese'));
  await tester.pumpAndSettle();

  final scrollPositionAfter = tester.getTopLeft(find.text('Expense 10')).dy;

  expect(scrollPositionBefore, scrollPositionAfter);
});
```

### Recent Expenses Tests

```dart
// Test deleted expense handling
test('deleted expense throws ExpenseNotFoundException', () async {
  final repository = MockDashboardRepository();

  when(() => repository.getRecentExpenses())
      .thenThrow(ExpenseNotFoundException(expenseId: '123'));

  expect(
    () => repository.getRecentExpenses(),
    throwsA(isA<ExpenseNotFoundException>()),
  );
});
```

---

## Version Compatibility

**API Version:** No changes (uses existing Supabase tables/queries)
**Client Version:** 1.1.0 (incremental feature, backward compatible)

**Versioning Strategy:**
- Navigation changes are client-side only
- No server-side API changes required
- Old app versions continue to work with 4-tab navigation
- New app version uses 3-tab navigation
- Gradual rollout supported (no forced update needed)

---

**Contracts Complete**: All interfaces, routes, and behavioral contracts defined for implementation.
