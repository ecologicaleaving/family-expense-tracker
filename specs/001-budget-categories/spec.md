# Feature Specification: Budget Management and Category Customization

**Feature Branch**: `001-budget-categories`
**Created**: 2025-12-31
**Status**: Draft
**Input**: User description: "ora vorrei dare la possibilità di impostare budget del gruppo, budget individuale e di modificare le categorie di spesa, in più , per ogni spesa , un flag che definisce se è una spesa per il gruppo o no"

## Clarifications

### Session 2025-12-31

- Q: When should monthly budgets reset (timezone handling)? → A: Reset at midnight in each user's local timezone (personalized)
- Q: How should existing expenses (created before this feature) be handled? → A: Default all existing expenses to "Group expense"
- Q: Can group administrators or other members view someone else's personal expenses? → A: Personal expenses are completely private - only the creator can see them
- Q: What decimal precision should budget amounts use? → A: Whole euros only (no cents)
- Q: Are budgets mandatory or optional? → A: Budgets are optional - dashboard shows "No budget set" message with option to set one

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Define Group Budget (Priority: P1)

As a group administrator, I want to set a monthly budget for my family group so that we can track our spending against a shared financial goal and avoid overspending.

**Why this priority**: Budget tracking is the core value of this feature. Without setting budgets, the other features lose context. This enables the primary use case.

**Independent Test**: Can be fully tested by creating a group budget, adding expenses, and verifying progress against the budget. Delivers immediate value for budget-conscious families.

**Acceptance Scenarios**:

1. **Given** I am a group administrator, **When** I navigate to budget settings, **Then** I can set a monthly budget amount for the family group
2. **Given** I have set a group budget, **When** I view the group dashboard, **Then** I see current spending vs budget with a visual indicator (e.g., progress bar)
3. **Given** group expenses approach the budget limit, **When** spending reaches 80% of budget, **Then** I see a warning indicator on the dashboard
4. **Given** group expenses exceed the budget, **When** spending surpasses 100% of budget, **Then** the dashboard clearly shows over-budget status
5. **Given** I have set a budget, **When** a new month begins, **Then** the budget tracking resets for the new month while preserving the budget amount
6. **Given** I have not set a group budget, **When** I view the group dashboard, **Then** I see expense totals without budget indicators and a "No budget set" message with a link to set one

---

### User Story 2 - Define Personal Budget (Priority: P2)

As a family member, I want to set my own personal monthly budget so that I can track my individual spending separately from the group budget and manage my personal finances.

**Why this priority**: Personal budgets complement group budgets and enable individual financial accountability. Important for families where members have separate allowances or spending goals.

**Independent Test**: Can be tested by setting a personal budget, adding personal expenses, and verifying personal budget tracking works independently of group budget.

**Acceptance Scenarios**:

1. **Given** I am a group member, **When** I navigate to my personal budget settings, **Then** I can set a monthly budget amount for my personal expenses
2. **Given** I have set a personal budget, **When** I view my personal dashboard, **Then** I see my spending vs budget with progress indicators
3. **Given** my personal expenses approach my budget, **When** spending reaches 80% of budget, **Then** I see a warning on my personal dashboard
4. **Given** I have both personal and group budgets, **When** I add a personal expense, **Then** it only affects my personal budget, not the group budget
5. **Given** I have both personal and group budgets, **When** I add a group expense, **Then** it affects both my personal budget and the group budget
6. **Given** I have not set a personal budget, **When** I view my personal dashboard, **Then** I see expense totals without budget indicators and a "No budget set" message with a link to set one

---

### User Story 3 - Mark Expenses as Group or Personal (Priority: P3)

As a user adding an expense, I want to mark whether the expense is for the group or just for me so that it counts toward the correct budget and appears in the appropriate dashboards.

**Why this priority**: This flag determines expense visibility and budget impact. Required for proper budget tracking but depends on budgets being set first.

**Independent Test**: Can be tested by adding expenses marked as group and personal, then verifying they appear in the correct dashboards and affect the correct budgets.

**Acceptance Scenarios**:

