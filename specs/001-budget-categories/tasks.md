# Tasks: Budget Management and Category Customization

**Input**: Design documents from `/specs/001-budget-categories/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Feature Branch**: `001-budget-categories`
**Architecture**: Flutter 3.0+ mobile app with Clean Architecture (Domain/Data/Presentation)
**Backend**: Supabase PostgreSQL with Row Level Security
**State Management**: Riverpod 2.4.0

**Tests**: Not explicitly requested - implementation-focused approach

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- All paths relative to repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add new dependencies and initialize timezone support required by all user stories

- [X] T001 Add new dependencies to pubspec.yaml: flutter_timezone ^2.1.0, timezone ^0.9.2, wolt_modal_sheet ^0.6.0
- [X] T002 Initialize timezone support in lib/main.dart with flutter_timezone and set local timezone
- [X] T003 Create lib/core/utils/timezone_handler.dart for timezone-aware date operations
- [X] T004 Create lib/core/utils/budget_calculator.dart for budget math utilities

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database migrations and core data structures that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database Migrations

- [X] T005 Create supabase/migrations/010_add_is_group_expense_phase1.sql: Add nullable is_group_expense column to expenses table with default true
- [X] T006 Create supabase/migrations/011_create_group_budgets_table.sql: Create group_budgets table with RLS policies
- [X] T007 Create supabase/migrations/012_create_personal_budgets_table.sql: Create personal_budgets table with RLS policies
- [X] T008 Create supabase/migrations/013_create_expense_categories_table.sql: Create expense_categories table with RLS policies
- [X] T009 Create supabase/migrations/014_seed_default_categories.sql: Insert default categories (Food, Utilities, Transport, Healthcare, Entertainment, Other) for all existing groups
- [X] T010 Create supabase/migrations/015_add_timezone_to_profiles.sql: Add timezone column to profiles table with default 'UTC'
- [X] T011 Run database migrations: Execute supabase db push to apply all migrations

### Core Data Models (Shared Across Stories)

- [X] T012 [P] Modify lib/features/expenses/domain/entities/expense_entity.dart: Add isGroupExpense boolean field with default true
- [X] T013 [P] Modify lib/features/expenses/data/models/expense_model.dart: Add isGroupExpense to JSON serialization with null-coalescing for backward compatibility
- [X] T014 [P] Create lib/features/budgets/domain/entities/group_budget_entity.dart for GroupBudget entity
- [X] T015 [P] Create lib/features/budgets/domain/entities/personal_budget_entity.dart for PersonalBudget entity
- [X] T016 [P] Create lib/features/budgets/domain/entities/budget_stats_entity.dart for BudgetStats calculation results
- [X] T017 [P] Create lib/features/categories/domain/entities/expense_category_entity.dart for ExpenseCategory entity

**Checkpoint**: Foundation ready - all migrations applied, core entities created. User story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Define Group Budget (Priority: P1) 🎯 MVP

**Goal**: Enable group administrators to set monthly budgets and track spending against them with visual indicators

**Independent Test**: Admin sets group budget → adds expenses → sees progress bar update → reaches 80% threshold → sees warning → exceeds budget → sees over-budget indicator

### Implementation for User Story 1

#### Data Layer

- [X] T018 [P] [US1] Create lib/features/budgets/data/models/group_budget_model.dart with JSON serialization
- [X] T019 [P] [US1] Create lib/features/budgets/data/models/budget_stats_model.dart with JSON serialization
- [X] T020 [US1] Create lib/features/budgets/domain/repositories/budget_repository.dart interface with setGroupBudget and getGroupBudgetStats methods
- [X] T021 [US1] Create lib/features/budgets/data/datasources/budget_remote_datasource.dart for Supabase operations
- [X] T022 [US1] Implement lib/features/budgets/data/repositories/budget_repository_impl.dart with error handling

#### Business Logic (Providers)

- [X] T023 [US1] Create lib/features/budgets/presentation/providers/budget_provider.dart: BudgetNotifier with state management for group budget stats
- [X] T024 [US1] Implement optimistic update logic in budget_provider.dart for expense add/edit/delete operations
- [X] T025 [US1] Implement Supabase Realtime subscription in budget_provider.dart for multi-device sync
- [X] T026 [US1] Create lib/features/budgets/presentation/providers/budget_actions_provider.dart for setGroupBudget action

#### UI Components

- [X] T027 [P] [US1] Create lib/features/budgets/presentation/widgets/budget_progress_bar.dart with percentage calculation and color coding
- [X] T028 [P] [US1] Create lib/features/budgets/presentation/widgets/budget_warning_indicator.dart for 80% threshold warning
- [X] T029 [P] [US1] Create lib/features/budgets/presentation/widgets/no_budget_set_card.dart with call-to-action button
- [X] T030 [US1] Create lib/features/budgets/presentation/screens/budget_settings_screen.dart with group budget section
- [X] T031 [US1] Add group budget card with progress indicators to lib/features/dashboard/presentation/screens/dashboard_screen.dart

#### Integration

- [X] T032 [US1] Enable Supabase Realtime on expenses table: ALTER PUBLICATION supabase_realtime ADD TABLE expenses
- [X] T033 [US1] Wire budget provider to expense creation flow in lib/features/expenses/presentation/providers/expense_provider.dart
- [X] T034 [US1] Add navigation from dashboard to budget settings screen

**Checkpoint**: At this point, group administrators can set budgets, see progress bars on dashboard, and receive warnings. This is a complete MVP feature.

---

## Phase 4: User Story 2 - Define Personal Budget (Priority: P2)

**Goal**: Enable individual users to set personal monthly budgets and track their own spending (personal + their share of group expenses)

**Independent Test**: User sets personal budget → adds personal expense → sees only personal budget affected → adds group expense → sees both budgets affected

### Implementation for User Story 2

#### Data Layer

- [X] T035 [P] [US2] Create lib/features/budgets/data/models/personal_budget_model.dart with JSON serialization
- [X] T036 [US2] Add setPersonalBudget and getPersonalBudgetStats methods to lib/features/budgets/domain/repositories/budget_repository.dart
- [X] T037 [US2] Add personal budget operations to lib/features/budgets/data/datasources/budget_remote_datasource.dart
- [X] T038 [US2] Implement personal budget methods in lib/features/budgets/data/repositories/budget_repository_impl.dart

#### Business Logic (Providers)

- [X] T039 [US2] Add personal budget state and calculations to lib/features/budgets/presentation/providers/budget_provider.dart
- [X] T040 [US2] Implement personal budget optimistic updates (includes both personal and user's group expenses)
- [X] T041 [US2] Add setPersonalBudget action to lib/features/budgets/presentation/providers/budget_actions_provider.dart

#### UI Components

- [X] T042 [P] [US2] Add personal budget section to lib/features/budgets/presentation/screens/budget_settings_screen.dart
- [X] T043 [US2] Create personal dashboard card in lib/features/dashboard/presentation/screens/dashboard_screen.dart with personal budget indicators
- [X] T044 [US2] Add personal budget progress bar using existing budget_progress_bar.dart widget

**Checkpoint**: Users can now manage both group and personal budgets independently. Personal budgets track user's total spending (personal + group expenses).

---

## Phase 5: User Story 3 - Mark Expenses as Group or Personal (Priority: P3)

**Goal**: Enable users to classify expenses as group or personal, affecting visibility and budget allocation

**Independent Test**: User adds expense marked as personal → only visible in personal dashboard → changes to group → now visible to all members

### Implementation for User Story 3

#### Data Layer & Privacy

- [X] T045 [US3] Run supabase/migrations/017_add_dual_rls_policies.sql: Replace single SELECT policy with dual policies for group/personal expense privacy
- [X] T046 [US3] Add updateExpenseClassification method to lib/features/expenses/domain/repositories/expense_repository.dart
- [X] T047 [US3] Implement updateExpenseClassification in lib/features/expenses/data/repositories/expense_repository_impl.dart with RLS-compliant updates

#### UI Components

- [X] T048 [P] [US3] Create lib/features/expenses/presentation/widgets/expense_type_toggle.dart: SegmentedButton for Group/Personal selection
- [X] T049 [US3] Add expense_type_toggle to lib/features/expenses/presentation/screens/manual_expense_screen.dart with state management
- [X] T050 [US3] Add expense type indicator to lib/features/expenses/presentation/widgets/expense_list_item.dart (icon or label)
- [X] T051 [US3] Update expense form submission to include isGroupExpense field

#### Business Logic

- [X] T052 [US3] Add expense classification change handling to lib/features/budgets/presentation/providers/budget_provider.dart (recalculate budgets)
- [X] T053 [US3] Implement optimistic update and rollback for expense classification changes in budget provider

**Checkpoint**: Expenses can now be classified as group or personal. Personal expenses are private. Budget calculations respect classification.

---

## Phase 6: User Story 4 - Customize Expense Categories (Priority: P4)

**Goal**: Enable group administrators to add, edit, and delete custom expense categories with bulk reassignment UX

**Independent Test**: Admin creates "Pet care" category → assigns expenses → edits category name → deletes category with reassignment flow

### Implementation for User Story 4

#### Data Layer

- [ ] T054 [P] [US4] Create lib/features/categories/data/models/expense_category_model.dart with JSON serialization
- [ ] T055 [US4] Create lib/features/categories/domain/repositories/category_repository.dart with CRUD methods and batchUpdateExpenseCategory
- [ ] T056 [US4] Create lib/features/categories/data/datasources/category_remote_datasource.dart for Supabase operations
- [ ] T057 [US4] Implement lib/features/categories/data/repositories/category_repository_impl.dart with validation

#### Database Functions for Performance

- [ ] T058 [US4] Create supabase/migrations/017_batch_update_category_function.sql: PostgreSQL RPC function for batch expense reassignment (500+ expenses)
- [ ] T059 [US4] Create supabase/migrations/018_get_expense_count_by_category_function.sql: Function to count expenses per category

#### Business Logic (Providers)

- [ ] T060 [US4] Create lib/features/categories/presentation/providers/category_provider.dart: StateNotifier for category list management
- [ ] T061 [US4] Create lib/features/categories/presentation/providers/category_actions_provider.dart for create/update/delete actions
- [ ] T062 [US4] Add Supabase Realtime subscription for expense_categories table in category provider

#### UI Components - Category Management

- [ ] T063 [P] [US4] Create lib/features/categories/presentation/screens/category_management_screen.dart with category list
- [ ] T064 [P] [US4] Create lib/features/categories/presentation/widgets/category_list_item.dart with edit/delete actions (admin only)
- [ ] T065 [P] [US4] Create lib/features/categories/presentation/widgets/category_form_dialog.dart for create/edit
- [ ] T066 [US4] Add navigation to category management from settings screen

#### UI Components - Deletion Flow (Multi-Page Modal)

- [ ] T067 [US4] Create lib/features/categories/presentation/widgets/category_deletion_flow.dart: Impact preview page with affected expense count
- [ ] T068 [US4] Add quick reassignment page to category_deletion_flow.dart with category dropdown and "Auto to Other" option
- [ ] T069 [US4] Add manual reassignment page to category_deletion_flow.dart with batch selection and progress tracking (optional, can be future enhancement)
- [ ] T070 [US4] Integrate WoltModalSheet for multi-page deletion flow with smooth transitions

#### Integration

- [ ] T071 [US4] Update expense category selector in lib/features/expenses/presentation/screens/manual_expense_screen.dart to use dynamic category list from provider
- [ ] T072 [US4] Add real-time category updates to expense form (new categories appear immediately)

**Checkpoint**: Administrators can fully manage categories. Deletion handles bulk reassignment gracefully. All users see category changes in real-time.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final integration, performance optimization, and documentation

### Database Finalization

- [ ] T073 Deploy Phase 2 migration (NOT NULL constraint) after app rollout: Create supabase/migrations/019_add_is_group_expense_phase2.sql to add NOT NULL constraint to is_group_expense
- [ ] T074 Verify all RLS policies work correctly with manual testing: Test personal expense privacy across users

### Performance Optimization

- [ ] T075 [P] Add indexes for budget queries: Run EXPLAIN ANALYZE on budget stat queries and create additional indexes if needed
- [ ] T076 [P] Verify budget calculations complete in <500ms with 1000+ expenses per group
- [ ] T077 [P] Verify real-time updates deliver within 2s latency (SC-003) on 3G network simulation

### UI/UX Polish

- [ ] T078 [P] Add loading states to budget settings screen during save operations
- [ ] T079 [P] Add error handling and user-friendly error messages for budget operations
- [ ] T080 [P] Add loading states to category management screen
- [ ] T081 [P] Ensure all budget indicators have proper accessibility labels (Semantics widgets)
- [ ] T082 [P] Verify touch targets are minimum 44×44dp for all buttons (WCAG 2.1 AA compliance)

### Integration & Testing

- [ ] T083 Manual testing: Verify budget reset at midnight in different timezones using device timezone change
- [ ] T084 Manual testing: Verify category deletion with 100+ expenses completes in <1s (batch reassignment)
- [ ] T085 Manual testing: Verify personal expenses are completely hidden from other users including admins
- [ ] T086 Run app through quickstart.md scenarios and verify all work correctly

### Documentation

- [ ] T087 [P] Update README with new budget and category features (if user-facing)
- [ ] T088 [P] Create migration guide for users on old app versions (backward compatibility notes)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - **BLOCKS all user stories**
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - Can proceed in parallel with sufficient team capacity
  - Or sequentially in priority order: US1 → US2 → US3 → US4
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - **No dependencies on other stories**
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Shares budget infrastructure with US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Modifies expense behavior but independent feature
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - Completely independent category management

### Within Each User Story

- Data models before repositories
- Repositories before providers
- Providers before UI components
- Core implementation before integration
- Story complete and tested before moving to next priority

### Parallel Opportunities

**Setup (Phase 1):**
- All 4 tasks can run in parallel (different files)

**Foundational (Phase 2):**
- T005-T011 (migrations) must run sequentially in order
- T012-T017 (models) can all run in parallel after migrations complete

**User Story 1 (Phase 3):**
- T018-T019 (models) can run in parallel
- T027-T029 (widgets) can run in parallel after providers exist
- All tasks depend on Phase 2 completion

**User Story 2 (Phase 4):**
- T035 can run in parallel with T036-T038
- T042-T044 can run in parallel

**User Story 3 (Phase 5):**
- T048 can run in parallel with T046-T047

**User Story 4 (Phase 6):**
- T054 can run in parallel with T055-T057
- T063-T065 (UI components) can run in parallel after providers exist
- T067-T069 (deletion pages) can run in parallel

**Polish (Phase 7):**
- T075-T077 (performance) can run in parallel
- T078-T082 (UI polish) can run in parallel
- T087-T088 (documentation) can run in parallel

---

## Parallel Example: User Story 1

```bash
# After Foundational phase completes, these can launch together:

