# Data Model: UI Navigation and Settings Reorganization

**Feature**: 002-ui-navigation-improvements
**Date**: 2025-12-31
**Purpose**: Define data structures for recent expenses, navigation state, and unsaved changes tracking

---

## Overview

This feature introduces minimal new data structures. Most navigation logic uses existing entities (Expense, User, Group) with new presentation-layer models for:
1. Recent expense summaries (lightweight expense representation)
2. Navigation state (tab indices, scroll positions)
3. Unsaved changes state (form dirty tracking)

---

## 1. RecentExpenseEntity (Domain Layer)

### Purpose
Represents a lightweight summary of an expense for display in the Dashboard's recent expenses list.

### Structure

```dart
class RecentExpenseEntity extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final String description;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final String createdBy;      // User ID who created the expense
  final String? createdByName;  // Optional: user display name

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

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Unique expense identifier (UUID) |
| `amount` | double | Yes | Expense amount (positive number) |
| `currency` | String | Yes | Currency code (e.g., "EUR") |
| `description` | String | Yes | Expense description (may be truncated in UI) |
| `category` | String | Yes | Expense category (e.g., "Food", "Transport") |
| `date` | DateTime | Yes | Date of the expense transaction |
| `createdAt` | DateTime | Yes | Timestamp when expense was created in system |
| `createdBy` | String | Yes | User ID of expense creator |
| `createdByName` | String | No | Display name of creator (for group view) |

### Validation Rules

- `id`: Must be valid UUID format
- `amount`: Must be > 0
- `currency`: Must be valid ISO 4217 currency code (validated by existing system)
- `description`: 1-500 characters (enforced by expense creation)
- `category`: Must match predefined category list
- `date`: Cannot be in future
- `createdAt`: System-generated, immutable

### Relationships

- **Source**: Full `ExpenseEntity` from expenses table
- **Creator**: References `User` entity via `createdBy` field
- **Group**: Implicitly filtered by user's current group

---

## 2. RecentExpenseModel (Data Layer)

### Purpose
Data transfer object for mapping Supabase JSON to `RecentExpenseEntity`.

### Structure

```dart
class RecentExpenseModel {
  final String id;
  final double amount;
  final String currency;
  final String description;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final String createdBy;
  final String? createdByName;

