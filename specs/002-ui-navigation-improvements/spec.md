# Feature Specification: UI Navigation and Settings Reorganization

**Feature Branch**: `002-ui-navigation-improvements`
**Created**: 2025-12-31
**Status**: Draft
**Input**: User description: "Adesso vorrei dare una sistemata miglioramento alla ui: come prima cosa nel menu bottom metti impostazioni e ci mettiamo dentro il profilo E gruppo. poi mi piacerebbe dare una controllata a tutta la navigazione e fare in modo che ogni screen in linea di massima abbiamo il menù Bottom in modo da accedere alle altre funzioni. poi mi piacerebbe aggiungere funzionalità alla Dashboard in modo da poter accedere anche alle ultime spese fatte vedendo elenco."

## Clarifications

### Session 2025-12-31

- Q: When a user is in the middle of creating or editing an expense and taps a bottom navigation item, what should happen? → A: Show confirmation dialog only if there are unsaved changes, otherwise navigate freely
- Q: How should the system handle navigation state when users switch between bottom navigation tabs? → A: Preserve each tab's state so users return to exactly where they left off
- Q: When a user navigates deep into the app (e.g., Settings → Profile → Edit Profile), how should bottom navigation accessibility work? → A: Keep bottom navigation visible on all screens, allowing users to jump to any main section at any time (may evolve to contextual system in future)
- Q: How should the recent expenses list handle long text that doesn't fit (descriptions, amounts with many digits, etc.)? → A: Truncate with ellipsis (...) to indicate more text exists
- Q: What happens when a user taps on a recent expense from the Dashboard that has been deleted by another user in the group? → A: Show an informative message explaining the expense was deleted, then automatically refresh the recent expenses list to remove it

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Settings Menu Consolidation (Priority: P1)

Users need a single, unified location to access all app settings, profile information, and group management. Currently, Profile and Group are separate navigation items, which creates unnecessary clutter and makes the app harder to navigate.

**Why this priority**: This is the foundation for improved navigation. Consolidating settings reduces cognitive load and follows standard mobile app patterns. Users expect settings to be grouped together, not scattered across the bottom navigation.

**Independent Test**: Can be fully tested by verifying that the bottom navigation contains a "Impostazioni" (Settings) tab, and tapping it reveals a settings screen with both Profile and Group options accessible. Delivers immediate value by simplifying the navigation structure.

**Acceptance Scenarios**:

1. **Given** a user is on any screen with the bottom navigation bar, **When** they tap the "Impostazioni" tab, **Then** they see a settings screen with options to access Profile and Group
2. **Given** a user is on the Settings screen, **When** they tap "Profilo", **Then** they are navigated to the Profile screen
3. **Given** a user is on the Settings screen, **When** they tap "Gruppo", **Then** they are navigated to the Group details screen
4. **Given** a user is viewing Profile or Group from Settings, **When** they use the back navigation, **Then** they return to the Settings screen

---

### User Story 2 - Consistent Bottom Navigation Access (Priority: P2)

Users need to access the bottom navigation bar from any screen in the app to quickly switch between different sections without having to navigate back to a home screen first.

**Why this priority**: Improves user experience by reducing navigation steps. Users should never feel "trapped" in a screen without easy access to other features. This enables efficient task switching and exploration.

**Independent Test**: Can be tested by navigating to any screen in the app and verifying that the bottom navigation bar is visible and functional. Delivers value by reducing friction in navigation.

**Acceptance Scenarios**:

1. **Given** a user is on the Dashboard screen, **When** they view the screen, **Then** the bottom navigation bar is visible and functional
2. **Given** a user is on the Expense List screen, **When** they view the screen, **Then** the bottom navigation bar is visible and functional
3. **Given** a user is on the Settings screen, **When** they view the screen, **Then** the bottom navigation bar is visible and functional
4. **Given** a user is on a detail screen (e.g., adding an expense), **When** they view the screen, **Then** the bottom navigation bar is visible or there is a clear way to return to a screen with bottom navigation
5. **Given** a user taps any bottom navigation item from any screen, **When** the navigation occurs, **Then** the selected screen loads with the bottom navigation bar visible