# Data models (different files):
Task T018: "Create group_budget_model.dart"
Task T019: "Create budget_stats_model.dart"

# UI widgets (different files):
Task T027: "Create budget_progress_bar.dart"
Task T028: "Create budget_warning_indicator.dart"
Task T029: "Create no_budget_set_card.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T017) - **CRITICAL**
3. Complete Phase 3: User Story 1 (T018-T034)
4. **STOP and VALIDATE**: Test group budget end-to-end
   - Admin sets budget
   - Add expenses and verify progress bar
   - Reach 80% and verify warning
   - Exceed budget and verify over-budget indicator
5. Deploy/demo MVP

**Result**: Fully functional group budget tracking with visual indicators

### Incremental Delivery

1. **Foundation**: Setup + Foundational (T001-T017) → Database ready
2. **MVP**: User Story 1 (T018-T034) → Group budgets working → **Deploy**
3. **Enhancement 1**: User Story 2 (T035-T044) → Personal budgets added → **Deploy**
4. **Enhancement 2**: User Story 3 (T045-T053) → Expense classification → **Deploy**
5. **Enhancement 3**: User Story 4 (T054-T072) → Category management → **Deploy**
6. **Polish**: Phase 7 (T073-T088) → Production-ready

### Parallel Team Strategy

With 3 developers after Foundational phase completes:

