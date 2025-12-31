# Implementation Tasks: UI Navigation and Settings Reorganization

**Feature**: 002-ui-navigation-improvements
**Branch**: `002-ui-navigation-improvements`
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

---

## Task Summary

- **Total Tasks**: 28
- **User Story 1 (P1)**: 8 tasks - Settings Menu Consolidation
- **User Story 2 (P2)**: 9 tasks - Consistent Bottom Navigation Access
- **User Story 3 (P3)**: 11 tasks - Recent Expenses on Dashboard

**MVP Scope**: User Story 1 only (8 tasks) - Delivers immediate navigation improvement

---

## Implementation Strategy

**Incremental Delivery Approach:**
1. **MVP (User Story 1)**: 3-tab navigation + Settings screen → Immediate UX improvement
2. **Enhancement (User Story 2)**: State preservation + unsaved changes guards → Better user experience
3. **Polish (User Story 3)**: Recent expenses widget → Additional Dashboard value

**Each user story is independently testable and deliverable.**

---

## Phase 1: Setup (No Story Dependencies)

**Purpose**: Prepare development environment and verify prerequisites.

- [X] T001 Verify Flutter SDK ≥3.0.0 and dependencies installed via `flutter doctor`
- [X] T002 [P] Run `flutter pub get` to fetch all dependencies
- [X] T003 [P] Run `flutter pub run build_runner build --delete-conflicting-outputs` for code generation
- [X] T004 Verify app runs successfully on emulator/simulator with `flutter run`

---

## Phase 2: User Story 1 - Settings Menu Consolidation (Priority: P1)

**Goal**: Replace 4-tab bottom navigation with 3-tab structure and create Settings screen

**Independent Test Criteria**:
- ✅ Bottom navigation shows exactly 3 tabs: Dashboard, Spese, Impostazioni
- ✅ Tapping "Impostazioni" opens Settings screen with Profilo and Gruppo options
- ✅ Tapping "Profilo" from Settings navigates to Profile screen
- ✅ Tapping "Gruppo" from Settings navigates to Group details screen
- ✅ Back navigation from Profile/Group returns to Settings screen

### Implementation Tasks

- [X] T005 [US1] Update `lib/features/auth/presentation/screens/main_navigation_screen.dart` - Change `_screens` list from 4 items to 3 (Dashboard, ExpenseList, Settings)
- [X] T006 [US1] Update `lib/features/auth/presentation/screens/main_navigation_screen.dart` - Change `_destinations` list to 3 items with correct labels ("Dashboard", "Spese", "Impostazioni")
- [X] T007 [US1] Update `lib/features/auth/presentation/screens/main_navigation_screen.dart` - Update icons for Settings tab (Icons.settings_outlined, Icons.settings)
- [X] T008 [US1] Create `lib/features/auth/presentation/screens/settings_screen.dart` - Implement Settings screen with Scaffold, AppBar, and ListView containing Profilo and Gruppo ListTiles
- [X] T009 [US1] Update `lib/app/routes.dart` - Add `/home/profile` sub-route under `/home` route pointing to ProfileScreen (Routes already exist, Settings screen uses existing routes)
- [X] T010 [US1] Update `lib/app/routes.dart` - Add `/home/group` sub-route under `/home` route pointing to GroupDetailsScreen (Routes already exist, Settings screen uses existing routes)
- [X] T011 [US1] Update `lib/features/auth/presentation/screens/settings_screen.dart` - Implement navigation to Profile screen via `context.push('/home/profile')` on Profilo tap
- [X] T012 [US1] Update `lib/features/auth/presentation/screens/settings_screen.dart` - Implement navigation to Group screen via `context.push('/home/group')` on Gruppo tap

### Manual Verification (User Story 1)

**Test Steps**:
1. Launch app and log in
2. Verify bottom nav shows 3 tabs: Dashboard, Spese, Impostazioni
3. Tap "Impostazioni" → verify Settings screen displays
4. Verify Settings screen shows "Profilo" and "Gruppo" options with icons
5. Tap "Profilo" → verify Profile screen opens
6. Tap back → verify returns to Settings screen
7. Tap "Gruppo" → verify Group details screen opens
8. Tap back → verify returns to Settings screen
9. Tap "Dashboard" bottom nav → verify navigates to Dashboard
10. Tap "Spese" bottom nav → verify navigates to Expenses list

**Expected Result**: ✅ All navigation flows work correctly, bottom nav visible

