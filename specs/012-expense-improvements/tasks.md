# Tasks: Expense Management Improvements

**Input**: Design documents from `/specs/012-expense-improvements/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: Tests are NOT requested in the specification. Test tasks are excluded per speckit guidelines.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Flutter project with feature-based clean architecture
- `lib/` at repository root contains all source code
- Tests mirror source structure in `test/` and `integration_test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database migration and code generation prerequisites

- [X] T001 Create Supabase migration file `supabase/migrations/20260116_add_reimbursement_tracking.sql` with schema changes from data-model.md
- [X] T002 Apply Supabase migration to add reimbursement_status and reimbursed_at columns to public.expenses table (Migration file created, apply via Supabase Dashboard)
- [X] T003 [P] Create reimbursement_status enum in `lib/core/enums/reimbursement_status.dart` per data-model.md
- [X] T004 [P] Update Drift table definition in `lib/core/database/drift/tables/expenses.dart` to include reimbursement columns (Updated offline_database.dart OfflineExpenses table)
- [X] T005 Run flutter pub run build_runner build to generate Drift code after schema changes

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core entity and utility updates that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Extend ExpenseEntity in `lib/features/expenses/domain/entities/expense_entity.dart` with reimbursementStatus and reimbursedAt fields per data-model.md
- [X] T007 Add canTransitionTo, requiresConfirmation, and updateReimbursementStatus methods to ExpenseEntity per data-model.md state machine
- [X] T008 Add computed properties isPendingReimbursement and isReimbursed to ExpenseEntity
- [X] T009 Update ExpenseEntity props list to include new reimbursement fields for Equatable comparison
- [X] T010 [P] Update ExpenseModel in `lib/features/expenses/data/models/expense_model.dart` to serialize/deserialize reimbursement fields in fromJson and toJson
- [X] T011 [P] Extend BudgetStatsEntity in `lib/features/budgets/domain/entities/budget_stats_entity.dart` with totalPendingReimbursements and totalReimbursedIncome fields
- [X] T012 [P] Add netSpentAmount getter to BudgetStatsEntity per data-model.md calculation logic
- [X] T013 [P] Create ReimbursementSummaryEntity in `lib/features/budgets/domain/entities/reimbursement_summary_entity.dart` per data-model.md

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Expense Deletion Confirmation (Priority: P1) 🎯 MVP

**Goal**: Prevent accidental expense deletions with confirmation dialogs that show warnings for reimbursable expenses

**Independent Test**: Delete any expense and verify confirmation dialog appears. Delete a reimbursable expense and verify additional warning is displayed.

### Implementation for User Story 1

- [X] T014 [P] [US1] Create delete_confirmation_dialog.dart in `lib/features/expenses/presentation/widgets/delete_confirmation_dialog.dart` per research.md pattern with Material AlertDialog
- [X] T015 [P] [US1] Add conditional warning UI in delete confirmation dialog when isReimbursable parameter is true
- [X] T016 [US1] Update deleteExpense method in `lib/features/expenses/presentation/providers/expense_provider.dart` to call showDeleteConfirmationDialog before deletion
- [X] T017 [US1] Pass expense.isPendingReimbursement to dialog isReimbursable parameter in deleteExpense method
- [X] T018 [US1] Only proceed with deletion if dialog returns true (user confirmed)
- [X] T019 [US1] Update any UI components that trigger expense deletion (e.g., swipe-to-delete, delete buttons) to use the provider's deleteExpense method with BuildContext

**Checkpoint**: At this point, User Story 1 should be fully functional - all expense deletions require confirmation with warnings for reimbursable expenses

---

## Phase 4: User Story 2 - Initial Income Display Fix (Priority: P1)

**Goal**: Fix zero income bug on dashboard initialization by ensuring income loads before dashboard renders

**Independent Test**: Clear app data, relaunch app with existing income data, verify income displays correctly (not zero) on first dashboard load

### Implementation for User Story 2

- [X] T020 [US2] Update incomeSourcesList provider in `lib/features/budgets/presentation/providers/income_source_provider.dart` to await authStateProvider.future per research.md fix pattern
- [X] T021 [US2] Add graceful degradation in incomeSourcesList to return empty list on auth failure with debugPrint logging
- [X] T022 [US2] Update DashboardData provider in `lib/features/dashboard/presentation/providers/dashboard_provider.dart` (or equivalent) to await incomeSourcesListProvider.future before calculating totalIncome
- [X] T023 [US2] Ensure dashboard state calculation includes all required data (income, expenses, budgets) using Future.wait or sequential awaits
- [X] T024 [P] [US2] Extend StaleDataBanner widget in `lib/shared/widgets/offline_banner.dart` to support stale data mode per research.md implementation pattern
- [X] T025 [P] [US2] Add StaleDataBanner to budget_dashboard_screen.dart in `lib/features/budgets/presentation/screens/budget_dashboard_screen.dart` above main dashboard content
- [X] T026 [US2] Create connectivity and lastSyncTime providers if not already present for StaleDataBanner widget

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - income displays correctly on first launch and deletion requires confirmation

