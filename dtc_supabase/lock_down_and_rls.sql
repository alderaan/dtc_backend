
--==============================================================================
--  PART 1: SYSTEM-WIDE SECURITY SETUP (RUN ONCE)
--  Establishes a "default-deny" posture for the entire public schema.
--==============================================================================

-- Revoke all existing privileges from the standard 'authenticated' role.
-- This immediately prevents logged-in users from accessing anything without an explicit GRANT.
REVOKE ALL ON SCHEMA public FROM authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM authenticated;

-- Alter the default privileges for any *future* objects created in the public schema.
-- This ensures that new tables, views, etc., are locked down by default upon creation.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM authenticated;

-- Grant back the absolute minimum permission: the ability to "use" the schema.
-- Without this, the 'authenticated' role cannot see any objects, even if granted access.
GRANT USAGE ON SCHEMA public TO authenticated;


--==============================================================================
--  PART 2: USER & ROLE MANAGEMENT
--==============================================================================

-- CHECK ROLE
SELECT id, email, raw_app_meta_data->'permissions' as permissions
FROM auth.users
WHERE id = 'USER_UUID_HERE'; -- e.g., 'd4e637e8-26a4-41f8-91a9-08334be01b29'

-- ADD ROLE
UPDATE auth.users
SET
  raw_app_meta_data = jsonb_set(
    COALESCE(raw_app_meta_data, '{}'::jsonb),
    '{permissions}',
    COALESCE(raw_app_meta_data->'permissions', '[]'::jsonb) || '"dtc_profile_cleaner"'::jsonb,
    true
  )
WHERE
  id = 'USER_UUID_HERE'
  AND (
    raw_app_meta_data->'permissions' IS NULL OR
    NOT (raw_app_meta_data->'permissions' @> '"dtc_profile_cleaner"'::jsonb)
  );

-- REMOVE ROLE
UPDATE auth.users
SET raw_app_meta_data = jsonb_set(
    raw_app_meta_data,
    '{permissions}',
    (raw_app_meta_data->'permissions') - 'dtc_profile_cleaner'
)
WHERE id = 'USER_UUID_HERE';


--==============================================================================
--  GRANT SELECT
--==============================================================================

GRANT SELECT ON TABLE public.dtc_profiles TO authenticated;
GRANT SELECT ON TABLE public.dtc_profiles_with_latest_details TO authenticated;
GRANT SELECT ON TABLE public.dtc_profile_details TO authenticated;
GRANT SELECT ON TABLE public.dtc_keywords TO authenticated;
GRANT SELECT ON TABLE public.dtc_profile_keywords TO authenticated;
GRANT UPDATE (status, notes) ON TABLE public.dtc_profiles TO authenticated;
GRANT INSERT ON TABLE public.dtc_profiles TO authenticated;



--==============================================================================
--  CREATE POLICIES
--==============================================================================

-- dtc_profiles
ALTER TABLE public.dtc_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dtc_profiles FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow admins full access" ON public.dtc_profiles;
CREATE POLICY "Allow admins full access"
ON public.dtc_profiles FOR ALL TO authenticated
USING ( (auth.jwt()->'app_metadata'->'permissions')::jsonb ? 'admin' )
WITH CHECK ( (auth.jwt()->'app_metadata'->'permissions')::jsonb ? 'admin' );

DROP POLICY IF EXISTS "Allow cleaners to view, insert and update profiles" ON public.dtc_profiles;

CREATE POLICY "Allow cleaners to view, insert and update profiles"
ON public.dtc_profiles FOR ALL TO authenticated
USING ( (auth.jwt()->'app_metadata'->'permissions')::jsonb ? 'dtc_profile_cleaner' )
WITH CHECK ( (auth.jwt()->'app_metadata'->'permissions')::jsonb ? 'dtc_profile_cleaner' );


-- dtc_profile_details
ALTER TABLE public.dtc_profile_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dtc_profile_details FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow cleaners and admins to read details" ON public.dtc_profile_details;
CREATE POLICY "Allow cleaners and admins to read details"
ON public.dtc_profile_details FOR SELECT TO authenticated
USING (
  (auth.jwt()->'app_metadata'->'permissions')::jsonb ?| array['admin', 'dtc_profile_cleaner']
);


-- dtc_keywords
ALTER TABLE public.dtc_keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dtc_keywords FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow cleaners and admins to read keywords" ON public.dtc_keywords;
CREATE POLICY "Allow cleaners and admins to read keywords"
ON public.dtc_keywords FOR SELECT TO authenticated
USING (
  (auth.jwt()->'app_metadata'->'permissions')::jsonb ?| array['admin', 'dtc_profile_cleaner']
);


-- dtc_profile_keywords
ALTER TABLE public.dtc_profile_keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dtc_profile_keywords FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow cleaners and admins to read profile keywords" ON public.dtc_profile_keywords;
CREATE POLICY "Allow cleaners and admins to read profile keywords"
ON public.dtc_profile_keywords FOR SELECT TO authenticated
USING (
  (auth.jwt()->'app_metadata'->'permissions')::jsonb ?| array['admin', 'dtc_profile_cleaner']
);

-- dtc_profiles_with_latest_details
ALTER VIEW public.dtc_profiles_with_latest_details SET (security_invoker = true);


-- Other

-- Test if normal user can access data
curl -H "apikey: ANON_KEY" \
     -H "Authorization: Bearer ANON_KEY" \
     "https://supabase.correlion.ai/rest/v1/dtc_profiles_with_latest_details"