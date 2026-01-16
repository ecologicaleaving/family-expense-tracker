# Implementation Plan: Expense Management Improvements

**Branch**: `012-expense-improvements` | **Date**: 2026-01-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-expense-improvements/spec.md`

## Summary

This feature implements three critical improvements to expense management:
1. **Deletion Confirmation** (P1) - Prevent accidental data loss with confirmation dialogs
2. **Income Display Fix** (P1) - Correct zero income bug on dashboard initialization
3. **Reimbursable Expense Tracking** (P2) - Track expenses awaiting reimbursement with budget adjustments

**Technical Approach**: Extend existing Flutter/Riverpod architecture with minimal changes to `ExpenseEntity`, add new UI dialogs, fix dashboard provider initialization logic, and update budget calculation to handle reimbursement as income events.

## Technical Context

**Language/Version**: Dart `>=3.0.0 <4.0.0` with Flutter (stable channel)
**Primary Dependencies**:
- `flutter_riverpod: ^2.4.0` (State management)
- `supabase_flutter: ^2.0.0` (Backend/Auth)
- `drift: ^2.14.0` (SQLite ORM for local storage)
- `hive_flutter: ^1.1.0` (Local caching)
- `go_router: ^12.0.0` (Navigation)
- `fl_chart: ^0.65.0` (Charts/visualization)

**Storage**:
- Primary: Supabase (PostgreSQL remote database)
- Local: Drift (SQLite) for offline support
- Cache: Hive for fast key-value storage
- Secure: flutter_secure_storage for sensitive data

**Testing**: flutter_test + mockito + dartz (functional programming)
**Target Platform**: iOS 15+ and Android (mobile-only app)
**Project Type**: Mobile (Flutter) - feature-based clean architecture

**Performance Goals**:
- Dialog responses: <200ms
- Budget recalculation: <500ms
- Dashboard load (cached): <1s
- Dashboard load (network): <3s

**Constraints**:
- Must work offline with cached data
- Must support Italian locale (hardcoded `it_IT`)
- Material Design 3 with "Flourishing Finances" theme
- EUR currency only

**Scale/Scope**:
- Family budget app (2-10 users per group)
- Hundreds of expenses per month per group
- Real-time sync when online

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: N/A - No constitution file customized yet (template placeholders only).

Since the constitution file contains only placeholders, there are no project-specific principles to validate against. The implementation will follow Flutter/Dart best practices and the existing clean architecture pattern established in the codebase.

**Re-evaluation after Phase 1**: Will verify alignment with discovered patterns from codebase exploration (clean architecture, Riverpod state management, offline-first approach).

## Project Structure

### Documentation (this feature)

```text
specs/012-expense-improvements/
├── spec.md              # Feature specification
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (NEXT)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (if needed for APIs)
├── checklists/          # Quality validation checklists
│   └── requirements.md  # Specification quality checklist (PASSED)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── enums/
│   │   └── reimbursement_status.dart         # NEW: Enum for reimbursement states
│   ├── utils/
│   │   └── budget_calculator.dart            # MODIFIED: Add reimbursement logic
│   └── database/
│       └── drift/
│           └── tables/                       # MODIFIED: Migration for reimbursement fields
│
├── features/
│   ├── expenses/
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── expense_entity.dart       # MODIFIED: Add reimbursement fields
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── expense_model.dart        # MODIFIED: Add reimbursement serialization
│   │   │   └── repositories/
│   │   │       └── expense_repository_impl.dart  # MODIFIED: Delete + status change
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── expense_provider.dart     # MODIFIED: Delete confirmation + state updates
│   │       │   └── expense_filters_provider.dart  # NEW/MODIFIED: Reimbursement filters
│   │       ├── screens/
│   │       │   ├── manual_expense_screen.dart  # MODIFIED: Add reimbursement toggle
│   │       │   └── edit_expense_screen.dart    # MODIFIED: Status change UI
│   │       └── widgets/
│   │           ├── delete_confirmation_dialog.dart  # NEW: Deletion confirmation
│   │           ├── reimbursement_status_change_dialog.dart  # NEW: Status change confirm
│   │           ├── expense_list_item.dart      # MODIFIED: Show reimbursement indicator
│   │           └── reimbursement_toggle.dart   # NEW: Toggle widget for forms
│   │
│   ├── budgets/
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   ├── budget_provider.dart          # MODIFIED: Include reimbursement in calc
│   │   │   │   └── income_source_provider.dart   # MODIFIED: Fix initialization bug
│   │   │   └── screens/
│   │   │       └── budget_dashboard_screen.dart  # MODIFIED: Offline indicator
│   │   └── domain/
│   │       └── entities/
│   │           ├── budget_stats_entity.dart      # MODIFIED: Add reimbursement totals
│   │           └── reimbursement_summary_entity.dart  # NEW: Pending/reimbursed totals
│   │
│   └── dashboard/
│       └── presentation/
│           └── providers/
│               └── dashboard_provider.dart       # MODIFIED: Fix income loading on init
│
└── shared/
    └── widgets/
        ├── offline_banner.dart                   # MODIFIED: Use for stale data indicator
        └── reimbursement_status_badge.dart       # NEW: Visual indicator widget

test/
├── features/
│   ├── expenses/
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── expense_entity_test.dart      # NEW: Test reimbursement fields
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── expense_provider_test.dart    # MODIFIED: Test delete confirmation
│   │       └── widgets/
│   │           └── delete_confirmation_dialog_test.dart  # NEW: Dialog tests
│   │
│   └── budgets/
│       ├── domain/
│       │   └── entities/
│       │       └── budget_stats_entity_test.dart  # MODIFIED: Test reimbursement calc
│       └── presentation/
│           └── providers/
│               └── budget_provider_test.dart      # MODIFIED: Test reimbursement logic
│
└── integration_test/
    ├── expense_deletion_flow_test.dart           # NEW: E2E deletion confirmation
    ├── reimbursement_workflow_test.dart          # NEW: E2E reimbursable → reimbursed
    └── dashboard_income_initialization_test.dart  # NEW: Test first launch income display
```

**Structure Decision**: Mobile (Flutter) with feature-based clean architecture. Each feature has domain/data/presentation layers. Shared widgets in `lib/shared/widgets/`. Core utilities in `lib/core/`. Tests mirror source structure with unit/integration separation.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | Constitution contains only template placeholders | No custom project principles defined yet |

**Note**: No violations to track. Implementation follows existing codebase patterns (clean architecture, Riverpod state management, offline-first design with Supabase sync).