---

## Phase 5: User Story 3 - Reimbursable Expense Tracking (Priority: P2)

**Goal**: Track expenses as reimbursable/reimbursed with budget calculations treating reimbursements as income in the reimbursement period

**Independent Test**: Create expense, mark as reimbursable, verify badge shows. Mark as reimbursed, verify budget increases and badge updates. Filter expenses by reimbursement status.

### Core Budget Calculator Updates

- [ ] T027 [US3] Add calculateReimbursedIncome static method to BudgetCalculator in `lib/core/utils/budget_calculator.dart` per research.md calculation logic
- [ ] T028 [US3] Add calculatePendingReimbursements static method to BudgetCalculator per research.md
- [ ] T029 [US3] Update calculateRemainingAmount method signature to include optional reimbursedIncome parameter with default 0
- [ ] T030 [US3] Update calculatePercentageUsed method signature to include optional reimbursedIncome parameter and calculate netSpent

### UI Widgets for Reimbursement

- [ ] T031 [P] [US3] Create ReimbursementStatusBadge widget in `lib/shared/widgets/reimbursement_status_badge.dart` per quickstart.md with compact and full modes
- [ ] T032 [P] [US3] Update expense_list_item.dart in `lib/features/expenses/presentation/widgets/expense_list_item.dart` to display ReimbursementStatusBadge after amount
- [ ] T033 [P] [US3] Create reimbursement_status_change_dialog.dart in `lib/features/expenses/presentation/widgets/reimbursement_status_change_dialog.dart` for confirming status reversions
- [ ] T034 [P] [US3] Create reimbursement_toggle.dart widget in `lib/features/expenses/presentation/widgets/reimbursement_toggle.dart` for expense forms (three-state selector)

### Form Integration

- [ ] T035 [US3] Add reimbursement status toggle to manual_expense_screen.dart in `lib/features/expenses/presentation/screens/manual_expense_screen.dart` using ReimbursementToggle widget
- [ ] T036 [US3] Add reimbursement status change UI to edit_expense_screen.dart in `lib/features/expenses/presentation/screens/edit_expense_screen.dart` with status change dialog integration
- [ ] T037 [US3] Update expense form state to track reimbursementStatus field and pass to repository on save

### Provider Updates for Reimbursement

- [ ] T038 [US3] Add updateReimbursementStatus method to ExpenseListNotifier in `lib/features/expenses/presentation/providers/expense_provider.dart` per quickstart.md
- [ ] T039 [US3] Implement confirmation check using expense.requiresConfirmation in updateReimbursementStatus before calling showReimbursementStatusChangeDialog
- [ ] T040 [US3] Call expense.updateReimbursementStatus domain method and handle StateError for invalid transitions in provider
- [ ] T041 [US3] Update BudgetStatsNotifier in `lib/features/budgets/presentation/providers/budget_provider.dart` to calculate reimbursed income and pending reimbursements using BudgetCalculator
- [ ] T042 [US3] Pass reimbursedIncome to budget calculation methods in BudgetStatsNotifier for accurate netSpent calculations
- [ ] T043 [US3] Create or update reimbursement summary provider to aggregate pending/reimbursed totals across all expenses

### Filtering

- [ ] T044 [P] [US3] Add reimbursement status filter options to expense_filters_provider.dart in `lib/features/expenses/presentation/providers/expense_filters_provider.dart` (if exists) or create new filter provider
- [ ] T045 [P] [US3] Update expense list filtering logic to support filtering by reimbursementStatus enum values
- [ ] T046 [US3] Add reimbursement filter UI controls to expense list screen with chips or dropdown for none/reimbursable/reimbursed

### Repository Layer

- [ ] T047 [US3] Update ExpenseRepository interface to support updateExpense with reimbursement fields if not already generic
- [ ] T048 [US3] Ensure expense_repository_impl.dart in `lib/features/expenses/data/repositories/expense_repository_impl.dart` correctly syncs reimbursement fields to Supabase and Drift

**Checkpoint**: All user stories should now be independently functional - deletion confirmed, income displays correctly, reimbursement tracking works with budget updates

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final validation