  const RecentExpenseModel({
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

  // From Supabase JSON
  factory RecentExpenseModel.fromJson(Map<String, dynamic> json) {
    return RecentExpenseModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      description: json['description'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
      createdByName: json['created_by_name'] as String?,
    );
  }

  // To domain entity
  RecentExpenseEntity toEntity() {
    return RecentExpenseEntity(
      id: id,
      amount: amount,
      currency: currency,
      description: description,
      category: category,
      date: date,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByName: createdByName,
    );
  }
}
```

### Supabase Query

```sql
SELECT
  e.id,
  e.amount,
  e.currency,
  e.description,
  e.category,
  e.date,
  e.created_at,
  e.created_by,
  u.display_name as created_by_name
FROM expenses e
LEFT JOIN profiles u ON e.created_by = u.id
WHERE e.group_id = :groupId
  AND e.deleted_at IS NULL
ORDER BY e.created_at DESC
LIMIT :limit
```

---

## 3. NavigationState (Presentation Layer)

### Purpose
Track bottom navigation tab state for persistence across tab switches.

### Structure

```dart
class NavigationState extends Equatable {
  final int currentTabIndex;
  final Map<int, ScrollController> scrollControllers;
  final Map<int, dynamic> tabSpecificState;

  const NavigationState({
    required this.currentTabIndex,
    required this.scrollControllers,
    this.tabSpecificState = const {},
  });

  @override
  List<Object?> get props => [currentTabIndex, tabSpecificState];

  NavigationState copyWith({
    int? currentTabIndex,
    Map<int, ScrollController>? scrollControllers,
    Map<int, dynamic>? tabSpecificState,
  }) {
    return NavigationState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      scrollControllers: scrollControllers ?? this.scrollControllers,
      tabSpecificState: tabSpecificState ?? this.tabSpecificState,
    );
  }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `currentTabIndex` | int | Active tab index (0=Dashboard, 1=Spese, 2=Impostazioni) |
| `scrollControllers` | Map<int, ScrollController> | Scroll controllers per tab for position preservation |
| `tabSpecificState` | Map<int, dynamic> | Tab-specific state (e.g., filters, selections) |

### State Preservation

**Handled automatically by IndexedStack:**
- Widget trees for all tabs remain mounted
- StatefulWidgets preserve their state
- ScrollControllers preserve scroll positions
- No manual state save/restore needed

**NavigationState is primarily for**:
- Tracking current tab index
- Providing named access to scroll controllers
- Storing metadata about tab state (optional)

---

## 4. UnsavedChangesState (Presentation Layer)

### Purpose
Track whether forms have unsaved changes for navigation guard.

### Structure

```dart
class UnsavedChangesState {
  final bool hasUnsavedChanges;
  final Map<String, dynamic>? initialValues;
  final Map<String, dynamic>? currentValues;

  const UnsavedChangesState({
    required this.hasUnsavedChanges,
    this.initialValues,
    this.currentValues,
  });

  factory UnsavedChangesState.initial() {
    return const UnsavedChangesState(hasUnsavedChanges: false);
  }

  factory UnsavedChangesState.fromForm({
    required Map<String, dynamic> initialValues,
    required Map<String, dynamic> currentValues,
  }) {
    return UnsavedChangesState(
      hasUnsavedChanges: initialValues != currentValues,
      initialValues: initialValues,
      currentValues: currentValues,
    );
  }
}
```

### Usage Pattern

```dart
class _ManualExpenseScreenState extends State<ManualExpenseScreen>
    with UnsavedChangesGuard {

  Map<String, dynamic>? _initialValues;

  @override
  void initState() {
    super.initState();
    _initialValues = _getFormValues();
  }

  @override
  bool get hasUnsavedChanges {
    final current = _getFormValues();
    return current != _initialValues;
  }

  Map<String, dynamic> _getFormValues() {
    return {
      'amount': _amountController.text,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'date': _selectedDate,
    };
  }
}
```

---

## 5. Settings Menu Structure

### Purpose
Define the structure of the Settings screen menu.

### Structure

```dart
enum SettingsMenuItem {
  profile,
  group,
  // Future: notifications, preferences, about, etc.
}

class SettingsMenuItemData {
  final SettingsMenuItem type;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const SettingsMenuItemData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
```

### Settings Items

| Type | Title | Subtitle | Icon | Route |
|------|-------|----------|------|-------|
| profile | Profilo | Gestisci il tuo profilo | Icons.person | /profile |
| group | Gruppo | Gestisci il gruppo familiare | Icons.group | /group |

---

## Entity Relationships

```
┌─────────────────────────┐
│   ExpenseEntity         │
│  (existing, unchanged)  │
└────────────┬────────────┘
             │
             │ derived from (SELECT with LIMIT)
             ▼
┌─────────────────────────┐
│ RecentExpenseEntity     │
│ - id                    │
│ - amount, currency      │
│ - description, category │
│ - date, createdAt       │
│ - createdBy (→ User)    │
└─────────────────────────┘
             │
             │ displayed in
             ▼
┌─────────────────────────┐
│ Dashboard Screen        │
│ - Recent Expenses List  │
└─────────────────────────┘

┌─────────────────────────┐
│ NavigationState         │
│ - currentTabIndex       │
│ - scrollControllers     │
│ - tabSpecificState      │
└─────────────────────────┘
             │
             │ manages
             ▼
┌─────────────────────────┐
│ MainNavigationScreen    │
│ - IndexedStack (3 tabs) │
└─────────────────────────┘

┌─────────────────────────┐
│ UnsavedChangesState     │
│ - hasUnsavedChanges     │
│ - initialValues         │
│ - currentValues         │
└─────────────────────────┘
             │
             │ guards
             ▼
┌─────────────────────────┐
│ Form Screens            │
│ (Manual Expense, etc.)  │
└─────────────────────────┘
```

---

## Data Flow Diagrams

### Recent Expenses Data Flow

```
User opens Dashboard
        ↓
DashboardProvider.loadRecentExpenses()
        ↓
DashboardRepository.getRecentExpenses(limit: 10)
        ↓
DashboardRemoteDataSource.fetchRecentExpenses()
        ↓
Supabase query (ORDER BY created_at DESC LIMIT 10)
        ↓
List<Map<String, dynamic>> JSON
        ↓
List<RecentExpenseModel>.fromJson()
        ↓
List<RecentExpenseEntity>.toEntity()
        ↓
DashboardProvider state update
        ↓
Dashboard Screen rebuilds with RecentExpensesList widget
```

### Navigation State Preservation Flow

```
User on Dashboard (Tab 0)
User scrolls down
ScrollController updates position
        ↓
User taps "Spese" (Tab 1)
        ↓
IndexedStack switches to index 1
Dashboard widget stays mounted (preserves ScrollController)
        ↓
User taps "Dashboard" (Tab 0)
        ↓
IndexedStack switches to index 0
Dashboard widget still at previous scroll position ✅
```

### Unsaved Changes Flow

```
User opens Manual Expense Screen
Form initialized with empty values
_initialValues = {}
        ↓
User fills amount = "50", description = "Lunch"
_currentValues = {amount: "50", description: "Lunch"}
hasUnsavedChanges = true
        ↓
User taps back button
        ↓
PopScope intercepts (canPop = false)
        ↓
Show UnsavedChangesDialog
"Hai modifiche non salvate. Vuoi uscire?"
        ↓
User taps "Esci" → discard changes, pop screen
User taps "Annulla" → stay on screen, keep editing
```

---

## Database Schema Impact

**No database schema changes required.**

All data comes from existing `expenses` table. The recent expenses feature is purely a UI presentation change - querying existing data with a different sort order and limit.

### Existing `expenses` Table (Reference)

```sql
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id UUID NOT NULL REFERENCES family_groups(id),
  created_by UUID NOT NULL REFERENCES profiles(id),
  amount NUMERIC(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'EUR',
  description TEXT NOT NULL,
  category VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  -- ... other fields
);

-- Relevant indexes (already exist)
CREATE INDEX idx_expenses_group_id ON expenses(group_id);
CREATE INDEX idx_expenses_created_at ON expenses(created_at DESC);
CREATE INDEX idx_expenses_deleted_at ON expenses(deleted_at) WHERE deleted_at IS NULL;
```

**Performance Note:** The `idx_expenses_created_at` index ensures fast sorting for recent expenses queries.

---

## State Management Architecture

### DashboardProvider Extension

Add recent expenses state to existing `DashboardProvider`:

```dart
class DashboardState {
  // ... existing fields
  final List<RecentExpenseEntity> recentExpenses;
  final bool recentExpensesLoading;
  final String? recentExpensesError;

  // ... existing methods

  DashboardState copyWith({
    // ... existing parameters
    List<RecentExpenseEntity>? recentExpenses,
    bool? recentExpensesLoading,
    String? recentExpensesError,
  }) {
    return DashboardState(
      // ... existing copies
      recentExpenses: recentExpenses ?? this.recentExpenses,
      recentExpensesLoading: recentExpensesLoading ?? this.recentExpensesLoading,
      recentExpensesError: recentExpensesError ?? this.recentExpensesError,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  // ... existing methods

  Future<void> loadRecentExpenses() async {
    state = state.copyWith(recentExpensesLoading: true);

    try {
      final expenses = await _repository.getRecentExpenses(limit: 10);
      state = state.copyWith(
        recentExpenses: expenses,
        recentExpensesLoading: false,
        recentExpensesError: null,
      );
    } catch (e) {
      state = state.copyWith(
        recentExpensesLoading: false,
        recentExpensesError: e.toString(),
      );
    }
  }

  Future<void> refreshRecentExpenses() => loadRecentExpenses();
}
```

---

## Validation & Constraints

### RecentExpenseEntity Constraints

- **Maximum list size**: 10 items (enforced by query LIMIT)
- **Minimum list size**: 0 items (empty state handled by UI)
- **Description length**: Display truncated to 1-2 lines (full text in detail screen)
- **Date range**: No restriction (recent expenses ordered by creation time, not expense date)
- **Deleted expenses**: Filtered out via `WHERE deleted_at IS NULL`

### Navigation State Constraints

- **Tab index range**: 0-2 (3 tabs only)
- **Scroll controller lifecycle**: Created on tab mount, disposed on app close
- **Memory overhead**: ~1KB per tab for scroll position storage

### Unsaved Changes Constraints

- **Form fields tracked**: Only user-modifiable fields (not system-generated IDs, timestamps)
- **Comparison strategy**: Shallow equality for simple fields, deep equality for complex objects
- **Dialog timeout**: No timeout (user must explicitly choose action)

---

## Migration & Backwards Compatibility

**No data migration required.**

Changes are purely at the presentation layer:
- No new database tables
- No schema modifications
- No data transformations
- Existing expense data works as-is

**App version compatibility:**
- Old app versions: Continue to work (bottom nav has 4 tabs)
- New app version: Uses 3-tab bottom nav + Settings screen
- No API version changes needed
- Backend remains unchanged

---

## Testing Considerations

### Unit Tests

```dart
// RecentExpenseModel tests
test('fromJson creates correct model from Supabase JSON', () {
  final json = {
    'id': '123',
    'amount': 50.00,
    'currency': 'EUR',
    'description': 'Lunch',
    'category': 'Food',
    'date': '2025-12-31',
    'created_at': '2025-12-31T12:00:00Z',
    'created_by': 'user123',
    'created_by_name': 'John Doe',
  };

  final model = RecentExpenseModel.fromJson(json);

  expect(model.id, '123');
  expect(model.amount, 50.00);
  expect(model.description, 'Lunch');
});

test('toEntity converts model to entity correctly', () {
  final model = RecentExpenseModel(/* ... */);
  final entity = model.toEntity();

  expect(entity.id, model.id);
  expect(entity.amount, model.amount);
});
```

### Widget Tests

```dart
// RecentExpenseItem widget test
testWidgets('displays expense with truncated description', (tester) async {
  final expense = RecentExpenseEntity(
    description: 'Very long description that should be truncated with ellipsis',
    // ... other fields
  );

  await tester.pumpWidget(
    MaterialApp(home: RecentExpenseItem(expense: expense)),
  );

  expect(find.text(expense.description), findsOneWidget);

  // Verify text is truncated (ellipsis shown)
  final textWidget = tester.widget<Text>(find.text(expense.description));
  expect(textWidget.maxLines, 1);
  expect(textWidget.overflow, TextOverflow.ellipsis);
});
```

### Integration Tests

```dart
// Full flow test
testWidgets('recent expenses appear after creating expense', (tester) async {
  // Open app, navigate to Dashboard
  await tester.pumpWidget(MyApp());

  // Create new expense
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  // ... fill form ...
  await tester.tap(find.text('Salva'));
  await tester.pumpAndSettle();

  // Return to Dashboard
  await tester.tap(find.text('Dashboard'));
  await tester.pumpAndSettle();

  // Verify expense appears in recent list
  expect(find.text('Lunch'), findsOneWidget);
});
```

---

**Data Model Complete**: All entities, models, and state structures defined for implementation.
