# Feature Specification: Expense Management Improvements

**Feature Branch**: `012-expense-improvements`
**Created**: 2026-01-16
**Status**: Draft
**Input**: User description: "ci sono un po' di cose da fare: chiedere conferma per cancellare le spese quando apro l'app la prima volta, le income nella dashboard sono a zero avere la possibilita di flaggare le spese come \"da rimborsare\" e \"rimborsata\" e aggiungere il conteggio del \"rimborsato\" al budget generale"

## Clarifications

### Session 2026-01-16

- Q: Should there be restrictions on reimbursement status transitions (e.g., can users freely change from "reimbursed" back to "reimbursable")? → A: Allow status changes with restrictions - users can change from "reimbursable" to "reimbursed" and back, but require confirmation for reverting "reimbursed" status
- Q: How should reimbursements interact with budget time periods (monthly/yearly views) - should they affect the period when the expense was created or when it was marked as reimbursed? → A: Track in reimbursement period - reimbursement affects the budget period when it's marked as "reimbursed" (treated as income event)
- Q: How should the dashboard handle income calculation when network connectivity is lost during initial load? → A: Show cached data with indicator - display last known income values with a visual indicator that data may be stale, allow background sync
- Q: What should happen when a user deletes an expense that is marked as "reimbursable" (awaiting reimbursement)? → A: Warn about reimbursement status - show additional warning in confirmation dialog noting the expense is pending reimbursement before allowing deletion
- Q: What happens when reimbursed amounts exceed current budget deficits (e.g., budget is already positive)? → A: Always add to budget - reimbursement always increases available budget regardless of current budget state (can result in surplus)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Expense Deletion Confirmation (Priority: P1)

Users need protection against accidental expense deletions. When a user attempts to delete an expense, the system prompts for confirmation before permanently removing the data.

**Why this priority**: Prevents data loss from accidental deletions, which is critical for maintaining budget accuracy and user trust. This is a foundational safety feature that should be in place before other enhancements.

**Independent Test**: Can be fully tested by attempting to delete any expense and verifying that a confirmation dialog appears. Delivers immediate value by preventing accidental data loss.

**Acceptance Scenarios**:

1. **Given** a user has selected an expense to delete, **When** they initiate the delete action, **Then** a confirmation dialog appears asking "Are you sure you want to delete this expense?"
2. **Given** the confirmation dialog is displayed, **When** the user confirms deletion, **Then** the expense is permanently deleted and removed from the list
3. **Given** the confirmation dialog is displayed, **When** the user cancels the action, **Then** the expense remains unchanged and the dialog closes
4. **Given** a user attempts to delete multiple expenses, **When** they initiate the delete action, **Then** each deletion requires individual confirmation
5. **Given** a user attempts to delete an expense marked as "reimbursable", **When** the confirmation dialog appears, **Then** it includes an additional warning stating the expense is pending reimbursement

---

### User Story 2 - Initial Income Display Fix (Priority: P1)

When users first open the app, the dashboard should accurately display income data instead of showing zero values. This ensures users see complete financial information from their first interaction.

**Why this priority**: Critical for user onboarding and first impression. Showing zero income when data exists creates confusion and undermines trust in the app's reliability.

**Independent Test**: Can be fully tested by launching the app for the first time (or after clearing app data) and verifying that income values are correctly displayed on the dashboard.

**Acceptance Scenarios**:

1. **Given** a user opens the app for the first time with existing income data, **When** the dashboard loads, **Then** all income values are correctly displayed (not zero)
2. **Given** a user has income entries in the system, **When** they navigate to the dashboard, **Then** the total income reflects the sum of all income entries
3. **Given** the app is freshly installed with no data, **When** the dashboard loads, **Then** income is displayed as zero (expected behavior for empty state)
4. **Given** income data exists in the database, **When** the app initializes, **Then** income data is loaded and ready before the dashboard renders
5. **Given** network connectivity is lost during dashboard initialization, **When** the dashboard loads, **Then** cached income data is displayed with a visual indicator showing data may be stale
6. **Given** the dashboard is showing stale cached data, **When** network connectivity is restored, **Then** the app automatically syncs income data in the background and updates the display

---

### User Story 3 - Reimbursable Expense Tracking (Priority: P2)

Users can mark expenses as "reimbursable" or "reimbursed" to track money that will be or has been returned to the budget. The system includes reimbursed amounts in the overall budget calculation.

**Why this priority**: Enhances budget accuracy by tracking temporary expenses that don't permanently impact the budget. While valuable, it's not as critical as preventing data loss or fixing broken core functionality.

**Independent Test**: Can be fully tested by creating an expense, marking it as reimbursable, then marking it as reimbursed, and verifying the budget calculation reflects the reimbursement.

**Acceptance Scenarios**:

1. **Given** a user is creating or editing an expense, **When** they view the expense form, **Then** options to mark the expense as "reimbursable" are available
2. **Given** an expense is marked as "reimbursable", **When** the user views the expense details, **Then** an indicator shows the expense is awaiting reimbursement
3. **Given** an expense is marked as "reimbursable", **When** the user marks it as "reimbursed", **Then** the expense status updates to "reimbursed"
4. **Given** an expense is marked as "reimbursed", **When** the budget is calculated, **Then** the reimbursed amount is added back to the available budget
5. **Given** multiple expenses have various reimbursement statuses, **When** the user views the budget overview, **Then** a summary shows: total reimbursable amount pending and total reimbursed amount
6. **Given** an expense is marked as "reimbursed", **When** the user views expense history, **Then** the expense remains visible with a "reimbursed" indicator
7. **Given** a user wants to filter expenses, **When** they access expense filters, **Then** options to filter by "reimbursable" and "reimbursed" status are available
8. **Given** an expense is marked as "reimbursed", **When** the user attempts to change it back to "reimbursable" or "none", **Then** a confirmation dialog appears before allowing the status change
9. **Given** the budget is already positive (surplus), **When** an expense is marked as "reimbursed", **Then** the reimbursed amount is added to the budget, further increasing the surplus

---

### Edge Cases

- When a user attempts to revert a "reimbursed" expense back to "reimbursable" status, the system must require confirmation to prevent accidental reversions
- Reimbursements are treated as income events occurring in the period when the expense is marked as "reimbursed", not when the original expense was created
- What happens if the app is closed while the delete confirmation dialog is open?
- When network connectivity is lost during initial load, the dashboard displays cached income data with a visual indicator showing data may be stale, and attempts background sync when connectivity is restored
- When deleting an expense marked as "reimbursable", the confirmation dialog displays an additional warning informing the user that the expense is pending reimbursement
- Reimbursements always increase the available budget regardless of current budget state, potentially creating a surplus (positive balance)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a confirmation dialog before permanently deleting any expense
- **FR-002**: Confirmation dialog MUST provide clear "Confirm" and "Cancel" options
- **FR-003**: System MUST only delete the expense when the user explicitly confirms the deletion
- **FR-004**: System MUST correctly load and display income data when the app initializes, including first-time launches
- **FR-005**: Dashboard MUST calculate and display total income from all income entries in the database
- **FR-006**: System MUST provide a way for users to mark expenses with reimbursement status (not reimbursable, reimbursable, reimbursed)
- **FR-007**: System MUST persist reimbursement status for each expense across app sessions
- **FR-008**: System MUST include reimbursed amounts in the overall budget calculation as positive adjustments
- **FR-009**: System MUST display reimbursement status indicators on expense entries in lists and detail views
- **FR-010**: System MUST provide a summary of total pending reimbursements and total reimbursed amounts
- **FR-011**: System MUST allow users to filter expenses by reimbursement status
- **FR-012**: System MUST allow users to change reimbursement status of existing expenses (e.g., from "reimbursable" to "reimbursed")
- **FR-013**: System MUST require confirmation when users attempt to revert a "reimbursed" expense back to "reimbursable" or "none" status
- **FR-014**: System MUST treat reimbursements as income events that affect the budget period when the expense is marked as "reimbursed", not the period when the original expense was created
- **FR-015**: System MUST display cached income data when network connectivity is unavailable during dashboard initialization
- **FR-016**: System MUST show a visual indicator when displaying potentially stale cached income data due to network issues
- **FR-017**: System MUST attempt background synchronization of income data when network connectivity is restored
- **FR-018**: System MUST display an enhanced confirmation dialog with additional warning when user attempts to delete an expense marked as "reimbursable", noting the pending reimbursement status
- **FR-019**: System MUST always add reimbursed amounts to the available budget regardless of current budget state, allowing the budget to exceed zero (create surplus)

### Key Entities

- **Expense**: Represents a spending transaction. Key attributes include amount, date, category, description, and reimbursement status. Reimbursement status can be: "none" (regular expense), "reimbursable" (pending reimbursement), or "reimbursed" (money returned to budget).

- **Income**: Represents money coming into the budget. Key attributes include amount, source, and date. Should be loaded and calculated when the app initializes.

- **Budget**: Represents overall financial state. Calculation must include: total income, total expenses, and adjustments for reimbursed amounts (reimbursed expenses add back to available budget). For period-based budgets (monthly/yearly), reimbursements are counted as income in the period when marked as "reimbursed", not when the original expense occurred.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users cannot accidentally delete expenses - 100% of deletion attempts require confirmation
- **SC-002**: Dashboard displays accurate income data on first app launch with zero calculation errors
- **SC-003**: Users can track reimbursable expenses with clear visual indicators distinguishing between "reimbursable", "reimbursed", and regular expenses
- **SC-004**: Budget calculations accurately reflect reimbursements with 100% accuracy in mathematical adjustments
- **SC-005**: Users can complete the workflow of marking an expense as reimbursable, then reimbursed, and see budget update in under 10 seconds
- **SC-006**: Zero data loss incidents from accidental deletions after confirmation dialog implementation

## Assumptions

- The app currently allows expense deletion without any confirmation mechanism
- Income data exists in the database but is not being loaded correctly on initial app launch
- The current expense data model can be extended to include reimbursement status fields
- Budget calculations are centralized in a way that can be updated to include reimbursement adjustments
- Users understand the concept of reimbursable expenses (e.g., business expenses, shared costs to be repaid)
- Reimbursed amounts should increase the available budget (not reduce total expenses in historical records)
- The app uses a database that persists data across sessions
