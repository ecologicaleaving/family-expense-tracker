-- Add payment method tracking to expenses
-- Feature: 011-payment-methods
-- Purpose: Add payment_method_id and payment_method_name columns to expenses table

-- Step 1: Add nullable columns to expenses
ALTER TABLE expenses
  ADD COLUMN payment_method_id UUID,
  ADD COLUMN payment_method_name TEXT;

-- Step 2: Backfill existing expenses with "Contanti" default payment method
DO $$
DECLARE
  contanti_id UUID;
BEGIN
  -- Get the ID of the "Contanti" default payment method
  SELECT id INTO contanti_id
  FROM payment_methods
  WHERE name = 'Contanti' AND is_default = true
  LIMIT 1;

  -- If "Contanti" doesn't exist, raise an error
  IF contanti_id IS NULL THEN
    RAISE EXCEPTION 'Default payment method "Contanti" not found. Run migration 052 first.';
  END IF;

  -- Update all expenses without a payment method
  UPDATE expenses
  SET
    payment_method_id = contanti_id,
    payment_method_name = 'Contanti',
    updated_at = now()
  WHERE payment_method_id IS NULL;

  -- Verify no NULL values remain
  IF EXISTS (SELECT 1 FROM expenses WHERE payment_method_id IS NULL) THEN
    RAISE EXCEPTION 'Migration failed: some expenses still have NULL payment_method_id';
  END IF;
END $$;

-- Step 3: Make payment_method_id NOT NULL (after backfill)
ALTER TABLE expenses
  ALTER COLUMN payment_method_id SET NOT NULL;

-- Step 4: Add foreign key constraint with delete protection
ALTER TABLE expenses
  ADD CONSTRAINT fk_payment_method
  FOREIGN KEY (payment_method_id)
  REFERENCES payment_methods(id)
  ON DELETE RESTRICT;  -- Prevent deletion of methods in use

-- Step 5: Create index for queries filtering by payment method
CREATE INDEX idx_expenses_payment_method ON expenses(payment_method_id);

-- Note: payment_method_name is denormalized for display performance
-- It will be updated when payment method name changes (optional consistency)
