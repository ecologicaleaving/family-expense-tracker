# Research: UI Navigation and Settings Reorganization

**Feature**: 002-ui-navigation-improvements
**Date**: 2025-12-31
**Purpose**: Research technical approaches for navigation reorganization, state preservation, and recent expenses implementation

---

## 1. Navigation State Preservation Strategy

### Decision

**Use IndexedStack with StatefulWidget preservation**

### Rationale

IndexedStack is the recommended Flutter pattern for tab-based navigation with state preservation:
- Keeps all tab widgets in memory, preserving their full state
- Minimal performance impact for 3 tabs (Dashboard, Spese, Impostazioni)
- Each tab maintains its scroll position, filters, and user selections automatically
- Works seamlessly with Material NavigationBar widget
- No custom state management code needed beyond standard Riverpod

**Implementation Pattern:**
```dart
body: IndexedStack(
  index: _currentIndex,
  children: [
    DashboardScreen(),      // Tab 0
    ExpenseListScreen(),    // Tab 1
    SettingsScreen(),       // Tab 2
  ],
)
```

### Alternatives Considered

1. **Navigator per tab (separate navigation stacks)**
   - Pros: More flexible for complex nested navigation
   - Cons: Overkill for this use case, adds complexity
   - Rejected: IndexedStack is simpler and sufficient

2. **Manual state save/restore**
   - Pros: More control over what gets preserved
   - Cons: Requires significant boilerplate code
   - Rejected: IndexedStack handles automatically

3. **go_router ShellRoute**
   - Pros: Built-in go_router feature for nested navigation
   - Cons: go_router 12.0 ShellRoute can be complex with IndexedStack
   - Rejected: Would require restructuring existing navigation

### go_router Integration

The existing codebase uses go_router for routing. For the bottom navigation tabs:
- Main navigation screen remains a single route (`/home`)
- IndexedStack handles tab switching locally (not route changes)
- Deep navigation from tabs (e.g., Settings → Profile) uses go_router push
- Bottom nav persists because main_navigation_screen.dart is the root scaffold

---

## 2. Unsaved Changes Detection

### Decision

**Use Form key + dirty state tracking with PopScope widget**

### Rationale

Flutter's Form widget with GlobalKey provides built-in dirty state tracking:
- Form fields automatically track changes via TextEditingController
- Can compare current values with initial values to detect unsaved changes
- PopScope (replacement for deprecated WillPopScope) intercepts back navigation
- Works with go_router navigation events

**Implementation Pattern:**
```dart
class _ManualExpenseScreenState extends State<ManualExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => UnsavedChangesDialog(),
        );

        if (shouldPop ?? false) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Form(key: _formKey, ...),
    );
  }
}
```

### Alternatives Considered

1. **go_router redirect/listener hooks**
   - Pros: Centralized navigation guard logic
   - Cons: go_router redirects are for route-level guards, not form-level
   - Rejected: Too global, can't access form state easily

2. **Riverpod provider-based state tracking**
   - Pros: Reactive state management
   - Cons: Requires providers for every form, increases complexity
   - Rejected: Overkill when PopScope + Form handles it natively

3. **Mixin for reusable unsaved changes logic**
   - Pros: Reusable across multiple screens
   - Cons: Still requires state tracking mechanism
   - Decision: Use mixin WITH PopScope pattern for code reuse

### go_router Compatibility

PopScope works with go_router:
- Handles both system back button and programmatic navigation
- For bottom nav navigation while on edit screen, we'll listen to tab changes
- If tab change detected + unsaved changes exist, show dialog before switching

---

## 3. Recent Expenses Data Fetching

### Decision

**Fetch on Dashboard load with simple in-memory caching (Riverpod state)**

### Rationale

Given the requirements:
- Show 5-10 most recent expenses
- Load within 1 second
- Supabase query with limit + order by date is fast

**Optimal approach:**
- Query: `SELECT * FROM expenses ORDER BY created_at DESC LIMIT 10`
- Add to DashboardProvider state (already manages dashboard data)
- Fetch on Dashboard tab mount, cache in provider state
- Invalidate cache when new expense created/deleted
- No complex caching needed (small dataset, fast query)

**Supabase Query:**
```dart
final recentExpenses = await supabase
    .from('expenses')
    .select('id, amount, description, category, date, created_at')
    .eq('group_id', groupId)
    .order('created_at', ascending: false)
    .limit(10);
```

