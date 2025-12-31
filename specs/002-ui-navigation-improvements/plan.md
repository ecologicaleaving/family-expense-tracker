# Implementation Plan: UI Navigation and Settings Reorganization

**Branch**: `002-ui-navigation-improvements` | **Date**: 2025-12-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-ui-navigation-improvements/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Reorganize the app's bottom navigation to consolidate settings, ensure consistent navigation bar access across all screens, and add a recent expenses widget to the Dashboard. The implementation will:
1. Replace 4-tab bottom navigation (Dashboard, Spese, Gruppo, Profilo) with 3-tab structure (Dashboard, Spese, Impostazioni)
2. Create a new Settings screen that provides access to Profile and Group management
3. Ensure bottom navigation persists across all app screens including deep navigation
4. Add a recent expenses list (5-10 items) to the Dashboard screen with tap navigation to details
5. Implement unsaved changes protection when navigating away from edit screens

## Technical Context

**Language/Version**: Dart 3.0.0+ (Flutter SDK)
**Primary Dependencies**: flutter_riverpod 2.4.0, go_router 12.0.0, supabase_flutter 2.0.0
**Storage**: Supabase (PostgreSQL) for remote data, Drift + Hive for local caching
**Testing**: flutter_test, integration_test, mockito
**Target Platform**: Mobile (iOS 15+, Android API 24+)
**Project Type**: Mobile app (Flutter)
**Performance Goals**: Navigation transitions <300ms, Dashboard data load <1s, smooth 60fps UI
**Constraints**: Preserve navigation state across tab switches, maintain offline capability
**Scale/Scope**: ~15-20 screens, 3 main navigation tabs, handling 100-1000 expenses per user

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: ✅ PASSED (No violations detected)

The project constitution template is not customized for this project. The feature implementation follows standard Flutter/Dart best practices:

- **Clean Architecture**: Existing codebase uses feature-based structure with data/domain/presentation layers
- **State Management**: Riverpod is consistently used for state management
- **Testing Strategy**: Unit, integration, and widget tests structure already in place
- **Code Quality**: Flutter lints configured, follows Material Design guidelines

No constitutional violations detected. The feature adds navigation reorganization without introducing architectural complexity or violating existing patterns.

## Project Structure

### Documentation (this feature)

```text
specs/002-ui-navigation-improvements/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── navigation-structure.md  # Navigation routes and state contracts
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── app.dart                    # Main app widget
│   ├── routes.dart                 # [MODIFY] Add settings routes, update navigation structure
│   └── app_theme.dart             # Existing theme configuration
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── main_navigation_screen.dart  # [MODIFY] Update to 3-tab structure
│   │           ├── profile_screen.dart          # [UNCHANGED] Keep existing
│   │           └── settings_screen.dart         # [NEW] Create settings hub screen
│   ├── dashboard/
│   │   ├── domain/
│   │   │   └── entities/
│   │       │   └── recent_expense_entity.dart   # [NEW] Recent expense summary entity
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── dashboard_remote_datasource.dart  # [MODIFY] Add recent expenses query
│   │   │   ├── models/
│   │   │   │   └── recent_expense_model.dart    # [NEW] Data model for recent expenses
│   │   │   └── repositories/
│   │   │       └── dashboard_repository_impl.dart # [MODIFY] Add recent expenses method
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── dashboard_provider.dart      # [MODIFY] Add recent expenses state
│   │       ├── screens/
│   │       │   └── dashboard_screen.dart        # [MODIFY] Add recent expenses widget
│   │       └── widgets/
│   │           ├── recent_expenses_list.dart    # [NEW] Recent expenses widget
│   │           └── recent_expense_item.dart     # [NEW] Individual expense item widget
│   ├── expenses/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── expense_detail_screen.dart   # [MODIFY] Add unsaved changes guard
│   │           └── manual_expense_screen.dart   # [MODIFY] Add unsaved changes guard
│   └── groups/
│       └── presentation/
│           └── screens/
│               └── group_details_screen.dart    # [UNCHANGED] Accessed via Settings
├── shared/
│   └── widgets/
│       ├── unsaved_changes_dialog.dart          # [NEW] Reusable confirmation dialog
│       └── navigation_guard.dart                # [NEW] Navigation guard mixin
└── core/
    └── navigation/
        └── navigation_state_manager.dart        # [NEW] Tab state preservation logic

test/
└── features/
    ├── auth/
    │   └── presentation/
    │       └── screens/
    │           └── settings_screen_test.dart    # [NEW] Settings screen tests
    └── dashboard/
        └── presentation/
            └── widgets/
                ├── recent_expenses_list_test.dart # [NEW] Widget tests
                └── recent_expense_item_test.dart  # [NEW] Widget tests
```