- **Developer A**: User Story 1 (Group budgets) - Priority P1
- **Developer B**: User Story 2 (Personal budgets) - Priority P2
- **Developer C**: User Story 4 (Categories) - Priority P4

**Rationale**: US1 and US4 are completely independent. US2 shares budget infrastructure with US1 but can be developed in parallel with careful coordination. US3 (expense classification) is small and can be picked up after US2 completes.

---

## Notes

### General Guidelines

- **[P] tasks**: Different files, no dependencies, can run in parallel
- **[Story] label**: Maps task to specific user story for traceability
- **File paths**: All relative to repository root (C:\Users\KreshOS\Documents\00-Progetti\Fin)
- **Commit frequency**: Commit after each task or logical group for rollback safety
- **Testing checkpoints**: Use checkpoint markers to validate story independence

### Architecture Compliance

- Follow Clean Architecture: Domain → Data → Presentation
- Use Riverpod for state management (existing pattern)
- Implement RLS at database level (security-first)
- Support offline viewing via optimistic updates + cache

### Performance Requirements (from spec.md)

- Budget stats calculation: <500ms (FR-003, FR-004)
- Real-time updates: <2s (SC-003, SC-005)
- Category deletion with 500 expenses: <1s (research.md)
- Budget settings workflow: <30s (SC-001, SC-002)

