-- Migration: Add reimbursement tracking to expenses table
-- Feature: 012-expense-improvements
-- Created: 2026-01-16

-- Add reimbursement columns to expenses table
ALTER TABLE public.expenses
ADD COLUMN reimbursement_status TEXT DEFAULT 'none' NOT NULL
  CHECK (reimbursement_status IN ('none', 'reimbursable', 'reimbursed')),
ADD COLUMN reimbursed_at TIMESTAMPTZ DEFAULT NULL;

-- Add constraint: reimbursed_at required when status is reimbursed
ALTER TABLE public.expenses
ADD CONSTRAINT check_reimbursed_at_consistency
  CHECK (
    (reimbursement_status = 'reimbursed' AND reimbursed_at IS NOT NULL) OR
    (reimbursement_status != 'reimbursed' AND reimbursed_at IS NULL)
  );

-- Add index for filtering by reimbursement status (partial index for efficiency)
CREATE INDEX idx_expenses_reimbursement_status
  ON public.expenses(reimbursement_status)
  WHERE reimbursement_status != 'none';

-- Add index for period-based reimbursement queries
CREATE INDEX idx_expenses_reimbursed_at
  ON public.expenses(reimbursed_at)
  WHERE reimbursed_at IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.expenses.reimbursement_status IS
  'Reimbursement tracking: none (default), reimbursable (awaiting), reimbursed (received)';

COMMENT ON COLUMN public.expenses.reimbursed_at IS
  'Timestamp when expense was marked as reimbursed. Used for period-based budget calculations. NULL if not reimbursed.';

-- Update existing expenses to have default values
UPDATE public.expenses
SET reimbursement_status = 'none'
WHERE reimbursement_status IS NULL;