1. **Given** I am adding a new expense, **When** I am on the expense entry screen, **Then** I see an option to mark the expense as "Group expense" or "Personal expense"
2. **Given** I mark an expense as "Group expense", **When** I save it, **Then** it appears in both the group dashboard and my personal dashboard
3. **Given** I mark an expense as "Personal expense", **When** I save it, **Then** it appears only in my personal dashboard, not in the group dashboard
4. **Given** I mark an expense as "Group expense", **When** I save it, **Then** it counts toward both the group budget and my personal budget
5. **Given** I mark an expense as "Personal expense", **When** I save it, **Then** it counts only toward my personal budget, not the group budget
6. **Given** I am editing an existing expense, **When** I change it from personal to group or vice versa, **Then** the dashboards and budgets update accordingly

---

### User Story 4 - Customize Expense Categories (Priority: P4)

As a group administrator, I want to add, edit, or delete expense categories so that our family can track spending in categories that match our actual spending patterns.

**Why this priority**: Category customization improves tracking accuracy and user experience. Less critical than budgets but enhances the feature's utility.

**Independent Test**: Can be tested by creating a custom category, assigning expenses to it, and verifying the category appears in dashboards and reports.

**Acceptance Scenarios**:

1. **Given** I am a group administrator, **When** I navigate to category settings, **Then** I see a list of current categories and can add new ones
2. **Given** I want to add a custom category, **When** I create a new category named "Pet care", **Then** it becomes available when categorizing expenses
3. **Given** I have created custom categories, **When** I edit a category name, **Then** all expenses using that category reflect the updated name
4. **Given** I want to remove an unused category, **When** I delete it, **Then** it is no longer available for new expenses
5. **Given** I want to delete a category with existing expenses, **When** I attempt deletion, **Then** I see a warning with the count of affected expenses and options to either manually reassign them to another category or automatically move them all to "Other"
6. **Given** I am a non-admin group member, **When** I try to access category settings, **Then** I can view categories but cannot add, edit, or delete them

---

### Edge Cases

