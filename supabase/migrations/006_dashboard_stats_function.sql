-- Dashboard statistics RPC function
-- Migration: 006_dashboard_stats_function.sql

CREATE OR REPLACE FUNCTION public.get_dashboard_stats(
  p_group_id UUID,
  p_period TEXT DEFAULT 'month',
  p_user_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_start_date DATE;
  v_end_date DATE;
  v_total_amount NUMERIC;
  v_expense_count INTEGER;
  v_average_expense NUMERIC;
  v_by_category JSON;
  v_by_member JSON;
  v_trend JSON;
BEGIN
  -- Calculate date range based on period
  v_end_date := CURRENT_DATE;

  CASE p_period
    WHEN 'week' THEN
      v_start_date := v_end_date - INTERVAL '7 days';
    WHEN 'year' THEN
      v_start_date := v_end_date - INTERVAL '1 year';
    ELSE -- 'month' is default
      v_start_date := v_end_date - INTERVAL '1 month';
  END CASE;

  -- Get total amount and count
  SELECT
    COALESCE(SUM(amount), 0),
    COUNT(*)
  INTO v_total_amount, v_expense_count
  FROM expenses
  WHERE group_id = p_group_id
    AND date >= v_start_date
    AND date <= v_end_date
    AND (p_user_id IS NULL OR paid_by = p_user_id);

  -- Calculate average
  v_average_expense := CASE
    WHEN v_expense_count > 0 THEN v_total_amount / v_expense_count
    ELSE 0
  END;

  -- Get breakdown by category
  SELECT COALESCE(json_agg(cat_data ORDER BY cat_data->>'total' DESC), '[]'::json)
  INTO v_by_category
  FROM (
    SELECT json_build_object(
      'category', category,
      'total', SUM(amount),
      'count', COUNT(*),
      'percentage', CASE
        WHEN v_total_amount > 0 THEN ROUND((SUM(amount) / v_total_amount * 100)::numeric, 1)
        ELSE 0
      END
    ) as cat_data
    FROM expenses
    WHERE group_id = p_group_id
      AND date >= v_start_date
      AND date <= v_end_date
      AND (p_user_id IS NULL OR paid_by = p_user_id)
    GROUP BY category
  ) subq;

  -- Get breakdown by member
  SELECT COALESCE(json_agg(mem_data ORDER BY mem_data->>'total' DESC), '[]'::json)
  INTO v_by_member
  FROM (
    SELECT json_build_object(
      'user_id', e.paid_by,
      'display_name', COALESCE(p.display_name, 'Utente'),
      'total', SUM(e.amount),
      'count', COUNT(*),
      'percentage', CASE
        WHEN v_total_amount > 0 THEN ROUND((SUM(e.amount) / v_total_amount * 100)::numeric, 1)
        ELSE 0
      END
    ) as mem_data
    FROM expenses e
    LEFT JOIN profiles p ON p.id = e.paid_by
    WHERE e.group_id = p_group_id
      AND e.date >= v_start_date
      AND e.date <= v_end_date
      AND (p_user_id IS NULL OR e.paid_by = p_user_id)
    GROUP BY e.paid_by, p.display_name
  ) subq;

  -- Get trend data
  IF p_period = 'year' THEN
    -- Monthly trend for year view
    SELECT COALESCE(json_agg(trend_data ORDER BY trend_data->>'date'), '[]'::json)
    INTO v_trend
    FROM (
      SELECT json_build_object(
        'date', date_trunc('month', date)::date,
        'total', SUM(amount),
        'count', COUNT(*)
      ) as trend_data
      FROM expenses
      WHERE group_id = p_group_id
        AND date >= v_start_date
        AND date <= v_end_date
        AND (p_user_id IS NULL OR paid_by = p_user_id)
      GROUP BY date_trunc('month', date)
    ) subq;
  ELSE
    -- Daily trend for week/month view
    SELECT COALESCE(json_agg(trend_data ORDER BY trend_data->>'date'), '[]'::json)
    INTO v_trend
    FROM (
      SELECT json_build_object(
        'date', date,
        'total', SUM(amount),
        'count', COUNT(*)
      ) as trend_data
      FROM expenses
      WHERE group_id = p_group_id
        AND date >= v_start_date
        AND date <= v_end_date
        AND (p_user_id IS NULL OR paid_by = p_user_id)
      GROUP BY date
    ) subq;
  END IF;

  -- Return complete stats object
  RETURN json_build_object(
    'start_date', v_start_date,
    'end_date', v_end_date,
    'total_amount', v_total_amount,
    'expense_count', v_expense_count,
    'average_expense', ROUND(v_average_expense::numeric, 2),
    'by_category', v_by_category,
    'by_member', v_by_member,
    'trend', v_trend
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_dashboard_stats(UUID, TEXT, UUID) TO authenticated;
