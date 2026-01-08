-- Create payment_methods table
-- Feature: 011-payment-methods
-- Purpose: Store default and user-custom payment methods for expense tracking

-- Create the payment_methods table
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL,
  user_id UUID,  -- NULL for default methods, references auth.users(id) for custom methods
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Constraints
  CONSTRAINT chk_name_length CHECK (LENGTH(TRIM(name)) BETWEEN 1 AND 50),
  CONSTRAINT chk_default_no_user CHECK (
    (is_default = true AND user_id IS NULL) OR
    (is_default = false AND user_id IS NOT NULL)
  )
);

-- Create unique index for case-insensitive name uniqueness per user
CREATE UNIQUE INDEX unique_user_payment_method ON payment_methods(user_id, LOWER(name));

-- Create indexes for performance
CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id)
  WHERE user_id IS NOT NULL;

CREATE INDEX idx_payment_methods_is_default ON payment_methods(is_default)
  WHERE is_default = true;

-- Enable Row Level Security
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view default payment methods
CREATE POLICY "Users can view default payment methods"
  ON payment_methods FOR SELECT
  USING (is_default = true);

-- RLS Policy: Users can view their custom payment methods
CREATE POLICY "Users can view their custom payment methods"
  ON payment_methods FOR SELECT
  USING (user_id = auth.uid());

-- RLS Policy: Users can create their custom payment methods
CREATE POLICY "Users can create their custom payment methods"
  ON payment_methods FOR INSERT
  WITH CHECK (user_id = auth.uid() AND is_default = false);

-- RLS Policy: Users can update their custom payment methods
CREATE POLICY "Users can update their custom payment methods"
  ON payment_methods FOR UPDATE
  USING (user_id = auth.uid() AND is_default = false)
  WITH CHECK (user_id = auth.uid() AND is_default = false);

-- RLS Policy: Users can delete their custom payment methods
CREATE POLICY "Users can delete their custom payment methods"
  ON payment_methods FOR DELETE
  USING (user_id = auth.uid() AND is_default = false);

-- Trigger for updated_at timestamp
CREATE TRIGGER set_payment_methods_updated_at
  BEFORE UPDATE ON payment_methods
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Seed default payment methods
-- Using DO block to check if they already exist before inserting
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM payment_methods WHERE name = 'Contanti' AND is_default = true) THEN
    INSERT INTO payment_methods (id, name, user_id, is_default, created_at, updated_at)
    VALUES (gen_random_uuid(), 'Contanti', NULL, true, now(), now());
  END IF;

  IF NOT EXISTS (SELECT 1 FROM payment_methods WHERE name = 'Carta di Credito' AND is_default = true) THEN
    INSERT INTO payment_methods (id, name, user_id, is_default, created_at, updated_at)
    VALUES (gen_random_uuid(), 'Carta di Credito', NULL, true, now(), now());
  END IF;

  IF NOT EXISTS (SELECT 1 FROM payment_methods WHERE name = 'Bonifico' AND is_default = true) THEN
    INSERT INTO payment_methods (id, name, user_id, is_default, created_at, updated_at)
    VALUES (gen_random_uuid(), 'Bonifico', NULL, true, now(), now());
  END IF;

  IF NOT EXISTS (SELECT 1 FROM payment_methods WHERE name = 'Satispay' AND is_default = true) THEN
    INSERT INTO payment_methods (id, name, user_id, is_default, created_at, updated_at)
    VALUES (gen_random_uuid(), 'Satispay', NULL, true, now(), now());
  END IF;
END $$;
