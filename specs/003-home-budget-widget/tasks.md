# Tasks: Home Screen Budget Widget

**Input**: Design documents from `/specs/003-home-budget-widget/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are NOT explicitly requested in the specification. This task list focuses on implementation only.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/` at repository root
- **Android native**: `android/app/src/main/kotlin/` and `android/app/src/main/res/`
- **iOS native**: `ios/BudgetWidgetExtension/`
- All paths are relative to repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add widget dependencies and basic project structure

- [X] T001 Add home_widget ^0.6.0 dependency to pubspec.yaml
- [X] T002 Run flutter pub get to install dependencies
- [X] T003 [P] Create lib/features/widget directory structure (data/, domain/, presentation/)
- [X] T004 [P] Create android/app/src/main/kotlin/com/family/expense_tracker/widget/ directory
- [X] T005 [P] Create ios/BudgetWidgetExtension/ directory structure (if not exists from Xcode)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core widget infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Flutter Foundation

- [X] T006 Create WidgetDataEntity in lib/features/widget/domain/entities/widget_data_entity.dart
- [X] T007 [P] Create WidgetConfigEntity in lib/features/widget/domain/entities/widget_config_entity.dart
- [X] T008 Create WidgetDataModel in lib/features/widget/data/models/widget_data_model.dart
- [X] T009 [P] Create WidgetConfigModel in lib/features/widget/data/models/widget_config_model.dart
- [X] T010 Create WidgetRepository interface in lib/features/widget/domain/repositories/widget_repository.dart
- [X] T011 Create WidgetLocalDataSource interface in lib/features/widget/data/datasources/widget_local_datasource.dart
- [X] T012 Implement WidgetLocalDataSourceImpl in lib/features/widget/data/datasources/widget_local_datasource_impl.dart
- [X] T013 Implement WidgetRepositoryImpl in lib/features/widget/data/repositories/widget_repository_impl.dart
- [X] T014 Create WidgetProvider (Riverpod) in lib/features/widget/presentation/providers/widget_provider.dart
- [X] T015 Create WidgetUpdateService in lib/features/widget/presentation/services/widget_update_service.dart

### Android Foundation

- [X] T016 Create BudgetWidgetProvider.kt in android/app/src/main/kotlin/com/family/expense_tracker/widget/
- [X] T017 [P] Create widget_budget_small.xml layout in android/app/src/main/res/layout/
- [X] T018 [P] Create widget_budget_medium.xml layout in android/app/src/main/res/layout/
- [X] T019 [P] Create widget_budget_large.xml layout in android/app/src/main/res/layout/
- [X] T020 [P] Create widget_background.xml drawable in android/app/src/main/res/drawable/
- [X] T021 [P] Define widget colors in android/app/src/main/res/values/colors.xml (light theme)
- [X] T022 [P] Define dark theme colors in android/app/src/main/res/values-night/colors.xml
- [X] T023 Create budget_widget_info.xml in android/app/src/main/res/xml/
- [X] T024 Register BudgetWidgetProvider in android/app/src/main/AndroidManifest.xml
- [X] T025 Add deep link intent filters in android/app/src/main/AndroidManifest.xml

### iOS Foundation

- [ ] T026 Open ios/Runner.xcworkspace in Xcode and add Widget Extension target named BudgetWidgetExtension
- [ ] T027 Configure App Groups capability for Runner target (group.com.family.financetracker)
- [ ] T028 Configure App Groups capability for BudgetWidgetExtension target (same group ID)
- [X] T029 Create BudgetWidget.swift in ios/BudgetWidgetExtension/
- [X] T030 [P] Create BudgetWidgetView.swift in ios/BudgetWidgetExtension/
- [X] T031 [P] Create BudgetProvider.swift (TimelineProvider) in ios/BudgetWidgetExtension/
- [ ] T032 [P] Add CFBundleURLTypes for deep linking in ios/Runner/Info.plist
- [ ] T033 [P] Enable FlutterDeepLinkingEnabled in ios/Runner/Info.plist

### Deep Linking Setup

- [X] T034 Configure go_router with deep link routes (/dashboard, /scan-receipt, /add-expense) in lib/app/routes.dart
- [X] T035 Create DeepLinkHandler service in lib/features/widget/presentation/services/deep_link_handler.dart
- [X] T036 Integrate deep link handling in lib/app/app.dart (getInitialLink and uriLinkStream)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - At-a-Glance Budget Monitoring (Priority: P1) 🎯 MVP

