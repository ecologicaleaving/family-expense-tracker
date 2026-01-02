-- Migration: Seed default expense categories for all existing groups
-- Feature: Budget Management and Category Customization
-- User Story: US4 - Customize Expense Categories
-- Date: 2026-01-01
--
-- Purpose: Create default categories (Food, Utilities, Transport, Healthcare, Entertainment, Other)
-- for all existing family groups in the system

-- Insert default categories for all existing groups
-- Uses INSERT...SELECT to create categories for each group
INSERT INTO public.expense_categories (group_id, name, is_default, created_by)
SELECT
  fg.id,
  category_name,
  true,
  NULL
FROM public.family_groups fg
CROSS JOIN (
  VALUES
    ('Food'),
    ('Utilities'),
    ('Transport'),
    ('Healthcare'),
    ('Entertainment'),
    ('Other')
) AS categories(category_name)
-- Avoid duplicates if migration is run multiple times
ON CONFLICT (group_id, name) DO NOTHING;

-- Verify seeding completed successfully
DO $$
DECLARE
  group_count INTEGER;
  category_count INTEGER;
  expected_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO group_count FROM public.family_groups;
  SELECT COUNT(*) INTO category_count FROM public.expense_categories WHERE is_default = true;
  expected_count := group_count * 6; -- 6 default categories per group

  IF category_count < expected_count THEN
    RAISE WARNING 'Default category seeding may be incomplete. Expected %, got %', expected_count, category_count;
  ELSE
    RAISE NOTICE 'Default categories seeded successfully: % categories for % groups', category_count, group_count;
  END IF;
END $$;
