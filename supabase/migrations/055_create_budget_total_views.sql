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
-- Calculates total budget for each user/month/year as SUM of their contributions
CREATE OR REPLACE VIEW v_personal_budget_totals AS
SELECT
    mbc.user_id,
    cb.group_id,
    cb.year,
    cb.month,
    SUM(
        CASE
            WHEN mbc.type = 'FIXED' THEN mbc.fixed_amount
            WHEN mbc.type = 'PERCENTAGE' THEN mbc.calculated_amount
            ELSE 0
        END
    ) as total_amount_cents,
    COUNT(DISTINCT cb.category_id) as category_count,
    COUNT(mbc.id) as contribution_count,
    MIN(mbc.created_at) as first_contribution_created_at,
    MAX(mbc.updated_at) as last_contribution_updated_at
FROM member_budget_contributions mbc
JOIN category_budgets cb ON cb.id = mbc.category_budget_id
WHERE cb.is_group_budget = true
GROUP BY mbc.user_id, cb.group_id, cb.year, cb.month;

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
