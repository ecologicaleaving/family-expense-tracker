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

    -- If no system category exists, raise exception
    IF v_system_category_id IS NULL THEN
        RAISE EXCEPTION 'System category "Varie" not found for group %', p_group_id;
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