**Goal**: Display current monthly budget on home screen widget with spent/limit, percentage, progress bar, and tap-to-dashboard. Users can see budget status without opening the app.

**Independent Test**: Install widget on home screen and verify it shows current budget with format "€450 / €800 (56%)" and progress bar. Tap widget should open app to Dashboard. Add expense in app and verify widget updates within 30 seconds.

### Implementation for User Story 1

#### Flutter Implementation

- [X] T037 [P] [US1] Implement getWidgetData() method in WidgetRepositoryImpl to fetch budget stats from DashboardRepository
- [X] T038 [P] [US1] Implement saveWidgetData() method in WidgetRepositoryImpl to persist data via home_widget plugin
- [X] T039 [P] [US1] Implement updateWidget() method in WidgetRepositoryImpl to trigger native widget refresh
- [X] T040 [US1] Add triggerUpdate() method in WidgetUpdateService that orchestrates fetch → save → update flow
- [X] T041 [US1] Integrate widget update trigger in ExpenseProvider.createExpense() in lib/features/expenses/presentation/providers/expense_provider.dart
- [X] T042 [P] [US1] Integrate widget update trigger in ExpenseProvider.updateExpense()
- [X] T043 [P] [US1] Integrate widget update trigger in ExpenseProvider.deleteExpense()

#### Android Widget Implementation

- [X] T044 [US1] Implement onUpdate() in BudgetWidgetProvider.kt to read SharedPreferences data
- [X] T045 [US1] Implement widget size detection in BudgetWidgetProvider.kt (small/medium/large)
- [X] T046 [US1] Implement updateWidget() method to populate RemoteViews with budget data
- [X] T047 [US1] Implement theme detection and color application in BudgetWidgetProvider.kt
- [X] T048 [US1] Add PendingIntent for budget container tap → dashboard deep link
- [X] T049 [US1] Implement progress bar color logic based on percentage (green <80%, orange 80-99%, red >=100%)
- [X] T050 [US1] Add staleness indicator logic (show "Aggiornato X min fa" if lastUpdated >5 min)

#### iOS Widget Implementation

- [X] T051 [US1] Implement BudgetProvider.loadData() to read from App Group UserDefaults
- [X] T052 [US1] Implement BudgetProvider.getTimeline() to generate 24-hour timeline entries
- [X] T053 [US1] Implement BudgetWidgetView with budget display (spent/limit/percentage)
- [X] T054 [US1] Add ProgressView with dynamic color based on percentage
- [X] T055 [US1] Add Link wrapper for budget section → dashboard deep link
- [X] T056 [US1] Implement theme adaptation using @Environment(\.colorScheme)

#### iOS App Group Data Sync

- [ ] T057 [US1] Create MethodChannel handler in ios/Runner/AppDelegate.swift for saveWidgetData
- [ ] T058 [US1] Implement UserDefaults write to App Group suite in AppDelegate.swift

**Checkpoint**: At this point, User Story 1 should be fully functional - widget displays budget, updates after expense changes, and opens to dashboard on tap

---

## Phase 4: User Story 2 - Quick Expense Entry from Home Screen (Priority: P2)

**Goal**: Two buttons on widget ("Scansiona" and "Manuale") that open app directly to scanner camera or manual expense form, bypassing normal navigation flow. Reduces friction from 5-6 taps to 1-2 taps.

**Independent Test**: From widget, tap "Scansiona" button and verify app opens directly to camera scanner screen. Tap "Manuale" button and verify app opens directly to manual expense form. Verify both work when app is not running (cold start <2s) and when app is in background.

### Implementation for User Story 2

#### Android Button Implementation

- [X] T059 [P] [US2] Add "Scansiona" button to widget layouts (small/medium/large) in android/app/src/main/res/layout/
- [X] T060 [P] [US2] Add "Manuale" button to widget layouts (small/medium/large)
- [X] T061 [US2] Implement createDeepLinkIntent() helper in BudgetWidgetProvider.kt for PendingIntent creation
- [X] T062 [US2] Set PendingIntent for "Scansiona" button → /scan-receipt deep link
- [X] T063 [US2] Set PendingIntent for "Manuale" button → /add-expense deep link
- [X] T064 [US2] Configure button styling and icons (camera icon for Scansiona, pencil for Manuale)

#### iOS Button Implementation