- What happens when a user changes an expense from group to personal after the group budget has been exceeded? The group budget totals recalculate immediately, potentially moving from over-budget back to within budget.
- What happens to budgets when the month changes? Budget amounts persist and reset tracking to zero for the new month; historical budget vs actual data is preserved for reporting.
- What happens to expenses in a deleted category? System shows a warning about existing expenses and gives admin the option to either manually reassign them to another category or auto-move them to "Other".
- What happens when a user leaves the group mid-month? Their personal expenses remain with them; their group expenses remain in the group's history but no longer affect their personal budget.
- Can users set different budget amounts for different months? Initially, budgets are recurring monthly amounts; budget history tracking is assumed for future reporting.
- What happens when admin changes category settings while members are adding expenses? Changes apply immediately; ongoing expense entry uses the updated category list.
- What happens to group budget when members are in different timezones? Each user's view resets at their local midnight; group budget totals may show different values to different members during the transition period (last hours of old month for some, first hours of new month for others).
- What happens to expenses created before the group/personal flag feature was introduced? All existing expenses are automatically migrated with the flag set to "Group expense" to maintain current shared expense behavior.
- Can group administrators view or manage other members' personal expenses? No, personal expenses are completely private to the creator; administrators cannot view, edit, or delete them even though they can manage group expenses.
- What happens when a user adds expenses without setting a budget? Expenses are tracked normally; dashboards show totals and breakdowns but no budget progress indicators; a "No budget set" message appears with option to configure budgets.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow group administrators to set a monthly budget amount (in whole euros, no cents) for the family group
- **FR-002**: System MUST allow individual users to set a monthly budget amount (in whole euros, no cents) for their personal expenses
- **FR-003**: System MUST track total spending against group budget in real-time
- **FR-004**: System MUST track individual spending against personal budget in real-time
- **FR-005**: System MUST display budget progress on group dashboard with visual indicators (progress bar showing percentage used)
- **FR-006**: System MUST display personal budget progress on personal dashboard with visual indicators
- **FR-007**: System MUST show warning indicators when spending reaches 80% of budget
- **FR-008**: System MUST show over-budget indicators when spending exceeds 100% of budget
- **FR-009**: System MUST reset budget tracking at midnight on the first day of each month (in each user's local timezone) while preserving budget amounts
- **FR-010**: System MUST provide a flag for each expense to mark it as "Group expense" or "Personal expense"
- **FR-011**: System MUST count group expenses toward both group budget and the creator's personal budget
- **FR-012**: System MUST count personal expenses only toward the creator's personal budget
- **FR-013**: System MUST show group expenses in both group dashboard and creator's personal dashboard
- **FR-014**: System MUST show personal expenses only in creator's personal dashboard and hide them from all other users (including group administrators)
- **FR-015**: System MUST allow group administrators to create new expense categories
- **FR-016**: System MUST allow group administrators to edit existing category names
- **FR-017**: System MUST allow group administrators to delete categories
- **FR-018**: System MUST prevent non-admin members from modifying categories
- **FR-019**: System MUST update all expenses when a category is renamed
- **FR-020**: System MUST show a warning when attempting to delete a category with existing expenses, and provide the administrator with options to either manually reassign expenses to another category or automatically move them to "Other"
- **FR-021**: System MUST make newly created categories immediately available for expense entry
- **FR-022**: System MUST recalculate budget totals immediately when expense group/personal flag is changed
- **FR-023**: System MUST preserve budget amount settings when month changes
- **FR-024**: Users MUST be able to view budget history showing budget vs actual for previous months
- **FR-025**: System MUST migrate all existing expenses (created before this feature) by defaulting their flag to "Group expense" to maintain backward compatibility
- **FR-026**: System MUST round up expense totals (which may include cents) to the next whole euro when calculating budget consumption
- **FR-027**: System MUST allow users to use the app without setting budgets (budgets are optional)
- **FR-028**: System MUST display a "No budget set" message on dashboards when no budget has been configured, with a clear call-to-action to set one

### Key Entities

- **Group Budget**: Monthly spending limit for the entire family group, set by administrator, with tracking of total group expenses against limit
- **Personal Budget**: Monthly spending limit for an individual user, set by that user, with tracking of user's expenses (both personal and their share of group expenses) against limit
- **Expense Flag**: Boolean indicator on each expense marking it as group or personal, determines budget allocation and dashboard visibility
- **Expense Category**: Classification for expenses (food, utilities, transport, etc.), customizable by group administrator, with default categories plus user-defined additions

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Group administrators can set or modify group budget in under 30 seconds
- **SC-002**: Users can set or modify personal budget in under 30 seconds
- **SC-003**: Budget progress indicators update in real-time (within 2 seconds) when new expenses are added
- **SC-004**: Users can mark an expense as group or personal during entry with a single tap/selection
- **SC-005**: Changing expense flag from personal to group (or vice versa) updates dashboards and budgets within 2 seconds
- **SC-006**: Group administrators can add, edit, or delete a category in under 30 seconds
- **SC-007**: Dashboard clearly distinguishes group vs personal expenses with 90% user comprehension in usability testing
- **SC-008**: Budget warning indicators are visible and understood by 95% of users in usability testing
- **SC-009**: Users successfully set up both group and personal budgets within 5 minutes of feature introduction
- **SC-010**: Category customization results in 80% of families adding at least one custom category within first month

## Assumptions

- **Default behavior**: Expenses default to "group" when created by scanning receipts (can be changed by user)
- **Budget scope**: Budgets are monthly; weekly or annual budgets are not in initial scope
- **Budget requirement**: Budgets are optional; users can track expenses without setting budgets
- **Budget permissions**: Only group administrators can set group budget; all members can set personal budgets
- **Category permissions**: Only group administrators can modify categories; changes apply to entire group
- **Default categories**: System includes standard categories (food, utilities, transport, healthcare, entertainment, other) that cannot be deleted
- **Budget history**: Past months' budget vs actual data is preserved for future reporting features
- **Multi-currency**: Not supported; budgets use same EUR currency as expenses
- **Budget precision**: Budget amounts are whole euros only (no cents); expense totals with cents are rounded up to the next euro for budget tracking
- **Budget notifications**: Push notifications for budget warnings are a future enhancement
- **Shared categories**: All group members use the same category list; personal category customization is not supported
- **Budget rollover**: Unused budget does not roll over to next month
