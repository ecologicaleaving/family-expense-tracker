-- Migration 056: Migrate Manual Budgets to Category Budgets
--
-- This migration migrates existing manual group and personal budgets to the
-- category-only system by creating "Altro" category budgets with the total amounts.
--
-- Migration strategy:
-- 1. For each group budget, create/update "Altro" category budget with the amount
-- 2. For each personal budget, create member contribution to "Altro" category
-- 3. Mark original records as deprecated

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

-- Function to migrate a single personal budget to member contribution
CREATE OR REPLACE FUNCTION migrate_personal_budget_to_contribution(
    p_personal_budget_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_personal_budget RECORD;
    v_system_category_id UUID;
    v_category_budget_id UUID;
    v_existing_contribution_id UUID;
BEGIN
    -- Get the personal budget to migrate
    SELECT * INTO v_personal_budget
    FROM personal_budgets
    WHERE id = p_personal_budget_id
    AND is_deprecated = true;

    IF v_personal_budget IS NULL THEN
        RETURN;
    END IF;

    -- Get system category ID
    SELECT id INTO v_system_category_id
    FROM expense_categories
    WHERE group_id = v_personal_budget.group_id
    AND is_system_category = true
    AND is_default = true
    LIMIT 1;

    IF v_system_category_id IS NULL THEN
        RAISE WARNING 'System category not found for group %, skipping', v_personal_budget.group_id;
        RETURN;
    END IF;

    -- Get or create "Altro" category budget
    SELECT id INTO v_category_budget_id
    FROM category_budgets
    WHERE category_id = v_system_category_id
    AND group_id = v_personal_budget.group_id
    AND year = v_personal_budget.year
    AND month = v_personal_budget.month;

    IF v_category_budget_id IS NULL THEN
        -- Create category budget if it doesn't exist
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
            v_personal_budget.group_id,
            v_personal_budget.amount, -- Initialize with this user's budget
            v_personal_budget.month,
            v_personal_budget.year,
            v_personal_budget.user_id,
            true,
            'FIXED'
        )
        RETURNING id INTO v_category_budget_id;
    END IF;

    -- Check if contribution already exists
    SELECT id INTO v_existing_contribution_id
    FROM member_budget_contributions
    WHERE category_budget_id = v_category_budget_id
    AND user_id = v_personal_budget.user_id;

    IF v_existing_contribution_id IS NULL THEN
        -- Create member contribution
        INSERT INTO member_budget_contributions (
            category_budget_id,
            user_id,
            type,
            fixed_amount,
            created_at,
            updated_at
        ) VALUES (
            v_category_budget_id,
            v_personal_budget.user_id,
            'FIXED',
            v_personal_budget.amount,
            v_personal_budget.created_at,
            NOW()
        );
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
