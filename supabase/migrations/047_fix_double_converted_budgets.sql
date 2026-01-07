-- Migration: Fix budgets that were double-converted to cents
-- Some budgets were already in cents (from manual resets using the new code)
-- before migration 045 ran. These were incorrectly multiplied by 100 again.
-- This migration detects and fixes those by dividing by 100.
--
-- Detection criteria: amount > 1000000 cents (10k euros) is likely a double conversion
-- Example: 500€ → saved as 50000 cents → migration 045 → 5000000 cents (50k euros!)

-- Fix group_budgets that were double-converted
-- Reasonable budget range: 100 cents to 1M cents (1€ to 10k€)
UPDATE public.group_budgets
SET amount = amount / 100
WHERE amount > 1000000; -- Likely double-converted if > 10k euros

-- Fix personal_budgets that were double-converted
UPDATE public.personal_budgets
SET amount = amount / 100
WHERE amount > 1000000; -- Likely double-converted if > 10k euros

-- Fix category_budgets that were double-converted
UPDATE public.category_budgets
SET amount = amount / 100
WHERE amount > 1000000; -- Likely double-converted if > 10k euros

COMMENT ON TABLE public.category_budgets IS 'Monthly budget allocations per category per group. Duplicates removed in migration 046. Double-conversions fixed in migration 047.';
