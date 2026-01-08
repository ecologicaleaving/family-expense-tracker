-- Migration 052: Deprecate Manual Budget Tables
--
-- This migration marks the group_budgets and personal_budgets tables as deprecated
-- in preparation for the category-only budget system. The tables are kept for
-- historical data but new inserts are discouraged.
--
-- Changes:
-- 1. Add is_deprecated column to group_budgets
-- 2. Add is_deprecated column to personal_budgets
-- 3. Mark all existing records as deprecated
-- 4. Add comments explaining the deprecation

-- Add is_deprecated flag to group_budgets
ALTER TABLE group_budgets
ADD COLUMN IF NOT EXISTS is_deprecated BOOLEAN DEFAULT false;

-- Add is_deprecated flag to personal_budgets
ALTER TABLE personal_budgets
ADD COLUMN IF NOT EXISTS is_deprecated BOOLEAN DEFAULT false;

-- Mark all existing group budgets as deprecated (they will be migrated to categories)
UPDATE group_budgets
SET is_deprecated = true
WHERE is_deprecated = false;

-- Mark all existing personal budgets as deprecated (they will be migrated to categories)
UPDATE personal_budgets
SET is_deprecated = true
WHERE is_deprecated = false;

-- Add table comments explaining deprecation
COMMENT ON TABLE group_budgets IS
'DEPRECATED: Group budgets are now calculated as SUM of category budgets. This table is kept for historical data only. Use category_budgets table for new budget management.';

COMMENT ON TABLE personal_budgets IS
'DEPRECATED: Personal budgets are now calculated as SUM of user contributions in category budgets. This table is kept for historical data only. Use member_budget_contributions table for new budget management.';

COMMENT ON COLUMN group_budgets.is_deprecated IS
'Flag indicating this is a deprecated manual budget. All new budgets should use category_budgets instead.';

COMMENT ON COLUMN personal_budgets.is_deprecated IS
'Flag indicating this is a deprecated manual budget. All new budgets should use category budgets with member contributions instead.';

-- Create index for querying non-deprecated records (for transition period)
CREATE INDEX IF NOT EXISTS idx_group_budgets_deprecated
ON group_budgets(group_id, year, month, is_deprecated);

CREATE INDEX IF NOT EXISTS idx_personal_budgets_deprecated
ON personal_budgets(user_id, year, month, is_deprecated);
-- Migration 053: Add System Category Flag
--
-- This migration adds support for system-managed categories that cannot be deleted.
-- The "Varie" (Other/Misc) category is marked as a system category and will serve
-- as the catch-all for uncategorized expenses.
--
-- Changes:
-- 1. Add is_system_category column to expense_categories
-- 2. Mark existing "Varie" category as system category
-- 3. Add constraint to prevent deletion of system categories

-- Add is_system_category flag to expense_categories
ALTER TABLE expense_categories
ADD COLUMN IF NOT EXISTS is_system_category BOOLEAN DEFAULT false;

-- Mark "Varie" as a system category
-- This is the catch-all category for uncategorized expenses
UPDATE expense_categories
SET is_system_category = true
WHERE name = 'Varie' AND is_default = true;

-- Note: If "Varie" doesn't exist in any group, it should be created by the app
-- We don't create it here because expense_categories requires group_id
-- The ensure_altro_category_budget function in migration 054 will handle creation per group

-- Add table comment
COMMENT ON COLUMN expense_categories.is_system_category IS
'Flag indicating this is a system-managed category (like "Varie"/"Other") that cannot be deleted. System categories are used for special purposes like catch-all for uncategorized expenses.';

-- Create index for efficient querying of system categories
CREATE INDEX IF NOT EXISTS idx_expense_categories_system
ON expense_categories(is_system_category)
WHERE is_system_category = true;

-- Add RLS policy to prevent deletion of system categories
-- First, check if the policy exists, if not create it
DO $$
BEGIN
    -- Drop existing delete policy if it exists
    DROP POLICY IF EXISTS "Group admins can delete non-default categories" ON expense_categories;

    -- Create new delete policy that prevents deletion of system categories
    CREATE POLICY "Group admins can delete non-system categories"
    ON expense_categories
    FOR DELETE
    TO authenticated
    USING (
        is_system_category = false
        AND is_default = false
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND group_id = expense_categories.group_id
            AND is_group_admin = true
        )
    );