---

## Phase 3: User Story 2 - Consistent Bottom Navigation Access (Priority: P2)

**Goal**: Preserve tab state and implement unsaved changes guards

**Independent Test Criteria**:
- ✅ Switching tabs preserves scroll position in lists
- ✅ Switching tabs preserves applied filters (e.g., Dashboard period selection)
- ✅ Bottom navigation visible on all screens including deep navigation
- ✅ Unsaved changes dialog appears when navigating away from dirty forms
- ✅ Can cancel dialog to stay on form or confirm to discard changes

### State Preservation Tasks

- [ ] T013 [P] [US2] Verify `lib/features/auth/presentation/screens/main_navigation_screen.dart` uses IndexedStack pattern for `body` property
- [ ] T014 [US2] Test state preservation - Navigate to Spese tab, scroll down, switch to Dashboard, return to Spese and verify scroll position preserved

### Unsaved Changes Guard Tasks

- [ ] T015 [P] [US2] Create `lib/shared/widgets/unsaved_changes_dialog.dart` - Implement AlertDialog with title "Modifiche non salvate", content explaining unsaved changes, and two buttons ("Annulla", "Esci senza salvare")
- [ ] T016 [P] [US2] Create `lib/shared/widgets/navigation_guard.dart` - Implement `UnsavedChangesGuard` mixin with `hasUnsavedChanges` getter, `confirmDiscardChanges()` method, and `buildWithNavigationGuard()` method using PopScope
- [ ] T017 [US2] Update `lib/features/expenses/presentation/screens/manual_expense_screen.dart` - Add `UnsavedChangesGuard` mixin to state class
- [ ] T018 [US2] Update `lib/features/expenses/presentation/screens/manual_expense_screen.dart` - Implement `hasUnsavedChanges` getter by comparing current form values with initial values stored in `initState()`
- [ ] T019 [US2] Update `lib/features/expenses/presentation/screens/manual_expense_screen.dart` - Wrap Scaffold with `buildWithNavigationGuard()` in build method
- [ ] T020 [US2] Test unsaved changes guard - Enter data in manual expense form, press back button, verify dialog appears with correct text
- [ ] T021 [US2] Test unsaved changes guard - Enter data in manual expense form, tap bottom nav item, verify dialog appears and allows navigation on confirm

### Manual Verification (User Story 2)

**Test Steps**:
1. Navigate to Spese tab, scroll to bottom of list
2. Switch to Dashboard tab
3. Switch back to Spese tab → verify scroll position is at bottom (preserved)
4. Apply filter on Dashboard (select period)
5. Switch to Spese, then back to Dashboard → verify filter still applied
6. Tap FAB to add expense, enter amount "50" and description "Test"
7. Press device back button → verify "Modifiche non salvate" dialog appears
8. Tap "Annulla" → verify stays on expense screen with data intact
9. Press back again, tap "Esci senza salvare" → verify returns to previous screen
10. Add expense again with data, tap "Spese" bottom nav → verify dialog appears
11. Tap "Esci senza salvare" → verify navigates to Spese tab

**Expected Result**: ✅ State preserved, unsaved changes protected

---

## Phase 4: User Story 3 - Recent Expenses on Dashboard (Priority: P3)

**Goal**: Display 5-10 recent expenses on Dashboard with tap navigation

**Independent Test Criteria**:
- ✅ Dashboard shows "Spese recenti" section with list of expenses
- ✅ Each expense shows date, amount, description, category
- ✅ List shows maximum 10 items, ordered by creation date (newest first)
- ✅ Long descriptions are truncated with ellipsis (...)
- ✅ Tapping expense navigates to detail screen
- ✅ "Vedi tutte" button navigates to full expense list
- ✅ Empty state shows when no expenses exist
- ✅ Tapping deleted expense shows error message and refreshes list

### Domain & Data Layer Tasks