- [ ] T049 [P] Add Italian localization strings for all new dialogs and labels if using l10n (or verify hardcoded Italian text is correct)
- [ ] T050 [P] Verify Material Design 3 theme compatibility for all new widgets (dialogs, badges, banners)
- [ ] T051 [P] Update expense detail screen to show reimbursement status with badge and allow status changes
- [ ] T052 Verify budget dashboard displays reimbursement summary (pending and reimbursed totals) if UI mockup requires it
- [ ] T053 Manual testing per quickstart.md checklist - delete flows, income display, reimbursement workflows
- [ ] T054 [P] Code cleanup - remove any unused imports, add dartdoc comments to new public APIs
- [ ] T055 Performance validation - verify dialog response <200ms, budget recalculation <500ms per plan.md performance goals
- [ ] T056 Run flutter analyze and fix any warnings introduced by new code
- [ ] T057 Verify offline functionality - reimbursement status changes persist locally and sync when online

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001-T005) completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational (T006-T013) completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (US1 → US2 → US3)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1) - Deletion Confirmation**: Can start after Foundational - No dependencies on other stories (only needs ExpenseEntity and expense_provider)
- **User Story 2 (P1) - Income Display Fix**: Can start after Foundational - No dependencies on other stories (independent provider fix)
- **User Story 3 (P2) - Reimbursement Tracking**: Can start after Foundational - Integrates with US1 deletion dialog (shows warning for reimbursable) but US3 can be implemented and tested independently

### Within Each User Story

- **US1**: Dialog widget can be built in parallel with provider updates (T014-T015 parallel, then T016-T019 sequential)
- **US2**: Provider updates (T020-T023) must be sequential, StaleDataBanner (T024-T026) can be parallel
- **US3**: Calculator updates (T027-T030) before providers (T038-T043), widgets (T031-T034) and forms (T035-T037) can be parallel, filtering (T044-T046) can be parallel

### Parallel Opportunities

- **Setup Phase**: T003 (enum) and T004 (Drift table) can run in parallel after T002 (migration)
- **Foundational Phase**: T010 (ExpenseModel), T011-T013 (BudgetStatsEntity and ReimbursementSummaryEntity) can all run in parallel after T006-T009 (ExpenseEntity) complete
- **US1**: T014-T015 (dialog widget) can run in parallel with each other
- **US2**: T024-T025 (StaleDataBanner) can run in parallel with T020-T023 (provider fixes) after Foundational
- **US3**: T031-T034 (all widgets) can run in parallel, T035-T037 (form updates) can run in parallel after widgets, T044-T046 (filtering) can run in parallel after provider updates

---

## Parallel Example: User Story 3 Widgets

```bash
# Launch all reimbursement widgets together after Foundational phase:
Task: "Create ReimbursementStatusBadge in lib/shared/widgets/reimbursement_status_badge.dart"
Task: "Update expense_list_item.dart to display badge"
Task: "Create reimbursement_status_change_dialog.dart"
Task: "Create reimbursement_toggle.dart widget"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

**Rationale**: Both US1 and US2 are Priority P1 and address critical issues (data loss prevention and broken functionality). Implementing both together provides maximum immediate value.

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T013) - CRITICAL
3. Complete Phase 3: User Story 1 (T014-T019) - Deletion confirmation
4. Complete Phase 4: User Story 2 (T020-T026) - Income display fix
5. **STOP and VALIDATE**: Test both US1 and US2 independently
6. Deploy/demo MVP with both critical fixes

### Incremental Delivery

1. **Foundation** (Phases 1-2): Setup + Foundational → T001-T013 complete
2. **MVP Release** (Phase 3-4): US1 + US2 → T014-T026 complete → Deploy critical fixes
3. **Enhancement Release** (Phase 5): US3 → T027-T048 complete → Deploy reimbursement tracking
4. **Polish Release** (Phase 6): T049-T057 complete → Final optimizations

### Parallel Team Strategy

With 2 developers after Foundational phase:

1. Team completes Setup + Foundational together (T001-T013)
2. Once Foundational is done:
   - Developer A: User Story 1 (T014-T019) - 6 tasks
   - Developer B: User Story 2 (T020-T026) - 7 tasks
3. Both join for User Story 3:
   - Developer A: Calculator + Providers (T027-T043)
   - Developer B: Widgets + Forms + Filtering (T031-T046)
4. Both work on Polish together (T049-T057)

---

## Task Count Summary

- **Total Tasks**: 57
- **Setup (Phase 1)**: 5 tasks
- **Foundational (Phase 2)**: 8 tasks (BLOCKING)
- **User Story 1 (P1)**: 6 tasks
- **User Story 2 (P1)**: 7 tasks
- **User Story 3 (P2)**: 22 tasks
- **Polish (Phase 6)**: 9 tasks

**Parallel Opportunities Identified**: 18 tasks marked with [P] can run in parallel with other tasks in their phase

**MVP Scope** (Recommended): Setup + Foundational + US1 + US2 = 26 tasks total
**Full Feature**: All 57 tasks

---

## Notes

- [P] tasks = different files, no dependencies within phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group (e.g., after completing all widgets for US3)
- Stop at any checkpoint to validate story independently before proceeding
- Foundational phase (T006-T013) is CRITICAL - must complete before any user story work
- Priority P1 stories (US1, US2) should be completed before P2 story (US3) for maximum value delivery
- All file paths are absolute and verified against plan.md structure
