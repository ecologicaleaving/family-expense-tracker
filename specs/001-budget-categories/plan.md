# Implementation Plan: Budget Management and Category Customization

**Branch**: `001-budget-categories` | **Date**: 2025-12-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-budget-categories/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature adds budget management capabilities to the family expense tracker, allowing group administrators to set group budgets and individual members to set personal budgets. It introduces an expense classification system (group vs personal) with privacy controls, customizable expense categories, and real-time budget tracking with visual indicators. Budgets reset monthly at midnight in each user's local timezone, with historical tracking preserved for reporting.

## Technical Context

**Language/Version**: Dart 3.0+ / Flutter 3.0+
**Primary Dependencies**: flutter_riverpod 2.4.0 (state management), supabase_flutter 2.0.0 (backend), drift 2.14.0 (local database), fl_chart 0.65.0 (budget visualizations)
**Storage**: Supabase (PostgreSQL) for server-side data, Drift (SQLite) for local caching
**Testing**: flutter_test (unit), integration_test (E2E), mockito 5.4.0 (mocking)
**Target Platform**: Android (primary), iOS (future)
**Project Type**: Mobile app (Flutter) with feature-based clean architecture
**Performance Goals**: Budget calculations < 500ms, dashboard render < 2s, real-time updates within 2s
**Constraints**: Offline-capable budget viewing, whole-euro precision, timezone-aware resets, privacy for personal expenses
**Scale/Scope**: Support 10-member groups, hundreds of expenses per month, monthly budget history

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: ⚠️ Constitution file contains only template placeholders - no specific project principles defined yet.

**Assumed Best Practices** (in absence of constitution):
- ✅ **Feature-based architecture**: New feature follows existing `lib/features/` structure
- ✅ **Clean architecture layers**: Domain (entities/repositories) → Data (models/datasources) → Presentation (screens/providers/widgets)
- ✅ **State management consistency**: Using Riverpod as per existing codebase
- ✅ **Testing requirements**: Unit tests for business logic, integration tests for critical flows
- ✅ **Supabase-first**: Server-side logic in database functions/RLS, client handles presentation

**Post-Design Re-check**: Will verify after Phase 1 that new entities and contracts follow established patterns.

## Project Structure

### Documentation (this feature)

```text
specs/001-budget-categories/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── budget-api.md    # Budget CRUD operations
│   ├── category-api.md  # Category management operations
│   └── expense-api.md   # Expense flag update operations
├── checklists/
│   └── requirements.md  # Specification quality checklist (completed)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── budgets/              # NEW: Budget management feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── budget_local_datasource.dart
│   │   │   │   └── budget_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── group_budget_model.dart
│   │   │   │   ├── personal_budget_model.dart
│   │   │   │   └── budget_stats_model.dart
│   │   │   └── repositories/
│   │   │       └── budget_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── group_budget_entity.dart
│   │   │   │   ├── personal_budget_entity.dart
│   │   │   │   └── budget_stats_entity.dart
│   │   │   └── repositories/
│   │   │       └── budget_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── budget_provider.dart
│   │       ├── screens/
│   │       │   ├── budget_settings_screen.dart
│   │       │   └── budget_history_screen.dart
│   │       └── widgets/
│   │           ├── budget_progress_bar.dart
│   │           ├── budget_warning_indicator.dart
│   │           └── no_budget_set_card.dart
│   │
│   ├── categories/           # NEW: Category management feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── category_local_datasource.dart
│   │   │   │   └── category_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── expense_category_model.dart
│   │   │   └── repositories/
│   │   │       └── category_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── expense_category_entity.dart
│   │   │   └── repositories/
│   │   │       └── category_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── category_provider.dart
│   │       ├── screens/
│   │       │   └── category_management_screen.dart
│   │       └── widgets/
│   │           ├── category_list_item.dart
│   │           ├── category_form_dialog.dart
│   │           └── category_delete_dialog.dart
│   │
│   ├── expenses/             # MODIFIED: Add group/personal flag support
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── expense_model.dart          # Add isGroupExpense field
│   │   │   └── repositories/
│   │   │       └── expense_repository_impl.dart # Add migration logic
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── expense_entity.dart         # Add isGroupExpense field
│   │   │   └── repositories/
│   │   │       └── expense_repository.dart      # Add flag update methods
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── manual_expense_screen.dart   # Add group/personal toggle
│   │       └── widgets/
│   │           ├── expense_type_toggle.dart    # NEW: Group/Personal selector
│   │           └── expense_list_item.dart      # Show expense type indicator
│   │
│   └── dashboard/            # MODIFIED: Integrate budget progress indicators
│       └── presentation/
│           ├── screens/
│           │   └── dashboard_screen.dart        # Add budget widgets
│           └── widgets/
│               └── total_summary_card.dart      # Integrate budget progress
│
├── core/
│   └── utils/
│       ├── budget_calculator.dart               # NEW: Budget math utilities
│       └── timezone_handler.dart                # NEW: Timezone-aware date logic
│
└── shared/
    └── widgets/
        └── budget_indicator.dart                # NEW: Reusable budget UI

test/
├── features/
│   ├── budgets/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── budget_repository_impl_test.dart
│   │   ├── domain/
│   │   └── presentation/
│   │       └── providers/
│   │           └── budget_provider_test.dart
│   │
│   └── categories/
│       ├── data/
│       └── presentation/
│
└── integration/
    ├── budget_flow_test.dart
    ├── category_management_test.dart
    └── expense_classification_test.dart

supabase/migrations/
└── [TIMESTAMP]_add_budgets_and_categories.sql   # NEW: Database schema changes
```