---

### User Story 3 - Recent Expenses on Dashboard (Priority: P3)

Users want to quickly view their most recent expenses directly from the Dashboard without navigating to the full expense list. This provides an at-a-glance view of recent activity.

**Why this priority**: Enhances the Dashboard's usefulness as a central hub for information. While valuable, this is less critical than fixing the core navigation structure. It can be implemented after the navigation improvements are in place.

**Independent Test**: Can be tested by opening the Dashboard and verifying that a list of recent expenses is displayed with relevant details (amount, date, description). Delivers value by providing quick access to recent activity without extra navigation.

**Acceptance Scenarios**:

1. **Given** a user has created expenses in the system, **When** they open the Dashboard, **Then** they see a list of the most recent expenses (up to 5-10 items)
2. **Given** a user views the recent expenses list on the Dashboard, **When** they examine each item, **Then** they see key information (date, amount, description, category)
3. **Given** a user sees recent expenses on the Dashboard, **When** they tap on an expense item, **Then** they are navigated to the detailed view of that expense
4. **Given** a user has no expenses yet, **When** they view the Dashboard, **Then** they see a message indicating no recent expenses and a prompt to add their first expense
5. **Given** a user views the recent expenses section on the Dashboard, **When** they want to see all expenses, **Then** there is a clear action (e.g., "Vedi tutte" button) to navigate to the full expense list

---

### Edge Cases

- When users navigate deep into the app (e.g., Settings → Profile → Edit Profile), the bottom navigation remains visible and functional, allowing users to jump to any main section at any time
- When switching between bottom navigation tabs, the system preserves each tab's state (scroll position, filters, selections) so users return to exactly where they left off
- When a user is creating or editing an expense and taps a bottom navigation item, the system shows a confirmation dialog if unsaved changes exist, otherwise navigates freely
- Long text in the recent expenses list (descriptions, amounts, currencies) is truncated with ellipsis (...) to maintain clean list formatting while indicating more content is available
- When a user taps on a recent expense that has been deleted by another group member, the system displays an informative message explaining the deletion and automatically refreshes the recent expenses list to remove the stale item

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST replace the current bottom navigation structure to include Dashboard, Spese (Expenses), and Impostazioni (Settings) as the three main tabs
- **FR-002**: System MUST provide access to Profile and Group management through the Impostazioni (Settings) tab
- **FR-003**: System MUST display the bottom navigation bar on all screens throughout the app, including deep navigation screens (e.g., Profile edit screens, expense detail screens), enabling users to jump to any main section at any time
- **FR-004**: System MUST preserve each tab's complete state (including scroll position, applied filters, and user selections) when switching between bottom navigation tabs, allowing users to return to exactly where they left off
- **FR-005**: System MUST display a list of recent expenses on the Dashboard screen
- **FR-006**: System MUST show at least the 5 most recent expenses, with a maximum of 10 items displayed
- **FR-007**: System MUST display essential expense information for each recent expense item including date, amount, and description
- **FR-007a**: System MUST truncate long text fields (descriptions, amounts, currencies) in the recent expenses list with ellipsis (...) when text exceeds available display space
- **FR-008**: Users MUST be able to tap on a recent expense to view its full details
- **FR-009**: System MUST provide a way to navigate from the recent expenses preview to the full expense list
- **FR-010**: System MUST handle the case when no expenses exist by showing an appropriate empty state message
- **FR-011**: System MUST show a confirmation dialog when a user attempts to navigate away from a screen with unsaved changes (e.g., expense creation/editing), and allow free navigation when no unsaved changes exist
- **FR-012**: System MUST handle attempts to view a deleted expense by displaying an informative message explaining the expense was deleted, then automatically refreshing the recent expenses list to remove the stale entry