- [X] T065 [P] [US2] Add "Scansiona" button Link in BudgetWidgetView.swift → /scan-receipt deep link
- [X] T066 [P] [US2] Add "Manuale" button Link in BudgetWidgetView.swift → /add-expense deep link
- [X] T067 [US2] Style buttons with SF Symbols icons (camera.fill, square.and.pencil)
- [X] T068 [US2] Implement button layout for different widget sizes (hide buttons in small widget per spec)

#### Deep Link Route Handlers

- [X] T069 [US2] Verify /scan-receipt route opens CameraScreen in lib/app/routes.dart
- [X] T070 [US2] Verify /add-expense route opens ManualExpenseScreen in lib/app/routes.dart
- [ ] T071 [US2] Test cold start deep link handling (app not running)
- [ ] T072 [US2] Test warm start deep link handling (app in background)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - widget shows budget AND provides quick access buttons

---

## Phase 5: User Story 3 - Responsive Widget Sizes and Themes (Priority: P3)

**Goal**: Widget supports 3 sizes (small, medium, large) with adaptive layouts, and automatically respects system light/dark theme without requiring manual configuration.

**Independent Test**: Add widget in small size and verify compact layout with budget + percentage only (no buttons). Add in medium size and verify full layout with buttons. Add in large size and verify extended layout. Change system theme from light to dark and verify widget updates colors automatically.

### Implementation for User Story 3

#### Size-Specific Layouts

- [X] T073 [P] [US3] Finalize small widget layout (budget + percentage, no buttons) in widget_budget_small.xml
- [X] T074 [P] [US3] Finalize medium widget layout (full budget + 2 buttons) in widget_budget_medium.xml
- [X] T075 [P] [US3] Finalize large widget layout (extended budget + large buttons) in widget_budget_large.xml
- [X] T076 [US3] Implement size-responsive layout selection in BudgetWidgetProvider.kt based on AppWidgetManager options

#### iOS Size Variants

- [X] T077 [P] [US3] Create SmallWidgetView variant in ios/BudgetWidgetExtension/BudgetWidgetView.swift
- [X] T078 [P] [US3] Create MediumWidgetView variant (existing implementation)
- [X] T079 [P] [US3] Create LargeWidgetView variant
- [X] T080 [US3] Add size switch logic in BudgetWidgetView based on @Environment(\.widgetFamily)
- [X] T081 [US3] Update supportedFamilies in BudgetWidget to include .systemSmall, .systemMedium, .systemLarge

#### Theme Adaptation

- [X] T082 [P] [US3] Implement isDarkMode detection in Flutter using PlatformDispatcher.platformBrightness
- [X] T083 [US3] Pass isDarkMode state to native widgets via home_widget plugin
- [X] T084 [US3] Apply theme colors dynamically in BudgetWidgetProvider.kt based on isDarkMode flag
- [X] T085 [US3] Verify automatic theme switching in iOS using @Environment(\.colorScheme)
- [ ] T086 [US3] Test widget appearance in both light and dark themes on both platforms

**Checkpoint**: All user stories should now be independently functional - complete widget with sizes and themes

---

## Phase 6: Background Refresh & Polish

**Purpose**: Add background refresh and final polish across all user stories

### Android Background Refresh

- [X] T087 Create WidgetUpdateWorker.kt in android/app/src/main/kotlin/com/family/expense_tracker/widget/
- [X] T088 Implement doWork() in WidgetUpdateWorker to trigger widget update broadcast
- [X] T089 Configure WorkManager periodic update (15-minute interval) in Flutter app initialization
- [ ] T090 Add WorkManager dependency to android/app/build.gradle
- [ ] T091 Register WidgetUpdateWorker retry logic with exponential backoff

### iOS Background Refresh

- [X] T092 Verify timeline refresh policy is set to .atEnd in BudgetProvider.getTimeline()
- [ ] T093 Test iOS widget timeline reload when app updates data
- [ ] T094 Configure background refresh permissions in ios/Runner/Info.plist (if needed)

### Error States & Edge Cases

- [X] T095 [P] Implement "Budget non configurato" state in BudgetWidgetProvider.kt (when SharedPreferences data missing)
- [ ] T096 [P] Implement "Accedi per visualizzare budget" state for logged-out users
- [X] T097 [P] Implement "Dati non aggiornati" indicator for offline/stale data
- [ ] T098 [P] Add equivalent error states in iOS BudgetWidgetView.swift
- [X] T099 Implement budget exceeded state (>100%) with red color indicator

### Polish & Validation

