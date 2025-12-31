# Implementation Plan: Home Screen Budget Widget

**Branch**: `003-home-budget-widget` | **Date**: 2025-12-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-home-budget-widget/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement native home screen widgets for Android and iOS that display the current monthly budget status (spent/limit with progress bar) and provide two quick action buttons: "Scansiona Scontrino" (opens camera scanner) and "Inserimento Manuale" (opens manual expense form). The widget must auto-update when expenses are added, support light/dark themes, and work in three sizes (small, medium, large). This reduces friction for expense entry from 5-6 taps to 1-2 taps while providing at-a-glance budget visibility without opening the app.

**Technical Approach**: Use Flutter's `home_widget` package (community-maintained bridge to native Android App Widgets and iOS WidgetKit) with platform-specific implementations in kotlin/ (Android) and Swift (iOS extension). Widget data will be persisted locally using shared preferences for quick rendering, with background refresh jobs updating from Supabase backend. Deep linking via custom URL schemes will handle navigation to specific screens.

## Technical Context

**Language/Version**: Dart 3.0+ (Flutter SDK), Kotlin 1.9+ (Android native), Swift 5.9+ (iOS native)
**Primary Dependencies**:
- `home_widget: ^0.6.0` - Flutter bridge to native widgets
- `flutter_riverpod: ^2.4.0` - State management (existing)
- `supabase_flutter: ^2.0.0` - Backend integration (existing)
- `go_router: ^12.0.0` - Deep linking navigation (existing)
- `shared_preferences` - Widget data persistence (existing via home_widget)

**Storage**:
- Supabase PostgreSQL (backend, existing) for expense and budget data
- SharedPreferences/UserDefaults (local) for widget state caching
- No new database required

**Testing**:
- `flutter_test` - Dart unit tests for widget data preparation logic
- `integration_test` - Widget update flows and deep linking
- Manual testing - Platform-specific widget rendering, theme adaptation, background refresh

**Target Platform**:
- Android 5.0+ (API 21+, minimum SDK already set to 24 in project)
- iOS 14+ (required for WidgetKit support)
- Widget sizes: Small (2x2 cells Android), Medium (4x2 cells Android), Large (4x4 cells Android); equivalent iOS sizes

**Project Type**: Mobile (Flutter cross-platform with native widget extensions)

**Performance Goals**:
- Widget render: <1 second from home screen view
- App launch from widget: <2 seconds to target screen
- Widget update after expense add: <30 seconds
- Background refresh: Every 15-30 minutes (configurable, OS-dependent)

**Constraints**:
- <5MB RAM consumption per widget instance
- Maximum staleness: 5 minutes for displayed data
- iOS WidgetKit limitations: no interactive text input, stateless UI, limited update frequency
- Android limitations: battery optimization may delay background updates

**Scale/Scope**:
- Single widget per user (no multi-group widget support)
- 3 widget sizes with different layouts
- 2 quick action buttons + 1 tap area (budget section)
- Expected usage: 10k+ daily widget views, 1k+ widget-initiated app launches

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**No constitution file found** - Using general best practices assessment:

| Check | Status | Notes |
|-------|--------|-------|
| Simplicity | ✅ PASS | Single responsibility: budget display + quick access. No unnecessary abstractions. |
| Existing patterns | ✅ PASS | Reuses existing architecture: Riverpod providers, Supabase repos, go_router navigation |
| Dependencies | ✅ PASS | Adds only 1 new dependency (home_widget), all others existing |
| Testing | ⚠️ ADVISORY | Native widget code harder to unit test; rely on integration tests + manual verification |
| Platform conventions | ✅ PASS | Follows Android App Widget and iOS WidgetKit best practices |

**Decision**: Proceed with plan. No violations requiring complexity justification.

## Project Structure

### Documentation (this feature)

```text
specs/003-home-budget-widget/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0: home_widget package evaluation, deep linking patterns
├── data-model.md        # Phase 1: Widget state model, update payload schema
├── quickstart.md        # Phase 1: Setup native widget extensions, test widget installation
├── contracts/           # Phase 1: Widget update API, deep link URL schemes
└── tasks.md             # Phase 2: (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Flutter Application (existing structure extended)
lib/
├── features/
│   ├── widget/                          # NEW - Widget feature module
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── widget_local_datasource.dart      # Read/write widget state to SharedPreferences
│   │   │   ├── models/
│   │   │   │   └── widget_data_model.dart            # Serializable widget state (budget, theme)
│   │   │   └── repositories/
│   │   │       └── widget_repository_impl.dart       # Implements widget data refresh logic
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── widget_data_entity.dart           # Widget state entity
│   │   │   └── repositories/
│   │   │       └── widget_repository.dart            # Abstract widget repository
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── widget_provider.dart              # Riverpod provider for widget updates
│   │       └── services/
│   │           ├── widget_update_service.dart        # Handles widget refresh triggers
│   │           └── deep_link_handler.dart            # Routes deep links to screens
│   ├── expenses/ (existing)
│   ├── dashboard/ (existing)
│   ├── auth/ (existing)
│   └── ...
├── shared/
│   └── services/
│       └── background_task_service.dart  # NEW - Manages periodic widget refresh
└── main.dart                             # Extended with deep link handling

# Android Native Widget Extension
android/app/src/main/
├── kotlin/com/family/expense_tracker/
│   └── widget/
│       ├── BudgetWidgetProvider.kt       # NEW - Android App Widget provider
│       ├── BudgetWidgetConfigActivity.kt # NEW - Widget configuration activity (optional)
│       └── WidgetUpdateWorker.kt         # NEW - WorkManager job for background refresh
└── res/
    ├── layout/
    │   ├── widget_budget_small.xml       # NEW - Small widget layout
    │   ├── widget_budget_medium.xml      # NEW - Medium widget layout
    │   └── widget_budget_large.xml       # NEW - Large widget layout
    ├── drawable/
    │   └── widget_background.xml         # NEW - Widget background shapes
    └── xml/
        └── budget_widget_info.xml        # NEW - Widget metadata (sizes, update frequency)

# iOS Native Widget Extension
ios/
├── BudgetWidgetExtension/                # NEW - WidgetKit extension target
│   ├── BudgetWidget.swift                # Widget definition, timeline provider
│   ├── BudgetWidgetView.swift            # SwiftUI widget layout
│   ├── WidgetDataProvider.swift          # Reads widget data from shared container
│   ├── Assets.xcassets/                  # Widget-specific assets
│   └── Info.plist                        # Extension configuration
└── Runner/ (existing Flutter app)
    └── AppDelegate.swift                 # Extended with shared app group setup

# Tests
test/
├── features/
│   └── widget/
│       ├── data/
│       │   └── widget_repository_impl_test.dart
│       └── presentation/
│           └── providers/
│               └── widget_provider_test.dart
└── integration_test/
    └── widget_integration_test.dart      # Widget update + deep link flows
```

**Structure Decision**: Extends existing Flutter feature-based architecture with new `widget/` module following clean architecture pattern (data/domain/presentation layers). Native widget code isolated in platform-specific directories (`android/app/src/main/kotlin/widget/`, `ios/BudgetWidgetExtension/`) to minimize Flutter codebase coupling. This allows independent testing and maintenance of Flutter logic vs platform-specific rendering.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** - This section is empty.