- [ ] T022 [P] [US3] Create `lib/features/dashboard/domain/entities/recent_expense_entity.dart` - Define RecentExpenseEntity with fields: id, amount, currency, description, category, date, createdAt, createdBy, createdByName
- [ ] T023 [P] [US3] Create `lib/features/dashboard/data/models/recent_expense_model.dart` - Implement RecentExpenseModel with fromJson() factory and toEntity() method
- [ ] T024 [US3] Update `lib/features/dashboard/domain/repositories/dashboard_repository.dart` - Add `Future<List<RecentExpenseEntity>> getRecentExpenses({int limit = 10})` method signature
- [ ] T025 [US3] Update `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart` - Implement getRecentExpenses() method calling remote datasource
- [ ] T026 [US3] Update `lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart` - Add fetchRecentExpenses() method with Supabase query: `SELECT e.*, p.display_name as created_by_name FROM expenses e LEFT JOIN profiles p ON e.created_by = p.id WHERE e.group_id = :groupId AND e.deleted_at IS NULL ORDER BY e.created_at DESC LIMIT :limit`

### Presentation Layer Tasks

- [ ] T027 [US3] Update `lib/features/dashboard/presentation/providers/dashboard_provider.dart` - Add `recentExpenses`, `recentExpensesLoading`, `recentExpensesError` fields to DashboardState
- [ ] T028 [US3] Update `lib/features/dashboard/presentation/providers/dashboard_provider.dart` - Add `loadRecentExpenses()` and `refreshRecentExpenses()` methods to DashboardNotifier
- [ ] T029 [P] [US3] Create `lib/features/dashboard/presentation/widgets/recent_expenses_list.dart` - Implement RecentExpensesList widget with Card, title "Spese recenti", "Vedi tutte" button, and ListView of expense items
- [ ] T030 [P] [US3] Create `lib/features/dashboard/presentation/widgets/recent_expense_item.dart` - Implement RecentExpenseItem widget as ListTile with CircleAvatar icon, description (maxLines:1, overflow: ellipsis), date subtitle, amount trailing, and onTap navigation
- [ ] T031 [US3] Update `lib/features/dashboard/presentation/widgets/recent_expenses_list.dart` - Implement empty state UI when expenses list is empty (icon, message "Nessuna spesa recente")
- [ ] T032 [US3] Update `lib/features/dashboard/presentation/screens/dashboard_screen.dart` - Add RecentExpensesList widget before existing summary card with `expenses: dashboardState.recentExpenses` and `onSeeAll: () => _tabController.animateTo(1)`

### Error Handling & Edge Cases

- [ ] T033 [US3] Update `lib/features/dashboard/presentation/widgets/recent_expense_item.dart` - Implement onTap with try-catch to handle ExpenseNotFoundException, show SnackBar "Questa spesa è stata eliminata da un altro membro", and call refreshRecentExpenses()
- [ ] T034 [US3] Test deleted expense handling - Manually delete expense from Supabase, tap it from recent expenses, verify error message shows and list refreshes

### Manual Verification (User Story 3)

**Test Steps**:
1. Launch app, navigate to Dashboard
2. Verify "Spese recenti" section appears above summary card
3. If no expenses exist → verify shows "Nessuna spesa recente" message
4. Create a new expense via FAB (amount: 25, description: "Coffee")
5. Return to Dashboard → verify expense appears in recent expenses
6. Create 12 more expenses → verify only 10 most recent shown
7. Verify each expense shows: category icon, description, date, amount
8. Create expense with long description: "Very long expense description that should be truncated with ellipsis to fit in one line without wrapping"
9. Verify description shows "Very long expense desc..." with ellipsis
10. Tap an expense in recent list → verify navigates to expense detail screen
11. Return to Dashboard, tap "Vedi tutte" → verify switches to Spese tab
12. Delete an expense from another device/browser (simulate concurrent deletion)
13. Tap deleted expense from recent list → verify SnackBar shows "Questa spesa è stata eliminata da un altro membro"
14. Verify recent expenses list refreshes automatically after error

**Expected Result**: ✅ Recent expenses display correctly with all edge cases handled

---

## Dependencies & Execution Order

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (US1 - Settings Consolidation) ← MVP minimum
    ↓
Phase 3 (US2 - Navigation Access) ← Can run independently after US1
    ↓
Phase 4 (US3 - Recent Expenses) ← Can run independently after US1
```

**Critical Path**: Setup → US1 → (US2 || US3 in parallel)

**Blocking Dependencies**:
- US2 and US3 both require US1 to be complete (3-tab navigation must exist)
- US2 and US3 are independent of each other (can be implemented in parallel)

**Non-Blocking**:
- Unsaved changes guard (US2) does not block recent expenses (US3)
- State preservation (US2) does not block recent expenses (US3)

### Parallel Execution Opportunities

**Within User Story 1**:
```
T005, T006, T007 (main_navigation_screen.dart changes) → Sequential
T008 (settings_screen.dart creation) → Can start in parallel with T009-T010
T009, T010 (routes.dart updates) → Parallel
T011, T012 (settings_screen.dart navigation) → Sequential after T008
```

**Within User Story 2**:
```
T015 (unsaved_changes_dialog.dart) ║ Parallel
T016 (navigation_guard.dart)        ║
    ↓
