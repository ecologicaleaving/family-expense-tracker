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