### Key Entities

- **Settings Menu**: Container that provides access to Profile and Group management options
- **Recent Expense Item**: Simplified view of an expense showing essential information (date, amount, description, optionally category/icon)
- **Navigation State**: Current selected tab and screen state that persists when switching between tabs

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can access Settings, Profile, and Group screens with a maximum of 2 taps from any screen in the app
- **SC-002**: Users can navigate between Dashboard, Expenses, and Settings without needing to use back navigation
- **SC-003**: Users can view recent expenses within 1 second of opening the Dashboard
- **SC-004**: 100% of screens in the app provide visible and functional access to the bottom navigation bar
- **SC-005**: Users can access full expense details from the Dashboard with exactly 1 tap on the expense item
- **SC-006**: Navigation between tabs completes in under 300 milliseconds

## Scope *(mandatory)*

### In Scope

- Redesigning the bottom navigation bar to include Dashboard, Spese, and Impostazioni tabs
- Creating a new Settings screen that acts as a hub for Profile and Group access
- Ensuring bottom navigation bar visibility across all primary screens
- Adding a recent expenses list component to the Dashboard
- Implementing navigation from recent expenses to expense details
- Providing a link from recent expenses preview to the full expense list

### Out of Scope

- Redesigning the visual appearance or styling of existing screens beyond navigation changes
- Adding new filtering or sorting options to the expense list
- Modifying how expenses are created, edited, or deleted
- Adding new settings options beyond Profile and Group
- Implementing notifications or alerts for new expenses
- Adding user preferences for how many recent expenses to display (will use a fixed default)
- Multi-language support changes (will maintain existing Italian labels)
- Contextual or adaptive bottom navigation visibility (e.g., hiding navigation based on screen type or user context) - this iteration uses persistent visibility on all screens

## Assumptions *(mandatory)*

- The app currently has a bottom navigation system in place that can be modified
- Profile and Group screens already exist and function correctly
- The Dashboard screen already exists but needs the recent expenses component added
- Expense data is already available and can be queried to retrieve recent items
- Users are familiar with standard mobile app navigation patterns (bottom navigation bars)
- The app uses a navigation framework that supports nested navigation and state preservation
- Recent expenses will be sorted by creation date (most recent first) by default
- The app operates in Italian language (based on existing labels like "Spese", "Profilo", "Gruppo")

## Dependencies *(mandatory)*

- Existing Profile screen implementation must remain functional when accessed through Settings
- Existing Group screen implementation must remain functional when accessed through Settings
- Expense data access layer must support querying for recent expenses
- Navigation framework must support the proposed structure with settings as a hub
- Dashboard screen must have space to accommodate the recent expenses list without overcrowding

## Risks & Considerations *(mandatory)*

### User Experience Risks

- **Navigation Disruption**: Users accustomed to the current navigation structure may initially be confused by the new Settings tab location for Profile and Group
  - *Mitigation*: Consider an in-app tooltip or brief onboarding message explaining the new navigation structure on first launch after update

- **Screen Clutter**: Adding recent expenses to the Dashboard could make the screen feel crowded if not designed carefully
  - *Mitigation*: Limit the number of displayed items and use clear visual hierarchy to separate sections

### Technical Risks

- **State Management Complexity**: Preserving navigation state across tab switches may introduce complexity in state management
  - *Mitigation*: Ensure proper testing of navigation flows and state preservation

- **Performance Impact**: Loading recent expenses on Dashboard screen load could impact performance if expense queries are slow
  - *Mitigation*: Implement efficient data fetching and consider caching strategies

### Migration Risks

- **Navigation Breaking Changes**: Existing deep links or saved navigation states may break with the new structure
  - *Mitigation*: Test all navigation entry points and update any deep linking logic

## Open Questions

*No open questions at this time. The specification is based on standard mobile app navigation patterns and the existing app structure. Any clarifications needed during implementation should be documented in the plan phase.*