T017, T018, T019 (apply to manual_expense_screen.dart) → Sequential
```

**Within User Story 3**:
```
T022 (recent_expense_entity.dart)  ║ Parallel
T023 (recent_expense_model.dart)   ║
    ↓
T024, T025, T026 (repository & datasource) → Sequential
    ↓
T027, T028 (provider updates) → Sequential
    ↓
T029 (recent_expenses_list.dart)   ║ Parallel
T030 (recent_expense_item.dart)    ║
    ↓
T031, T032 (dashboard integration) → Sequential
T033 (error handling) → Sequential
```

---

## Testing Strategy (Manual)

### Acceptance Testing Per User Story

**User Story 1 - Settings Consolidation**:
- [ ] Bottom nav has 3 tabs (not 4)
- [ ] "Impostazioni" tab exists and is tappable
- [ ] Settings screen shows "Profilo" and "Gruppo" options
- [ ] Both options navigate correctly
- [ ] Back navigation returns to Settings
- [ ] Bottom nav remains visible during deep navigation

**User Story 2 - Navigation Access**:
- [ ] Scroll position preserved when switching tabs
- [ ] Filter selections preserved when switching tabs
- [ ] Bottom nav visible on all screens
- [ ] Unsaved changes dialog appears when appropriate
- [ ] Dialog allows cancel or confirm discard
- [ ] No dialog appears when no changes made

**User Story 3 - Recent Expenses**:
- [ ] "Spese recenti" section visible on Dashboard
- [ ] Shows up to 10 most recent expenses
- [ ] Each expense shows: icon, description, date, amount
- [ ] Long descriptions truncated with ellipsis
- [ ] Tapping expense navigates to detail
- [ ] "Vedi tutte" navigates to Expenses tab
- [ ] Empty state shows when no expenses
- [ ] Deleted expense shows error and refreshes list

### Performance Verification

- [ ] Tab switching completes in <300ms (use stopwatch or Flutter DevTools)
- [ ] Recent expenses load within 1s of Dashboard opening
- [ ] Navigation transitions are smooth (60fps, no dropped frames)
- [ ] App memory usage <50MB with all 3 tabs loaded

---

## Rollback Plan

If issues arise after deployment:

1. **Revert US3**: Remove recent expenses widget from Dashboard (revert T029-T034)
2. **Revert US2**: Remove unsaved changes guards (revert T015-T021), state preservation remains
3. **Revert US1**: Restore 4-tab navigation (revert T005-T012)

Each user story can be rolled back independently due to modular design.

---

## Success Metrics (from spec.md)

- **SC-001**: ✅ Settings, Profile, Group accessible in ≤2 taps from any screen
- **SC-002**: ✅ Navigate between tabs without back navigation
- **SC-003**: ✅ Recent expenses visible within 1s
- **SC-004**: ✅ Bottom nav on 100% of screens
- **SC-005**: ✅ Expense details accessible with 1 tap from recent list
- **SC-006**: ✅ Tab transitions <300ms

---

## Implementation Notes

**Code Standards**:
- Follow existing Flutter/Dart style guide
- Use Riverpod for state management (consistent with codebase)
- Preserve Clean Architecture layers (domain/data/presentation)
- Use go_router for navigation (existing pattern)
- Add inline comments for complex logic only

**File Organization**:
- New screens go in appropriate `features/*/presentation/screens/` folder
- Shared widgets go in `lib/shared/widgets/`
- Follow existing naming conventions (snake_case for files, PascalCase for classes)

**Git Commits**:
- Commit after each completed user story phase
- Use descriptive commit messages: "feat: Implement Settings menu consolidation (US1)"
- Reference task IDs in commit body if helpful for tracking

---

**Tasks generated**: 34 total (4 setup + 8 US1 + 9 US2 + 11 US3 + 2 verification)
**MVP scope**: Tasks T001-T012 (Setup + User Story 1) = 12 tasks
**Full feature**: All 34 tasks

**Ready for implementation**: ✅ All tasks are independently executable with clear file paths and acceptance criteria.