END $$;
-- Migration 054: Ensure Altro Category Budget Function
--
-- This migration creates an RPC function to ensure the "Altro" (Varie) system
-- category has a budget entry for a given group/month/year. If the budget doesn't
-- exist, it creates one with amount = 0.
--
-- This function is called automatically when loading budget composition to ensure
-- the catch-all category always has a budget entry.

-- Drop function if exists to allow recreation
DROP FUNCTION IF EXISTS ensure_altro_category_budget(UUID, INTEGER, INTEGER);

-- Create function to ensure "Altro" category budget exists
CREATE OR REPLACE FUNCTION ensure_altro_category_budget(
    p_group_id UUID,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    id UUID,
    category_id UUID,
    group_id UUID,
    amount INTEGER,
    month INTEGER,
    year INTEGER,
    created_by UUID,
    is_group_budget BOOLEAN,
    budget_type TEXT,
    percentage_of_group NUMERIC,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_system_category_id UUID;
    v_current_user_id UUID;
    v_budget_id UUID;
BEGIN
    -- Get current user ID
    v_current_user_id := auth.uid();

    -- Get the system category ID (Varie/Altro)
    SELECT ec.id INTO v_system_category_id
    FROM expense_categories ec
    WHERE ec.group_id = p_group_id
    AND ec.is_system_category = true
    AND ec.is_default = true
    LIMIT 1;

    -- If no system category exists, create it
    IF v_system_category_id IS NULL THEN
        INSERT INTO expense_categories (
            name,
            group_id,
            is_default,
            is_system_category,
            created_by
        ) VALUES (
            'Varie',
            p_group_id,
            true,
            true,
            v_current_user_id
        )
        RETURNING id INTO v_system_category_id;

        RAISE NOTICE 'Created system category "Varie" for group %', p_group_id;
    END IF;

    -- Check if budget already exists
    SELECT cb.id INTO v_budget_id
    FROM category_budgets cb
    WHERE cb.category_id = v_system_category_id
    AND cb.group_id = p_group_id
    AND cb.year = p_year
    AND cb.month = p_month;

    -- If budget doesn't exist, create it with amount = 0
    IF v_budget_id IS NULL THEN
        INSERT INTO category_budgets (
            category_id,
            group_id,
            amount,
            month,
            year,
            created_by,
            is_group_budget,
            budget_type
        ) VALUES (
            v_system_category_id,
            p_group_id,
            0, -- Start with 0, users can update later
            p_month,
            p_year,
            v_current_user_id,
            true, -- System category budget is always group budget
            'FIXED'
        )
        RETURNING category_budgets.id INTO v_budget_id;
    END IF;

    -- Return the budget (existing or newly created)
    RETURN QUERY
    SELECT
        cb.id,
        cb.category_id,
        cb.group_id,
        cb.amount,
        cb.month,
        cb.year,
        cb.created_by,
        cb.is_group_budget,
        cb.budget_type,
        cb.percentage_of_group,
        cb.created_at,
        cb.updated_at
    FROM category_budgets cb
    WHERE cb.id = v_budget_id;
END;
$$;

-- Add comment
COMMENT ON FUNCTION ensure_altro_category_budget(UUID, INTEGER, INTEGER) IS
'Ensures the "Altro" (Varie) system category has a budget entry for the specified group/month/year. Creates budget with amount=0 if it does not exist. Returns the budget record.';

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION ensure_altro_category_budget(UUID, INTEGER, INTEGER) TO authenticated;
-- Migration 055: Create Budget Total Views
--
-- This migration creates database views to efficiently calculate budget totals
-- from category budgets and member contributions. These views replace the manual
-- group_budgets and personal_budgets tables with computed values.
--
-- Views created:
-- 1. v_group_budget_totals: Total budget per group/month/year (SUM of category budgets)
-- 2. v_personal_budget_totals: Total budget per user/month/year (SUM of member contributions)

-- Drop views if they exist to allow recreation
DROP VIEW IF EXISTS v_group_budget_totals CASCADE;
DROP VIEW IF EXISTS v_personal_budget_totals CASCADE;

-- View 1: Group Budget Totals
-- Calculates total budget for each group/month/year as SUM of all category budgets
CREATE OR REPLACE VIEW v_group_budget_totals AS
SELECT
    cb.group_id,
    cb.year,
    cb.month,
    SUM(cb.amount) as total_amount_cents,
    COUNT(cb.id) as category_count,
    COUNT(DISTINCT cb.category_id) as distinct_categories,
    MIN(cb.created_at) as first_budget_created_at,
    MAX(cb.updated_at) as last_budget_updated_at
FROM category_budgets cb
WHERE cb.is_group_budget = true
GROUP BY cb.group_id, cb.year, cb.month;

-- View 2: Personal Budget Totals
-- Calculates total budget for each user/month/year as SUM of:
-- 1. Personal (non-group) category budgets created by the user
-- 2. User's share of group category budgets (from budget_percentage_history)
CREATE OR REPLACE VIEW v_personal_budget_totals AS
SELECT
    cb.created_by as user_id,
    cb.group_id,
    cb.year,
    cb.month,
    SUM(cb.amount) as total_amount_cents,
    COUNT(DISTINCT cb.category_id) as category_count,
    COUNT(cb.id) as contribution_count,
    MIN(cb.created_at) as first_contribution_created_at,
    MAX(cb.updated_at) as last_contribution_updated_at
FROM category_budgets cb
WHERE cb.is_group_budget = false  -- Only personal budgets
GROUP BY cb.created_by, cb.group_id, cb.year, cb.month;

-- Add comments
COMMENT ON VIEW v_group_budget_totals IS
'Calculated group budget totals from category budgets. Replaces manual group_budgets table. Total is computed as SUM of all category budget amounts for each group/month/year.';

COMMENT ON VIEW v_personal_budget_totals IS
'Calculated personal budget totals from member contributions. Replaces manual personal_budgets table. Total is computed as SUM of user contributions across all categories for each user/month/year.';

-- Grant select permissions
GRANT SELECT ON v_group_budget_totals TO authenticated;
GRANT SELECT ON v_personal_budget_totals TO authenticated;

-- Create helper function to get group budget total
CREATE OR REPLACE FUNCTION get_group_budget_total(
    p_group_id UUID,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT COALESCE(total_amount_cents, 0)
    FROM v_group_budget_totals
    WHERE group_id = p_group_id
    AND year = p_year
    AND month = p_month;
$$;

-- Create helper function to get personal budget total
CREATE OR REPLACE FUNCTION get_personal_budget_total(
    p_user_id UUID,
    p_group_id UUID,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT COALESCE(total_amount_cents, 0)
    FROM v_personal_budget_totals
    WHERE user_id = p_user_id
    AND group_id = p_group_id
    AND year = p_year
    AND month = p_month;
$$;

-- Add comments for functions
COMMENT ON FUNCTION get_group_budget_total(UUID, INTEGER, INTEGER) IS
'Helper function to get total group budget for a specific group/month/year. Returns 0 if no budgets exist.';

COMMENT ON FUNCTION get_personal_budget_total(UUID, UUID, INTEGER, INTEGER) IS
'Helper function to get total personal budget for a specific user/group/month/year. Returns 0 if no contributions exist.';

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_group_budget_total(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_personal_budget_total(UUID, UUID, INTEGER, INTEGER) TO authenticated;
-- Migration 056: Migrate Manual Budgets to Category Budgets
--
-- This migration migrates existing manual group and personal budgets to the
-- category-only system by creating "Altro" category budgets with the total amounts.
--
-- Migration strategy:
-- 1. For each group budget, create/update "Altro" category budget with the amount
-- 2. For each personal budget, create member contribution to "Altro" category
-- 3. Mark original records as deprecated

-- Drop old unique constraint if it still exists (from migration 026)
-- Migration 037 should have dropped this, but use the actual constraint name
DO $$
BEGIN
    -- Drop the old constraint by its actual name
    ALTER TABLE category_budgets
    DROP CONSTRAINT IF EXISTS category_budgets_category_id_group_id_year_month_key;

    -- Ensure the new constraint exists (from migration 037)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'category_budgets_unique_budget'
    ) THEN
        ALTER TABLE category_budgets
        ADD CONSTRAINT category_budgets_unique_budget
        UNIQUE(category_id, group_id, year, month, is_group_budget, user_id);
    END IF;
END $$;

-- Function to migrate a single group budget to "Altro" category
CREATE OR REPLACE FUNCTION migrate_group_budget_to_altro(
    p_group_budget_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_group_budget RECORD;
    v_system_category_id UUID;
    v_existing_budget_id UUID;
BEGIN
    -- Get the group budget to migrate
    SELECT * INTO v_group_budget
    FROM group_budgets
    WHERE id = p_group_budget_id
    AND is_deprecated = true; -- Only migrate deprecated budgets

    -- Skip if budget not found
    IF v_group_budget IS NULL THEN
        RETURN;
    END IF;

    -- Get system category ID for this group
    SELECT id INTO v_system_category_id
    FROM expense_categories
    WHERE group_id = v_group_budget.group_id
    AND is_system_category = true
    AND is_default = true
    LIMIT 1;

    -- Skip if system category doesn't exist
    IF v_system_category_id IS NULL THEN
        RAISE WARNING 'System category not found for group %, skipping migration', v_group_budget.group_id;
        RETURN;
    END IF;

    -- Check if "Altro" budget already exists for this month/year
    SELECT id INTO v_existing_budget_id
    FROM category_budgets
    WHERE category_id = v_system_category_id
    AND group_id = v_group_budget.group_id
    AND year = v_group_budget.year
    AND month = v_group_budget.month;

    IF v_existing_budget_id IS NULL THEN
        -- Create new "Altro" category budget with the group budget amount
        INSERT INTO category_budgets (
            category_id,
            group_id,
            amount,
            month,
            year,
            created_by,
            is_group_budget,
            budget_type,
            created_at,
            updated_at
        ) VALUES (
            v_system_category_id,
            v_group_budget.group_id,
            v_group_budget.amount,
            v_group_budget.month,
            v_group_budget.year,
            v_group_budget.created_by,
            true,
            'FIXED',
            v_group_budget.created_at,
            NOW()
        );
    ELSE
        -- Update existing "Altro" budget (add the amount)
        UPDATE category_budgets
        SET amount = amount + v_group_budget.amount,
            updated_at = NOW()
        WHERE id = v_existing_budget_id;
    END IF;

    RAISE NOTICE 'Migrated group budget % (€% → Altro category)',
        p_group_budget_id, v_group_budget.amount / 100.0;
END;
$$;

-- Function to migrate a single personal budget to personal category budget
CREATE OR REPLACE FUNCTION migrate_personal_budget_to_contribution(
    p_personal_budget_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_personal_budget RECORD;
    v_user_group_id UUID;
    v_system_category_id UUID;
    v_existing_budget_id UUID;
BEGIN
    -- Get the personal budget to migrate
    SELECT * INTO v_personal_budget
    FROM personal_budgets
    WHERE id = p_personal_budget_id
    AND is_deprecated = true;

    IF v_personal_budget IS NULL THEN
        RETURN;
    END IF;

    -- Get user's group_id from profiles table
    SELECT group_id INTO v_user_group_id
    FROM profiles
    WHERE id = v_personal_budget.user_id;

    IF v_user_group_id IS NULL THEN
        RAISE WARNING 'User % has no group, skipping personal budget migration', v_personal_budget.user_id;
        RETURN;
    END IF;

    -- Get system category ID
    SELECT id INTO v_system_category_id
    FROM expense_categories
    WHERE group_id = v_user_group_id
    AND is_system_category = true
    AND is_default = true
    LIMIT 1;

    IF v_system_category_id IS NULL THEN
        RAISE WARNING 'System category not found for group %, skipping', v_user_group_id;
        RETURN;
    END IF;

    -- Check if personal "Altro" budget already exists for this user/month/year
    SELECT id INTO v_existing_budget_id
    FROM category_budgets
    WHERE category_id = v_system_category_id
    AND group_id = v_user_group_id
    AND year = v_personal_budget.year
    AND month = v_personal_budget.month
    AND user_id = v_personal_budget.user_id  -- Must match user_id for personal budgets
    AND is_group_budget = false;  -- Personal budget

    IF v_existing_budget_id IS NULL THEN
        -- Create personal category budget for this user
        INSERT INTO category_budgets (
            category_id,
            group_id,
            amount,
            month,
            year,
            created_by,
            is_group_budget,
            budget_type,
            user_id,  -- Required for personal budgets
            created_at,
            updated_at
        ) VALUES (
            v_system_category_id,
            v_user_group_id,
            v_personal_budget.amount,
            v_personal_budget.month,
            v_personal_budget.year,
            v_personal_budget.user_id,
            false,  -- Personal budget, not group
            'FIXED',
            v_personal_budget.user_id,  -- Set user_id for personal budget
            v_personal_budget.created_at,
            NOW()
        );
    ELSE
        -- Update existing budget amount
        UPDATE category_budgets
        SET amount = v_personal_budget.amount,
            updated_at = NOW()
        WHERE id = v_existing_budget_id;
    END IF;

    RAISE NOTICE 'Migrated personal budget % for user % (€%)',
        p_personal_budget_id, v_personal_budget.user_id, v_personal_budget.amount / 100.0;
END;
$$;

-- Migrate all existing group budgets
DO $$
DECLARE
    v_budget RECORD;
BEGIN
    FOR v_budget IN
        SELECT id FROM group_budgets WHERE is_deprecated = true
    LOOP
        PERFORM migrate_group_budget_to_altro(v_budget.id);
    END LOOP;

    RAISE NOTICE 'Group budget migration completed';
END $$;

-- Migrate all existing personal budgets
DO $$
DECLARE
    v_budget RECORD;
BEGIN
    FOR v_budget IN
        SELECT id FROM personal_budgets WHERE is_deprecated = true
    LOOP
        PERFORM migrate_personal_budget_to_contribution(v_budget.id);
    END LOOP;

    RAISE NOTICE 'Personal budget migration completed';
END $$;

-- Add comments
COMMENT ON FUNCTION migrate_group_budget_to_altro(UUID) IS
'Migrates a deprecated group budget to an "Altro" category budget. Creates or updates the category budget with the amount.';

COMMENT ON FUNCTION migrate_personal_budget_to_contribution(UUID) IS
'Migrates a deprecated personal budget to a member contribution in the "Altro" category. Creates contribution and category budget if needed.';
-- Migration 057: Assign Uncategorized Expenses to Altro
--
-- This migration assigns all expenses without a category (category_id IS NULL)
-- to the "Altro" (Varie) system category. This ensures all expenses are categorized
-- and properly tracked in the category-based budget system.
--
-- Changes:
-- 1. Update existing expenses with NULL category_id to use "Altro" category
-- 2. Create trigger to auto-assign "Altro" to new expenses with NULL category

-- Function to get "Altro" category ID for a group
CREATE OR REPLACE FUNCTION get_altro_category_id(p_group_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT id
    FROM expense_categories
    WHERE group_id = p_group_id
    AND is_system_category = true
    AND is_default = true
    LIMIT 1;
$$;

-- Update all existing expenses with NULL category to use "Altro"
DO $$
DECLARE
    v_expense RECORD;
    v_altro_category_id UUID;
    v_updated_count INTEGER := 0;
BEGIN
    -- Loop through all uncategorized expenses
    FOR v_expense IN
        SELECT id, group_id
        FROM expenses
        WHERE category_id IS NULL
    LOOP
        -- Get "Altro" category for this expense's group
        v_altro_category_id := get_altro_category_id(v_expense.group_id);

        -- Update expense if "Altro" category exists
        IF v_altro_category_id IS NOT NULL THEN
            UPDATE expenses
            SET category_id = v_altro_category_id,
                updated_at = NOW()
            WHERE id = v_expense.id;

            v_updated_count := v_updated_count + 1;
        ELSE
            RAISE WARNING 'No Altro category found for group %, expense % not updated',
                v_expense.group_id, v_expense.id;
        END IF;
    END LOOP;

    RAISE NOTICE 'Assigned % uncategorized expenses to Altro category', v_updated_count;
END $$;

-- Create trigger function to auto-assign "Altro" for new expenses
CREATE OR REPLACE FUNCTION auto_assign_altro_category()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_altro_category_id UUID;
BEGIN
    -- Only proceed if category_id is NULL
    IF NEW.category_id IS NULL THEN
        -- Get "Altro" category for this group
        v_altro_category_id := get_altro_category_id(NEW.group_id);

        -- Assign "Altro" if it exists
        IF v_altro_category_id IS NOT NULL THEN
            NEW.category_id := v_altro_category_id;
            RAISE NOTICE 'Auto-assigned expense % to Altro category', NEW.id;
        ELSE
            RAISE WARNING 'No Altro category found for group %, cannot auto-assign', NEW.group_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_auto_assign_altro_category ON expenses;

-- Create trigger to auto-assign "Altro" on INSERT
CREATE TRIGGER trigger_auto_assign_altro_category
    BEFORE INSERT ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION auto_assign_altro_category();

-- Add comments
COMMENT ON FUNCTION get_altro_category_id(UUID) IS
'Helper function to get the "Altro" system category ID for a given group. Returns NULL if not found.';

COMMENT ON FUNCTION auto_assign_altro_category() IS
'Trigger function that automatically assigns expenses with NULL category_id to the "Altro" system category for their group.';

COMMENT ON TRIGGER trigger_auto_assign_altro_category ON expenses IS
'Automatically assigns uncategorized expenses (category_id IS NULL) to the "Altro" system category on INSERT.';

-- Create index for category_id NULL queries (before migration completes)
CREATE INDEX IF NOT EXISTS idx_expenses_null_category
ON expenses(group_id)
WHERE category_id IS NULL;