**Structure Decision**: Mobile app structure using Flutter's feature-based organization. The existing architecture follows Clean Architecture with domain/data/presentation separation. New navigation components will be added to `features/auth/presentation` (for Settings screen) and `features/dashboard/presentation` (for recent expenses). Shared navigation utilities go in `shared/widgets` and `core/navigation`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

N/A - No constitutional violations detected.

---

## Phase 0: Research & Technical Decisions

### Research Areas

The following technical decisions need research and documentation:

1. **Navigation State Preservation Strategy**
   - How to preserve tab state (scroll position, filters) when switching between bottom navigation tabs
   - go_router state management best practices
   - IndexedStack vs. Navigator-per-tab approaches

2. **Unsaved Changes Detection**
   - Form state tracking patterns in Flutter
   - WillPopScope/NavigationObserver integration with go_router
   - User-friendly dialog patterns

3. **Recent Expenses Data Fetching**
   - Optimal query strategy for fetching recent expenses from Supabase
   - Caching strategy to avoid redundant fetches
   - Real-time subscription vs. polling for updates

4. **Navigation Guard Implementation**
   - go_router redirect/listener hooks for unsaved changes
   - Mixins vs. wrapper widgets for reusability
   - Integration with Riverpod state

5. **Text Truncation Patterns**
   - Flutter Text overflow handling best practices
   - Ellipsis positioning for different text lengths
   - Responsive design for various screen sizes

### Research Output

See `research.md` for detailed findings and decisions.

---

## Phase 1: Design Artifacts

### Data Model

See `data-model.md` for:
- RecentExpenseEntity structure
- NavigationState entity
- UnsavedChangesState structure
- Relationships with existing entities (ExpenseEntity, User, Group)

### API Contracts

See `contracts/navigation-structure.md` for:
- Bottom navigation tab structure definition
- Settings screen navigation routes
- Recent expenses data contract
- Navigation state preservation interface

### Quickstart Guide

See `quickstart.md` for:
- Developer setup for navigation changes
- Testing the new navigation structure
- Verifying state preservation
- Testing unsaved changes guards

---

## Implementation Strategy

### Phase Overview

**Priority Order** (aligned with spec user stories):
1. **P1 - Settings Menu Consolidation**: Update bottom nav to 3 tabs, create Settings screen
2. **P2 - Consistent Navigation Access**: Ensure bottom nav visible on all screens, implement state preservation
3. **P3 - Recent Expenses on Dashboard**: Add recent expenses widget and navigation

### Key Implementation Steps

#### 1. Settings Menu Consolidation (P1)

**Files to Modify:**
- `lib/features/auth/presentation/screens/main_navigation_screen.dart`
  - Change from 4 tabs to 3 tabs
  - Remove Profile and Group from bottom navigation
  - Add Impostazioni (Settings) tab

**Files to Create:**
- `lib/features/auth/presentation/screens/settings_screen.dart`
  - Create settings hub with list tiles for Profile and Group
  - Use Material ListTile with navigation to existing screens

**Navigation Routes:**
- Update `lib/app/routes.dart` to add `/settings` route
- Ensure Profile and Group screens remain accessible via Settings

#### 2. Consistent Navigation Access (P2)

**State Preservation:**
- Implement `IndexedStack` pattern in `main_navigation_screen.dart` to preserve tab state
- Each tab maintains its own navigation stack

**Unsaved Changes Guard:**
- Create `lib/shared/widgets/unsaved_changes_dialog.dart` for reusable dialog
- Create `lib/shared/widgets/navigation_guard.dart` mixin for forms
- Apply to `manual_expense_screen.dart` and other edit screens

**Deep Navigation:**
- Verify bottom nav remains visible on all screens
- Test navigation from Settings → Profile → Edit Profile maintains bottom nav access

#### 3. Recent Expenses on Dashboard (P3)

**Data Layer:**
- Add `getRecentExpenses(limit: int)` method to `DashboardRepository`
- Implement in `DashboardRepositoryImpl` with Supabase query
- Create `RecentExpenseEntity` and `RecentExpenseModel`

**Presentation Layer:**
- Update `DashboardProvider` to load recent expenses
- Create `RecentExpensesList` widget for Dashboard
- Create `RecentExpenseItem` widget with tap navigation
- Handle deleted expense case with informative message

**UI Integration:**
- Add recent expenses section to `dashboard_screen.dart` above existing stats
- Include "Vedi tutte" button to navigate to full expense list
- Implement empty state when no expenses exist

### Testing Strategy

**Unit Tests:**
- Settings screen navigation logic
- Recent expenses data fetching
- Navigation guard state detection

**Widget Tests:**
- Settings screen UI rendering
- Recent expenses list rendering
- Text truncation with ellipsis
- Empty state display

**Integration Tests:**
- Full navigation flow: Dashboard → Settings → Profile
- Tab switching with state preservation
- Unsaved changes dialog trigger
- Recent expense tap navigation to detail screen
- Deleted expense handling

