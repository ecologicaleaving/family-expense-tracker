-- RPC functions to bypass RLS for complex operations
-- Migration: 005_rpc_functions.sql

-- Function to create a family group (bypasses RLS)
CREATE OR REPLACE FUNCTION public.create_family_group(group_name TEXT)
RETURNS public.family_groups
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_group public.family_groups;
  user_id UUID;
BEGIN
  user_id := auth.uid();

  IF user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Create the group
  INSERT INTO public.family_groups (name, created_by)
  VALUES (group_name, user_id)
  RETURNING * INTO new_group;

  -- Update the user's profile with the group ID and admin status
  UPDATE public.profiles
  SET group_id = new_group.id, is_group_admin = true
  WHERE id = user_id;

  RETURN new_group;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_family_group(TEXT) TO authenticated;
