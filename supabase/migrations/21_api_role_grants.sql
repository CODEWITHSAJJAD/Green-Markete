-- =============================================================================
-- Migration 21 — Restore standard grants for API roles (fix 42501 "forbidden")
-- =============================================================================
-- Symptom: 42501 "details: forbidden" on business creation — persists even
-- with all policies verified applied (migration 20). PostgREST returns
-- `details: forbidden` with `message: permission denied for table/function`
-- when the executing role (authenticated) lacks TABLE/SEQUENCE/FUNCTION
-- GRANTs — RLS is irrelevant if the role has no privilege at all.
--
-- Fix: apply the standard Supabase grant set (the same statements every
-- `supabase init`/base migration ships) to `anon` + `authenticated` for the
-- whole public schema, plus ALTER DEFAULT PRIVILEGES so tables created by
-- future migrations inherit them.
--
-- Safe to run any time — GRANT is idempotent. Policies from migration 20
-- are untouched.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Grants
-- -----------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON SEQUENCES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON FUNCTIONS TO anon, authenticated;

DO $mig$
BEGIN
    RAISE NOTICE 'Grants applied — authenticated and anon now have ALL on schema public (tables, sequences, functions)';
END $mig$;


-- -----------------------------------------------------------------------------
-- 2. Diagnostics — run this section if the app STILL errors, and paste the
--    result sets together with the FULL error text (especially the
--    "message" field, which names the exact table or function).
-- -----------------------------------------------------------------------------
-- SELECT table_name, grantee, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE table_schema = 'public'
--   AND grantee = 'authenticated'
--   AND table_name IN ('businesses','business_partners','user_profiles')
-- ORDER BY table_name, privilege_type;
--
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
--   AND tablename IN ('businesses','business_partners','user_profiles')
-- ORDER BY tablename;
--
-- SELECT tablename, policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND tablename IN ('businesses','business_partners','user_profiles')
-- ORDER BY tablename, cmd;
-- =============================================================================