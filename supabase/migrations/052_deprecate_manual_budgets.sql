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
