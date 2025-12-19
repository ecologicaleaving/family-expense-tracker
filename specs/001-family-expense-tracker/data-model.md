# Data Model: Family Expense Tracker

**Date**: 2025-12-19
**Feature**: 001-family-expense-tracker

## Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    User     │───────│ FamilyGroup │───────│   Invite    │
│             │  N:1  │             │  1:N  │             │
└─────────────┘       └─────────────┘       └─────────────┘
       │                     │
       │ 1:N                 │ 1:N
       ▼                     ▼
┌─────────────┐       ┌─────────────┐
│   Expense   │───────│  (implicit) │
│             │       │  via group  │
└─────────────┘       └─────────────┘
```

## Entities

### User

Represents an authenticated app user.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, auto-generated | Unique user identifier (Supabase auth.users.id) |
| email | String | Unique, required | User email address |
| display_name | String | Required, max 50 chars | User's display name shown in app |
| group_id | UUID | FK → FamilyGroup, nullable | Current family group membership |
| is_group_admin | Boolean | Default: false | Admin status in current group |
| keep_name_on_delete | Boolean | Default: true | Preference for name retention after account deletion |
| created_at | Timestamp | Auto-generated | Account creation time |
| updated_at | Timestamp | Auto-updated | Last profile update |

**Validation Rules**:
- Email must be valid format
- Display name: 2-50 characters, alphanumeric + spaces
- User can belong to only one group at a time (FR-017)

**State Transitions**:
- `no_group` → `member` (join via invite)
- `member` → `admin` (promoted or creator)
- `member` → `no_group` (leave group)
- `admin` → `member` (demoted, only if other admin exists)

---

### FamilyGroup

A collection of users sharing expenses.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, auto-generated | Unique group identifier |
| name | String | Required, max 30 chars | Group display name (e.g., "Famiglia Rossi") |
| created_by | UUID | FK → User | Original creator (first admin) |
| created_at | Timestamp | Auto-generated | Group creation time |
| updated_at | Timestamp | Auto-updated | Last group update |

**Validation Rules**:
- Name: 2-30 characters
- Must have at least one admin at all times
- Maximum 10 members (SC-008)

**Derived/Computed**:
- `member_count`: Count of users where group_id = this.id
- `admin_count`: Count of users where group_id = this.id AND is_group_admin = true

---

### Expense

A recorded spending event.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, auto-generated | Unique expense identifier |
| group_id | UUID | FK → FamilyGroup, required | Associated family group |
| user_id | UUID | FK → User, nullable | User who recorded expense (null if user deleted & anonymized) |
| user_display_name | String | Required | Denormalized name for display (preserves name after user deletion) |
| amount | Decimal | Required, > 0, precision 2 | Expense amount in EUR |
| currency | String | Default: "EUR" | Currency code (EUR only for MVP) |
| date | Date | Required | Date of expense (from receipt or manual) |
| merchant | String | Max 100 chars, nullable | Store/merchant name |
| category | Enum | Required | Expense category |
| notes | String | Max 500 chars, nullable | Optional user notes |
| receipt_image_url | String | URL, nullable | Supabase Storage URL for receipt photo |
| is_ai_extracted | Boolean | Default: false | Whether data was extracted via OCR |
| created_at | Timestamp | Auto-generated | Record creation time |
| updated_at | Timestamp | Auto-updated | Last modification time |

**Category Enum Values**:
- `food` - Alimentari
- `utilities` - Utenze
- `transport` - Trasporti
- `healthcare` - Salute
- `entertainment` - Svago
- `household` - Casa
- `other` - Altro

**Validation Rules**:
- Amount: 0.01 to 99999.99 EUR
- Date: Cannot be in future
- Merchant: Optional but recommended
- Receipt image: Max 5MB, JPEG/PNG only

**Access Control** (FR-018, FR-019):
- Creator can edit/delete own expenses
- Group admin can delete any group expense
- All group members can view group expenses

---

### Invite

A time-limited invitation code to join a group.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, auto-generated | Unique invite identifier |
| code | String | Unique, 6 chars | Shareable invite code |
| group_id | UUID | FK → FamilyGroup, required | Target group to join |
| created_by | UUID | FK → User, required | Admin who created invite |
| created_at | Timestamp | Auto-generated | Invite creation time |
| expires_at | Timestamp | Required | Expiration (created_at + 7 days) |
| used_at | Timestamp | Nullable | When invite was redeemed |
| used_by | UUID | FK → User, nullable | User who redeemed invite |

**Validation Rules** (FR-020):
- Code: 6 alphanumeric characters (A-Z, 2-9, excluding 0/O/1/I/L)
- Expires after 7 days
- Single use only
- Cannot use if group is at max capacity (10 members)

**State Transitions**:
- `active` (created_at < now < expires_at, used_at = null)
- `expired` (now > expires_at)
- `used` (used_at != null)

---

## Database Schema (Supabase PostgreSQL)

```sql
-- Users profile (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 50),
    group_id UUID REFERENCES public.family_groups(id) ON DELETE SET NULL,
    is_group_admin BOOLEAN DEFAULT false,
    keep_name_on_delete BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Family groups