- [ ] T100 [P] Test widget installation on physical Android device
- [ ] T101 [P] Test widget installation on physical iOS device
- [ ] T102 [P] Verify widget updates after expense add/edit/delete on both platforms
- [ ] T103 [P] Verify deep links work on both platforms (cold/warm start)
- [ ] T104 [P] Verify theme switching works automatically
- [ ] T105 [P] Verify all 3 widget sizes render correctly
- [ ] T106 Run quickstart.md validation steps on both platforms
- [ ] T107 [P] Verify widget performance (<1s render, <5MB RAM)
- [ ] T108 [P] Test widget behavior across month boundary (counter resets)
- [ ] T109 [P] Test widget behavior when switching family groups

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Foundational - No dependencies on other stories
  - User Story 2 (P2): Can start after Foundational - Requires US1 widget foundation but adds independent functionality
  - User Story 3 (P3): Can start after Foundational - Builds on US1/US2 layouts but independently testable
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Uses widget layouts from US1 but adds independent button functionality
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Extends layouts from US1/US2 but sizes/themes are independent features

**Recommended Order**: Sequential (P1 → P2 → P3) for MVP-first approach, but parallel execution possible after Phase 2

### Within Each User Story

- Flutter implementation before native implementations
- Models before repositories before services
- Layout files can be created in parallel
- Deep link configuration before button implementation
- Core functionality before edge cases

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational models/views marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes:
  - Different developers can work on US1, US2, US3 in parallel
  - Android and iOS implementations within a story can proceed in parallel
  - Layout files within a story can be created in parallel
- All Polish tasks marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Flutter data models can be created together:
Task: "T006 Create WidgetDataEntity in lib/features/widget/domain/entities/widget_data_entity.dart"
Task: "T007 [P] Create WidgetConfigEntity in lib/features/widget/domain/entities/widget_config_entity.dart"
Task: "T008 Create WidgetDataModel in lib/features/widget/data/models/widget_data_model.dart"
Task: "T009 [P] Create WidgetConfigModel in lib/features/widget/data/models/widget_config_model.dart"

# Android layouts can be created together:
Task: "T017 [P] Create widget_budget_small.xml layout in android/app/src/main/res/layout/"
Task: "T018 [P] Create widget_budget_medium.xml layout in android/app/src/main/res/layout/"
Task: "T019 [P] Create widget_budget_large.xml layout in android/app/src/main/res/layout/"

# US1 widget update triggers can be done together:
Task: "T041 [US1] Integrate widget update trigger in ExpenseProvider.createExpense()"
Task: "T042 [P] [US1] Integrate widget update trigger in ExpenseProvider.updateExpense()"
Task: "T043 [P] [US1] Integrate widget update trigger in ExpenseProvider.deleteExpense()"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Budget display + tap to dashboard)
4. **STOP and VALIDATE**: Test widget shows budget correctly, updates on expense changes, opens to dashboard
5. Deploy/demo MVP with essential budget monitoring feature

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (widget infrastructure in place)
2. Add User Story 1 → Test independently → Deploy/Demo (MVP - budget display!)
3. Add User Story 2 → Test independently → Deploy/Demo (MVP + quick access buttons)
4. Add User Story 3 → Test independently → Deploy/Demo (Full feature with sizes/themes)
5. Add Polish (Phase 6) → Final validation → Production release

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (budget display)
   - Developer B: User Story 2 (quick access buttons) - can start in parallel if A completes layouts
   - Developer C: User Story 3 (sizes/themes) - can start in parallel if A/B complete layouts
3. Or: One developer on Flutter, one on Android native, one on iOS native (cross-cutting parallelization)
4. Stories complete and integrate independently

---

## Summary

**Total Tasks**: 109
**User Story Distribution**:
- Setup: 5 tasks
- Foundational: 31 tasks (BLOCKING)
- User Story 1 (P1): 22 tasks - Budget display & tap to dashboard (MVP)
- User Story 2 (P2): 14 tasks - Quick access buttons
- User Story 3 (P3): 14 tasks - Sizes & themes
- Polish: 23 tasks - Background refresh, error states, validation

**Parallel Opportunities**: 45 tasks marked [P] can run in parallel within their phases

**Independent Test Criteria**:
- US1: Widget shows budget, updates after expense changes, opens to dashboard
- US2: Buttons open to scanner/manual form directly
- US3: Widget adapts to 3 sizes and auto-switches themes

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1) = 58 tasks for core budget monitoring widget

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Android and iOS implementations can proceed in parallel once Flutter foundation is ready
- Focus on US1 first for MVP, then incrementally add US2 and US3
