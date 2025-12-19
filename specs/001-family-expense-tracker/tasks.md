# Tasks: Family Expense Tracker

**Input**: Design documents from `/specs/001-family-expense-tracker/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Not explicitly requested - tests omitted. Add test tasks if TDD approach is desired.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This project uses Flutter feature-first architecture:
- **App core**: `lib/core/`, `lib/app/`, `lib/shared/`
- **Features**: `lib/features/{feature}/data|domain|presentation/`
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`
- **Backend**: `supabase/migrations/`, `supabase/functions/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Flutter project initialization, dependencies, and core configuration

- [X] T001 Create Flutter project with `flutter create --org com.example family_expense_tracker`
- [X] T002 Configure pubspec.yaml with all dependencies from research.md (supabase_flutter, flutter_riverpod, drift, fl_chart, camera, image_picker, etc.)
- [X] T003 [P] Create lib/core/config/env.dart with Supabase URL and anon key placeholders
- [X] T004 [P] Create lib/core/config/constants.dart with app constants (categories enum, validation rules)
- [X] T005 [P] Create lib/core/errors/exceptions.dart with custom exception classes
- [X] T006 [P] Create lib/core/errors/failures.dart with failure classes for error handling
- [X] T007 Create lib/main.dart with Supabase initialization and ProviderScope
- [X] T008 Create lib/app/app.dart with MaterialApp configuration and Italian localization
- [X] T009 Create lib/app/routes.dart with GoRouter configuration for all screens

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database setup, Supabase configuration, and shared services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T010 Create supabase/migrations/001_initial_schema.sql with profiles, family_groups, expenses, invites tables from data-model.md
- [X] T011 Create supabase/migrations/002_rls_policies.sql with Row Level Security policies from data-model.md
- [X] T012 [P] Create lib/shared/services/supabase_client.dart with singleton Supabase client wrapper
- [X] T013 [P] Create lib/shared/services/secure_storage_service.dart for token persistence using flutter_secure_storage
- [X] T014 [P] Create lib/shared/widgets/loading_indicator.dart with reusable loading widget
- [X] T015 [P] Create lib/shared/widgets/error_display.dart with reusable error display widget
- [X] T016 [P] Create lib/shared/widgets/custom_text_field.dart with styled input field
- [X] T017 [P] Create lib/shared/widgets/primary_button.dart with styled action button
- [X] T018 Create lib/core/utils/validators.dart with email, password, amount validation helpers
- [X] T019 Create lib/core/utils/date_formatter.dart with Italian date formatting utilities

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Account Registration and Login (Priority: P1) 🎯 MVP

**Goal**: Users can register with email/password, login, logout, and reset password

**Independent Test**: Register a new account, logout, login again, request password reset - all without needing groups or expenses

### Domain Layer (US1)

- [X] T020 [P] [US1] Create lib/features/auth/domain/entities/user_entity.dart with User entity class
- [X] T021 [P] [US1] Create lib/features/auth/domain/repositories/auth_repository.dart abstract interface

### Data Layer (US1)

- [X] T022 [US1] Create lib/features/auth/data/datasources/auth_remote_datasource.dart with Supabase Auth calls (signUp, signIn, signOut, resetPassword)
- [X] T023 [US1] Create lib/features/auth/data/repositories/auth_repository_impl.dart implementing auth_repository.dart
- [X] T024 [US1] Create lib/features/auth/data/models/user_model.dart with JSON serialization for profiles table

### Presentation Layer (US1)

- [X] T025 [US1] Create lib/features/auth/presentation/providers/auth_provider.dart with Riverpod StateNotifier for auth state
- [X] T026 [P] [US1] Create lib/features/auth/presentation/screens/login_screen.dart with email/password form and login button
- [X] T027 [P] [US1] Create lib/features/auth/presentation/screens/register_screen.dart with email/password/name form and register button
- [X] T028 [P] [US1] Create lib/features/auth/presentation/screens/forgot_password_screen.dart with email form and reset button
- [X] T029 [US1] Create lib/features/auth/presentation/screens/home_screen.dart placeholder with logout button (redirects based on group membership)
- [X] T030 [US1] Update lib/app/routes.dart with auth flow guards (redirect to login if not authenticated)

**Checkpoint**: User Story 1 complete - users can register, login, logout, reset password

---

## Phase 4: User Story 2 - Family Group Management (Priority: P2)

**Goal**: Users can create groups, generate invite codes, join groups, view members, leave groups

**Independent Test**: Create a group, generate invite code, have second user join with code, both see each other as members

### Domain Layer (US2)

- [X] T031 [P] [US2] Create lib/features/groups/domain/entities/family_group_entity.dart with FamilyGroup entity class
- [X] T032 [P] [US2] Create lib/features/groups/domain/entities/invite_entity.dart with Invite entity class
- [X] T033 [P] [US2] Create lib/features/groups/domain/entities/member_entity.dart with GroupMember entity class
- [X] T034 [US2] Create lib/features/groups/domain/repositories/group_repository.dart abstract interface

### Data Layer (US2)

- [X] T035 [US2] Create lib/features/groups/data/datasources/group_remote_datasource.dart with Supabase DB calls (createGroup, getGroup, getMembers, leaveGroup)
- [X] T036 [US2] Create lib/features/groups/data/datasources/invite_remote_datasource.dart with Supabase DB calls (createInvite, validateInvite, useInvite)
- [X] T037 [US2] Create lib/features/groups/data/repositories/group_repository_impl.dart implementing group_repository.dart
- [X] T038 [P] [US2] Create lib/features/groups/data/models/family_group_model.dart with JSON serialization
- [X] T039 [P] [US2] Create lib/features/groups/data/models/invite_model.dart with JSON serialization
- [X] T040 [US2] Create lib/core/utils/invite_code_generator.dart with 6-char alphanumeric code generation (excluding 0/O/1/I/L)

### Presentation Layer (US2)

- [X] T041 [US2] Create lib/features/groups/presentation/providers/group_provider.dart with Riverpod StateNotifier for group state
- [X] T042 [P] [US2] Create lib/features/groups/presentation/screens/no_group_screen.dart with create group and join group options
- [X] T043 [P] [US2] Create lib/features/groups/presentation/screens/create_group_screen.dart with group name form
- [X] T044 [P] [US2] Create lib/features/groups/presentation/screens/join_group_screen.dart with invite code input
- [X] T045 [US2] Create lib/features/groups/presentation/screens/group_details_screen.dart with member list and admin actions
- [X] T046 [US2] Create lib/features/groups/presentation/widgets/invite_code_card.dart displaying shareable code with copy button
- [X] T047 [US2] Create lib/features/groups/presentation/widgets/member_list_item.dart with member name and role badge
- [X] T048 [US2] Update lib/features/auth/presentation/screens/home_screen.dart to route to no_group_screen or main app based on group_id

**Checkpoint**: User Story 2 complete - users can create/join groups, manage membership

---

## Phase 5: User Story 3 - Receipt Scanning with AI (Priority: P3)

**Goal**: Users can photograph receipts, AI extracts amount/date/merchant, users review and save expenses

**Independent Test**: Take receipt photo, verify extracted data appears, edit if needed, save expense, see it in expense list

### Backend (US3)

- [X] T049 [US3] Create supabase/functions/scan-receipt/index.ts Edge Function calling Google Cloud Vision API with Italian receipt parsing

### Domain Layer (US3)

- [X] T050 [P] [US3] Create lib/features/expenses/domain/entities/expense_entity.dart with Expense entity class including category enum
- [X] T051 [P] [US3] Create lib/features/scanner/domain/entities/scan_result_entity.dart with extracted amount, date, merchant, confidence
- [X] T052 [US3] Create lib/features/expenses/domain/repositories/expense_repository.dart abstract interface
- [X] T053 [US3] Create lib/features/scanner/domain/repositories/scanner_repository.dart abstract interface

### Data Layer (US3)

- [X] T054 [US3] Create lib/features/scanner/data/datasources/scanner_remote_datasource.dart calling scan-receipt Edge Function
- [X] T055 [US3] Create lib/features/scanner/data/repositories/scanner_repository_impl.dart implementing scanner_repository.dart
- [X] T056 [US3] Create lib/features/expenses/data/datasources/expense_remote_datasource.dart with Supabase DB calls (createExpense, getExpenses, updateExpense, deleteExpense)
- [X] T057 [US3] Create lib/features/expenses/data/repositories/expense_repository_impl.dart implementing expense_repository.dart
- [X] T058 [P] [US3] Create lib/features/expenses/data/models/expense_model.dart with JSON serialization
- [X] T059 [P] [US3] Create lib/features/scanner/data/models/scan_result_model.dart with JSON serialization
- [X] T060 [US3] Create lib/shared/services/camera_service.dart wrapping camera and image_picker packages
- [X] T061 [US3] Create lib/shared/services/image_compression_service.dart for resizing images before upload (max 1MB)

### Presentation Layer (US3)

- [X] T062 [US3] Create lib/features/scanner/presentation/providers/scanner_provider.dart with Riverpod StateNotifier for scan state
- [X] T063 [US3] Create lib/features/expenses/presentation/providers/expense_provider.dart with Riverpod StateNotifier for expense CRUD
- [X] T064 [US3] Create lib/features/scanner/presentation/screens/camera_screen.dart with camera preview and capture button
- [X] T065 [US3] Create lib/features/scanner/presentation/screens/review_scan_screen.dart showing extracted data with edit fields
- [X] T066 [P] [US3] Create lib/features/expenses/presentation/screens/manual_expense_screen.dart with full expense form (amount, date, merchant, category, notes)
- [X] T067 [US3] Create lib/features/expenses/presentation/screens/expense_list_screen.dart showing user's expenses with edit/delete actions
- [X] T068 [P] [US3] Create lib/features/expenses/presentation/widgets/expense_list_item.dart with amount, merchant, date, category display
- [X] T069 [P] [US3] Create lib/features/expenses/presentation/widgets/category_selector.dart with category icons and Italian labels
- [X] T070 [US3] Create lib/features/expenses/presentation/screens/expense_detail_screen.dart showing full expense with receipt image

**Checkpoint**: User Story 3 complete - users can scan receipts, review AI extraction, save expenses

---

## Phase 6: User Story 4 - Personal and Group Dashboard (Priority: P4)

**Goal**: Users view personal and group expense summaries with charts, filter by time period and member

**Independent Test**: Add expenses, view dashboard showing totals, filter by week/month/year, view category breakdown chart

### Backend (US4)

- [X] T071 [US4] Create supabase/functions/dashboard-stats/index.ts Edge Function with aggregated expense statistics by period

### Domain Layer (US4)

- [X] T072 [P] [US4] Create lib/features/dashboard/domain/entities/dashboard_stats_entity.dart with totals, by_category, by_member, trend data
- [X] T073 [US4] Create lib/features/dashboard/domain/repositories/dashboard_repository.dart abstract interface

### Data Layer (US4)

- [X] T074 [US4] Create lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart calling dashboard-stats Edge Function
- [X] T075 [US4] Create lib/features/dashboard/data/repositories/dashboard_repository_impl.dart implementing dashboard_repository.dart
- [X] T076 [US4] Create lib/features/dashboard/data/models/dashboard_stats_model.dart with JSON serialization
- [X] T077 [US4] Create lib/features/dashboard/data/datasources/dashboard_local_datasource.dart with Hive cache for quick loading

### Presentation Layer (US4)

- [X] T078 [US4] Create lib/features/dashboard/presentation/providers/dashboard_provider.dart with Riverpod StateNotifier for dashboard state
- [X] T079 [US4] Create lib/features/dashboard/presentation/screens/dashboard_screen.dart with tabs for personal/group views
- [X] T080 [P] [US4] Create lib/features/dashboard/presentation/widgets/period_selector.dart with week/month/year toggle
- [X] T081 [P] [US4] Create lib/features/dashboard/presentation/widgets/member_filter.dart dropdown for filtering by group member
- [X] T082 [US4] Create lib/features/dashboard/presentation/widgets/total_summary_card.dart with total amount and expense count
- [X] T083 [US4] Create lib/features/dashboard/presentation/widgets/category_pie_chart.dart using fl_chart for category breakdown
- [X] T084 [US4] Create lib/features/dashboard/presentation/widgets/trend_bar_chart.dart using fl_chart for daily/weekly trend
- [X] T085 [US4] Create lib/features/dashboard/presentation/widgets/member_breakdown_list.dart showing each member's contribution

**Checkpoint**: User Story 4 complete - full dashboard with personal/group views, filters, and charts

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final integration, navigation, and refinements across all stories

- [X] T086 Create lib/features/auth/presentation/screens/main_navigation_screen.dart with bottom navigation (Dashboard, Expenses, Scanner, Group, Profile)
- [X] T087 Update lib/app/routes.dart with complete navigation flow and deep linking
- [X] T088 [P] Create lib/features/auth/presentation/screens/profile_screen.dart with display name edit, logout, delete account options
- [X] T089 [P] Implement account deletion flow in profile_screen.dart with name anonymization choice (FR-021)
- [X] T090 Add Supabase Storage bucket 'receipts' configuration with signed URL generation
- [X] T091 Add error handling and retry logic across all remote datasources
- [X] T092 Add loading states to all screens during async operations
- [X] T093 [P] Create Italian string resources in lib/core/config/strings_it.dart
- [ ] T094 Run flutter analyze and fix all linting issues (NOTE: Requires fixing exception constructor calls across datasources and repositories)
- [ ] T095 Run integration test scenarios from quickstart.md manually to verify all acceptance criteria

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (Auth) should complete first as other stories need authenticated users
  - US2-4 can proceed in parallel after US1
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - pure authentication
- **User Story 2 (P2)**: Requires US1 (users must be logged in to manage groups)
- **User Story 3 (P3)**: Requires US1 + US2 (expenses belong to groups)
- **User Story 4 (P4)**: Requires US1 + US2 + US3 (dashboard shows expenses)

### Parallel Opportunities

Within each phase, tasks marked [P] can run in parallel:
- Phase 1: T003, T004, T005, T006 can run in parallel
- Phase 2: T012, T013, T014, T015, T016, T017 can run in parallel
- US1: T020, T021 (domain) in parallel; T026, T027, T028 (screens) in parallel
- US2: T031, T032, T033 (entities) in parallel; T038, T039 (models) in parallel
- US3: T050, T051, T058, T059 in parallel; T066, T068, T069 in parallel
- US4: T072, T080, T081 in parallel

---

## Parallel Example: User Story 3

```bash
# Launch domain entities in parallel:
Task: "Create lib/features/expenses/domain/entities/expense_entity.dart"
Task: "Create lib/features/scanner/domain/entities/scan_result_entity.dart"

# Launch data models in parallel:
Task: "Create lib/features/expenses/data/models/expense_model.dart"
Task: "Create lib/features/scanner/data/models/scan_result_model.dart"

# Launch independent widgets in parallel:
Task: "Create lib/features/expenses/presentation/widgets/expense_list_item.dart"
Task: "Create lib/features/expenses/presentation/widgets/category_selector.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (Auth)
4. **STOP and VALIDATE**: Users can register/login
5. Deploy beta for auth testing

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add US1 (Auth) → Users can register/login ✅
3. Add US2 (Groups) → Users can form families ✅
4. Add US3 (Scanner) → Users can add expenses with AI ✅
5. Add US4 (Dashboard) → Users can view spending ✅
6. Each story adds value without breaking previous stories

### Suggested Implementation Order

1. **Week 1**: Phase 1 + Phase 2 (Setup + Foundation)
2. **Week 2**: Phase 3 (US1 - Auth) - MVP milestone
3. **Week 3**: Phase 4 (US2 - Groups)
4. **Week 4**: Phase 5 (US3 - Scanner) - Core feature
5. **Week 5**: Phase 6 (US4 - Dashboard)
6. **Week 6**: Phase 7 (Polish) + Testing

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All file paths use Flutter feature-first architecture from plan.md