### Alternatives Considered

1. **Real-time subscription to expenses table**
   - Pros: Always up-to-date, no manual refresh needed
   - Cons: Overkill for "recent 10" list, connection overhead
   - Rejected: Polling/manual refresh is sufficient

2. **Persistent local caching with Drift/Hive + TTL**
   - Pros: Faster subsequent loads, offline support
   - Cons: Complexity, cache invalidation logic, stale data risk
   - Rejected: Recent expenses don't need offline persistence

3. **Pagination with infinite scroll**
   - Pros: Can load more expenses on demand
   - Cons: Spec requires fixed 5-10 items only
   - Rejected: Not required for this feature

### Caching Strategy

- **Cache location**: DashboardProvider state (Riverpod StateNotifier)
- **TTL**: No time-based expiration, invalidate on mutations only
- **Invalidation triggers**:
  - New expense created → refresh recent expenses
  - Expense deleted → refresh recent expenses
  - Manual refresh (pull-to-refresh)
- **Memory impact**: ~1KB for 10 expense summaries, negligible

---

## 4. Navigation Guard Implementation

### Decision

**Create reusable UnsavedChangesGuard mixin for StatefulWidgets**

### Rationale

Multiple screens need unsaved changes protection (manual expense, edit expense, profile edit):
- Mixin provides code reuse without inheritance issues
- Works with PopScope pattern
- Can be applied to any StatefulWidget with forms

**Mixin Structure:**
```dart
mixin UnsavedChangesGuard<T extends StatefulWidget> on State<T> {
  bool get hasUnsavedChanges;

  Future<bool> _confirmDiscard(BuildContext context) async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UnsavedChangesDialog(),
    );

    return result ?? false;
  }

  // Override in widget build to wrap with PopScope
  Widget buildWithGuard(BuildContext context, Widget child) {
    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard(context);
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: child,
    );
  }
}
```

### Alternatives Considered

1. **Wrapper widget (NavigationGuardWrapper)**
   - Pros: Can wrap any widget
   - Cons: Harder to access form state from parent widget
   - Rejected: Mixin is more ergonomic for StatefulWidgets

2. **Provider-based approach (hasUnsavedChangesProvider)**
   - Pros: Centralized state
   - Cons: Requires creating provider per screen, harder to track form state
   - Rejected: Mixin is simpler and more localized

3. **Custom Navigator observer**
   - Pros: Global navigation guard
   - Cons: Can't access screen-specific form state
   - Rejected: Too global, can't determine which screens have unsaved changes

### Integration with Riverpod

The mixin can access Riverpod providers if needed:
```dart
// In the screen using the mixin
bool get hasUnsavedChanges {
  final currentData = ref.read(expenseFormProvider);
  return currentData != initialData;
}
```

---

## 5. Text Truncation Patterns

### Decision

**Use Flutter Text widget overflow parameter with maxLines**

### Rationale

Flutter's built-in text overflow handling is sufficient:
- `TextOverflow.ellipsis` adds "..." when text exceeds space
- `maxLines: 1` ensures single-line display
- Automatic handling for different screen sizes
- No custom text measurement needed

**Implementation Pattern:**
```dart
Text(
  expense.description,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: Theme.of(context).textTheme.bodyMedium,
)
```

### Alternatives Considered

1. **Manual string truncation with substring**
   - Pros: Precise control over character count
   - Cons: Doesn't account for font metrics, not responsive
   - Rejected: Flutter's text widget handles better

2. **Custom TextPainter calculations**
   - Pros: Can precisely measure text width
   - Cons: Complex, performance overhead
   - Rejected: Built-in overflow is sufficient

3. **FittedBox with fit: BoxFit.scaleDown**
   - Pros: Scales text to fit
   - Cons: Can make text too small to read
   - Rejected: Ellipsis maintains readability

### Responsive Design

Different text fields have different max widths:
- **Description**: Can be 2 lines on larger screens (change to `maxLines: 2`)
- **Amount**: Always 1 line, right-aligned
- **Date**: Always 1 line, fixed format

Layout responsiveness handled by:
- `Expanded` widgets in Row/Column layouts
- `Flexible` for dynamic width allocation
- MediaQuery for screen size queries if needed

---

## 6. Deleted Expense Handling

