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