### Migration & Rollout

**Breaking Changes:**
- Bottom navigation structure changes (4 tabs → 3 tabs)
- Navigation routes updated (Profile/Group accessed via Settings)

**User Impact:**
- Existing users will see navigation structure change
- No data migration required
- Settings consolidation improves UX per spec goals

**Rollback Plan:**
- Feature can be rolled back by reverting navigation structure changes
- No database schema changes involved
- State management changes are isolated to navigation screens

### Performance Considerations

**Navigation Performance:**
- IndexedStack maintains widget tree, small memory overhead acceptable
- State preservation eliminates reload delays
- Tab switching should meet <300ms requirement

**Recent Expenses Query:**
- Limit to 10 items keeps query fast
- Consider caching with TTL (time-to-live) if performance issues arise
- Supabase RLS policies already in place for data security

**Memory Management:**
- Disposing controllers/subscriptions when tabs hidden
- Lazy loading Dashboard data only when tab visible
- Recent expenses list is small (5-10 items), minimal memory impact

---

## Risk Mitigation

### Technical Risks

1. **State Loss During Navigation**
   - **Risk**: Users lose scroll position/filters when switching tabs
   - **Mitigation**: Use IndexedStack pattern proven in Flutter apps
   - **Validation**: Integration tests verify state preservation

2. **go_router Compatibility**
   - **Risk**: go_router may not support nested navigation patterns needed
   - **Mitigation**: Research go_router best practices in Phase 0
   - **Fallback**: Use Navigator per tab if go_router limitations found

3. **Performance Degradation**
   - **Risk**: Keeping all tabs in memory might impact performance
   - **Mitigation**: Profile memory usage, dispose heavy widgets when not visible
   - **Validation**: Performance testing on low-end devices

### UX Risks

1. **User Confusion with Navigation Changes**
   - **Risk**: Users can't find Profile/Group in new Settings location
   - **Mitigation**: Use clear icons and labels in Settings screen
   - **Consider**: Add tooltip or first-launch hint as suggested in spec

2. **Deleted Expense Edge Case**
   - **Risk**: Tapping deleted expense causes poor UX
   - **Mitigation**: Implement informative message + auto-refresh per spec
   - **Validation**: Test concurrent deletion scenarios

---

## Dependencies & Assumptions

### External Dependencies

- **go_router 12.0.0**: Already in project, used for routing
- **flutter_riverpod 2.4.0**: Already in project, state management
- **supabase_flutter 2.0.0**: Already in project, backend queries

### Internal Dependencies

- Existing Profile screen must remain fully functional
- Existing Group screen must remain fully functional
- Expense repository must support query by date/limit
- Dashboard provider architecture supports adding recent expenses state

### Assumptions

- Current bottom navigation uses Material NavigationBar widget
- go_router supports the nested navigation pattern needed
- Recent expenses query performance is acceptable (<1s)
- Users understand standard bottom navigation patterns
- Italian language labels are final (no i18n changes needed for this iteration)

---

## Open Questions for Phase 0 Research

1. **go_router State Management**: What's the best pattern for preserving state across tab switches with go_router? Should we use ShellRoute or custom approach?

2. **Unsaved Changes with go_router**: How do we intercept navigation with go_router to show unsaved changes dialog? Is there a redirect/listener hook?

3. **Recent Expenses Caching**: Should we cache recent expenses data, and if so, what's the TTL and invalidation strategy?

4. **Navigation Guard Reusability**: Should we create a mixin, wrapper widget, or provider-based solution for unsaved changes detection?

5. **Deleted Expense Refresh**: After showing "expense deleted" message, should we just remove that item or reload the entire list?

---

## Success Metrics

Aligned with spec success criteria:

- **SC-001**: Settings, Profile, Group accessible in ≤2 taps from any screen
- **SC-002**: Tab switching works without using back navigation
- **SC-003**: Recent expenses visible within 1s of Dashboard load
- **SC-004**: Bottom nav visible on 100% of screens
- **SC-005**: Expense details accessible with 1 tap from recent expenses
- **SC-006**: Tab transitions complete in <300ms

**Acceptance Tests:**
- User can navigate from Dashboard → Settings → Profile and back via bottom nav
- Switching tabs preserves scroll position and filter state
- Creating expense and tapping bottom nav shows confirmation if unsaved changes exist
- Recent expenses list shows 5-10 items with truncated text and ellipsis
- Tapping deleted expense shows message and refreshes list

---

## Next Steps

After this plan is approved:

1. **Phase 0**: Execute research tasks and generate `research.md`
2. **Phase 1**: Create data models, contracts, and quickstart guide
3. **Phase 2**: Run `/speckit.tasks` to generate implementation task list
4. **Implementation**: Execute tasks from `tasks.md` in priority order

**This plan document stops here**. Phase 0 and Phase 1 artifacts follow below as separate sections.