### Decision

**Show SnackBar message + reload entire recent expenses list**

### Rationale

When user taps deleted expense:
1. API returns 404 or RLS policy blocks access
2. Show SnackBar with message: "Questa spesa è stata eliminata da un altro membro"
3. Reload recent expenses list (removes stale item + shows any new expenses)

**Why reload entire list:**
- Simplest implementation (call existing refresh method)
- Ensures list is fully up-to-date
- Minimal performance impact (10 items max)
- Avoids manual list manipulation bugs

**Implementation:**
```dart
Future<void> _onExpenseTap(String expenseId) async {
  try {
    context.push('/expense/$expenseId');
  } catch (e) {
    if (e is ExpenseNotFoundException) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questa spesa è stata eliminata da un altro membro'),
          duration: Duration(seconds: 3),
        ),
      );
      // Refresh list to remove stale item
      ref.read(dashboardProvider.notifier).refreshRecentExpenses();
    }
  }
}
```

### Alternatives Considered

1. **Remove only the tapped item from list**
   - Pros: Faster, no network request
   - Cons: List might still have other deleted items
   - Rejected: Full refresh is more reliable

2. **Silent removal without message**
   - Pros: Simpler code
   - Cons: User gets no feedback (bad UX per spec)
   - Rejected: Spec requires informative message

3. **Show dialog instead of SnackBar**
   - Pros: More prominent message
   - Cons: Requires user dismissal, blocks interaction
   - Rejected: SnackBar is less intrusive

---

## Summary of Technical Decisions

| Area | Decision | Key Benefits |
|------|----------|--------------|
| State Preservation | IndexedStack | Automatic state retention, minimal code |
| Unsaved Changes | PopScope + Form + Mixin | Built-in Flutter support, reusable pattern |
| Recent Expenses Fetch | Supabase query with Riverpod caching | Fast queries, simple invalidation |
| Navigation Guard | UnsavedChangesGuard mixin | Code reuse across multiple screens |
| Text Truncation | Text widget overflow property | Built-in, responsive, no custom logic |
| Deleted Expense | SnackBar + full list reload | User feedback + guaranteed consistency |

---

## Implementation Notes

### Performance Benchmarks

Expected performance based on Flutter best practices:
- **Tab switching**: <100ms (IndexedStack keeps widgets mounted)
- **Recent expenses query**: <500ms (10 items with indexed created_at column)
- **Dashboard load total**: <1s (spec requirement: ✅)
- **Navigation transition**: <300ms (Material route animation: ✅)

### Testing Considerations

1. **Navigation State Preservation**
   - Test: Switch tabs, scroll in list, switch back → verify scroll position preserved
   - Test: Apply filter, switch tabs, return → verify filter still active

2. **Unsaved Changes**
   - Test: Modify form, press back → verify dialog appears
   - Test: Modify form, tap bottom nav → verify dialog appears
   - Test: Modify form, press save → verify no dialog on navigation

3. **Recent Expenses**
   - Test: Create expense → verify appears in recent list
   - Test: Delete expense → verify removed from recent list
   - Test: Tap deleted expense → verify message shown and list refreshed

4. **Text Truncation**
   - Test: Long description → verify ellipsis shown
   - Test: Tap truncated expense → verify full text in detail screen

### Risk Mitigation

1. **IndexedStack Memory Overhead**
   - Mitigation: Profile memory usage on low-end devices
   - Fallback: Implement AutomaticKeepAliveClientMixin per tab if needed

2. **go_router Navigation Conflicts**
   - Mitigation: Test PopScope with go_router thoroughly
   - Fallback: Use NavigatorObserver if PopScope doesn't work

3. **Deleted Expense Race Condition**
   - Mitigation: Handle 404 errors gracefully with try-catch
   - Validation: Integration test with concurrent deletion

---

## References

- [Flutter IndexedStack documentation](https://api.flutter.dev/flutter/widgets/IndexedStack-class.html)
- [PopScope widget guide](https://api.flutter.dev/flutter/widgets/PopScope-class.html)
- [go_router package](https://pub.dev/packages/go_router)
- [Flutter Riverpod state management](https://riverpod.dev/)
- [Text overflow handling](https://api.flutter.dev/flutter/widgets/Text-class.html)

---

**Research Complete**: All open questions from plan.md have been addressed with concrete technical decisions.
