-- Migration: Add timezone column to profiles table
-- Feature: Budget Management and Category Customization
-- User Stories: US1, US2 - Timezone-aware budget calculations
-- Date: 2026-01-01
--
-- Purpose: Store user timezone for accurate monthly budget boundary calculations
-- Budgets reset at midnight in each user's local timezone

-- Add timezone column with default UTC
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) NOT NULL DEFAULT 'UTC';

-- Backfill existing rows with UTC
UPDATE public.profiles
SET timezone = 'UTC'
WHERE timezone IS NULL OR timezone = '';

-- Create index for timezone-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_timezone
  ON public.profiles(timezone);

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.timezone IS
  'User timezone (IANA timezone identifier, e.g., "Europe/Rome"). Used for accurate monthly budget boundary calculations.';

-- Add check constraint to ensure valid timezone format
ALTER TABLE public.profiles
  ADD CONSTRAINT chk_profiles_timezone_format
  CHECK (timezone ~ '^[A-Za-z_]+/[A-Za-z_]+$' OR timezone = 'UTC');