CREATE TABLE public.family_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (char_length(name) BETWEEN 2 AND 30),
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expense categories enum
CREATE TYPE expense_category AS ENUM (
    'food', 'utilities', 'transport', 'healthcare',
    'entertainment', 'household', 'other'
);

-- Expenses
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    user_display_name TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0 AND amount < 100000),
    currency TEXT DEFAULT 'EUR',
    date DATE NOT NULL CHECK (date <= CURRENT_DATE),
    merchant TEXT CHECK (char_length(merchant) <= 100),
    category expense_category NOT NULL,
    notes TEXT CHECK (char_length(notes) <= 500),
    receipt_image_url TEXT,
    is_ai_extracted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Invites
CREATE TABLE public.invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL CHECK (char_length(code) = 6),
    group_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    used_by UUID REFERENCES public.profiles(id)
);

-- Indexes for common queries
CREATE INDEX idx_expenses_group_id ON public.expenses(group_id);
CREATE INDEX idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX idx_expenses_date ON public.expenses(date DESC);
CREATE INDEX idx_profiles_group_id ON public.profiles(group_id);
CREATE INDEX idx_invites_code ON public.invites(code);
CREATE INDEX idx_invites_expires_at ON public.invites(expires_at);
```

---

## Row Level Security (RLS) Policies

```sql
-- Profiles: Users can read/update own profile, read group members
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can view group members"
    ON public.profiles FOR SELECT
    USING (group_id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Family Groups: Members can view their group
ALTER TABLE public.family_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their group"
    ON public.family_groups FOR SELECT
    USING (id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Authenticated users can create groups"
    ON public.family_groups FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Expenses: Group members can view, creators can edit/delete, admins can delete
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can view expenses"
    ON public.expenses FOR SELECT
    USING (group_id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Group members can create expenses"
    ON public.expenses FOR INSERT
    WITH CHECK (group_id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Creators can update own expenses"
    ON public.expenses FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Creators can delete own expenses"
    ON public.expenses FOR DELETE
    USING (user_id = auth.uid());

CREATE POLICY "Admins can delete group expenses"
    ON public.expenses FOR DELETE
    USING (
        group_id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );

-- Invites: Admins can manage, anyone can read to validate
ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can validate invite codes"
    ON public.invites FOR SELECT
    USING (true);

CREATE POLICY "Admins can create invites"
    ON public.invites FOR INSERT
    WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );
```

---

## Local Cache Schema (Drift/SQLite)

For offline display and faster load times:

```dart
// Cached expenses for quick dashboard loading
class CachedExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get merchant => text().nullable()();
  TextColumn get category => text()();
  TextColumn get userDisplayName => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```