### Privacy Requirements (from spec.md)

- Personal expenses: Only visible to creator (FR-014)
- Admins: Cannot view/edit/delete personal expenses (Edge Cases)
- RLS enforcement: Database-level security (research.md)

### Migration Safety (from research.md)

- Phase 1 migration: Nullable column first (backward compatible)
- App rollout: Gradual with version tracking
- Phase 2 migration: Add NOT NULL only after >95% users updated (T073)
- Rollback plan: Keep backup and rollback scripts available

### Accessibility (WCAG 2.1 AA)

- Touch targets: Minimum 44×44dp (T082)
- Color contrast: 4.5:1 for text (budget indicators)
- Semantic labels: All buttons and indicators (T081)
- Focus management: Safe actions focused by default (cancel buttons)

---

**Total Tasks**: 88
**User Story Breakdown**:
- Setup: 4 tasks
- Foundational: 13 tasks (BLOCKS all stories)
- US1 (Group Budget): 17 tasks
- US2 (Personal Budget): 10 tasks
- US3 (Expense Classification): 9 tasks
- US4 (Category Management): 19 tasks
- Polish: 16 tasks

**Parallel Opportunities**: 30+ tasks can run in parallel (all marked [P])

**Suggested MVP**: Phase 1 + Phase 2 + Phase 3 (User Story 1) = 34 tasks

**Estimated MVP Timeline**:
- Setup: 1-2 hours
- Foundational: 1-2 days (migrations + core models)
- User Story 1: 3-4 days (full budget tracking with UI)
- **Total MVP**: ~5-6 days for single developer

---

## Version

- **Version**: 1.0.0
- **Created**: 2025-12-31
- **Status**: Ready for Implementation
- **Command**: Generated by `/speckit.tasks` from spec.md, plan.md, data-model.md, contracts/, research.md