**Structure Decision**: Mobile application structure using Flutter's feature-based clean architecture. Each feature (budgets, categories) follows the existing pattern with domain/data/presentation layers. Modifications to existing expense feature add the group/personal classification system. Supabase database migration adds new tables for budgets and categories.

## Complexity Tracking

> **Not applicable** - No constitution violations. Implementation follows existing architectural patterns and project conventions.

## Phase 0: Research & Decision Log

### Research Tasks

1. **Budget Calculation Strategy with Timezone Handling**
   - **Question**: How to efficiently calculate budget consumption when users in different timezones see different "current month" boundaries?
   - **Research needed**: Strategies for timezone-aware monthly aggregation in Supabase PostgreSQL

2. **Personal Expense Privacy Implementation**
   - **Question**: How to enforce "personal expenses visible only to creator" at database level?
   - **Research needed**: Supabase RLS (Row Level Security) patterns for user-scoped data filtering

3. **Category Deletion with Expense Reassignment**
   - **Question**: Best UX pattern for bulk reassignment when deleting category with many expenses?
   - **Research needed**: Flutter modal patterns, batch update strategies in Supabase

4. **Existing Expense Migration Strategy**
   - **Question**: How to safely migrate existing expenses to add isGroupExpense flag (default true)?
   - **Research needed**: Supabase migration best practices for adding non-nullable fields with defaults

5. **Budget Progress Real-time Updates**
   - **Question**: How to ensure budget indicators update within 2s when new expenses added?
   - **Research needed**: Supabase real-time subscriptions vs. optimistic updates in Riverpod

### Decision Summary

*(To be filled in research.md after research agents complete)*

## Phase 1: Design Artifacts

### Data Model Overview

**New Entities:**
- `GroupBudget`: Monthly budget for family group (amount, month, year, groupId, createdBy)
- `PersonalBudget`: Monthly budget for individual user (amount, month, year, userId)
- `ExpenseCategory`: Customizable expense categories (id, name, isDefault, groupId, createdBy)

**Modified Entities:**
- `Expense`: Add `isGroupExpense` boolean field (default true for migration)

**Relationships:**
- GroupBudget 1:1 FamilyGroup (per month)
- PersonalBudget 1:1 User (per month)
- ExpenseCategory N:1 FamilyGroup
- Expense N:1 ExpenseCategory

*(Full details in data-model.md)*

### API Contracts

**Budget Service:**
- `POST /budgets/group` - Set/update group budget
- `GET /budgets/group/:groupId/:year/:month` - Get group budget for month
- `POST /budgets/personal` - Set/update personal budget
- `GET /budgets/personal/:userId/:year/:month` - Get personal budget for month
- `GET /budgets/stats/group/:groupId/:year/:month` - Get group budget consumption stats
- `GET /budgets/stats/personal/:userId/:year/:month` - Get personal budget consumption stats
- `GET /budgets/history/group/:groupId` - Get historical group budgets
- `GET /budgets/history/personal/:userId` - Get historical personal budgets

**Category Service:**
- `GET /categories/:groupId` - List all categories for group
- `POST /categories` - Create new category (admin only)
- `PUT /categories/:id` - Update category name (admin only)
- `DELETE /categories/:id` - Delete category with reassignment (admin only)

**Expense Service (Extensions):**
- `PATCH /expenses/:id/classification` - Update group/personal flag
- `POST /expenses/migrate` - One-time migration to add isGroupExpense=true to existing

*(Full OpenAPI specs in contracts/)*

### Quick Start Guide

*(To be generated in quickstart.md covering: setup, first budget creation, category management, expense classification)*

## Phase 2: Task Generation

**Note**: Task breakdown will be generated by `/speckit.tasks` command (not part of this plan).

**Expected task categories:**
1. Database migrations and schema updates
2. Backend: Budget repository and business logic
3. Backend: Category repository and CRUD operations
4. Backend: Expense migration and flag update logic
5. Frontend: Budget settings screens and widgets
6. Frontend: Category management screens
7. Frontend: Expense form updates (group/personal toggle)
8. Frontend: Dashboard integration (budget progress indicators)
9. State management: Riverpod providers for budgets and categories
10. Testing: Unit tests for repositories and business logic
11. Testing: Integration tests for critical user flows
12. Documentation: Update user-facing docs if applicable

## Next Steps

1. ✅ **Phase 0 Complete**: Run research agents to resolve unknowns → generate `research.md`
2. **Phase 1 Next**: Generate `data-model.md`, `contracts/`, and `quickstart.md`
3. **Update Agent Context**: Run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude`
4. **Phase 2**: User runs `/speckit.tasks` to generate dependency-ordered task list

## Open Questions for Research

1. How should budget consumption be calculated when expenses have cents but budgets are whole euros? (Answered in spec: round up)
2. Should budget history be stored as separate rows or computed from historical expenses? (To research)
3. How to handle budget reset at midnight across timezones without batch job? (To research)
4. Should default categories be seeded per-group or globally? (To research)
5. Optimistic update strategy for budget progress to meet 2s update requirement? (To research)
