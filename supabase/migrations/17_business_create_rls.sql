-- =============================================================================
-- Migration 17 — Allow creating a new business (fixes RLS chicken-and-egg)
-- =============================================================================
-- Symptom: "new row violates row-level security policy" on `businesses`
-- INSERT when the app creates a business (`BusinessRepository.create`).
--
-- Root cause: the app inserts the `businesses` row FIRST
-- (`business_repository.dart:25-33`, payload {name, business_type, owner_id})
-- and only afterwards inserts the owner row into `business_partners`
-- (`business_repository.dart:35-43`). Any INSERT policy that resolves the
-- business through `business_partners` (e.g. `my_business_id()` or
-- `i_am_owner()`) can never match at that moment, because the partner row
-- does not exist yet — so RLS rejects the insert.
--
-- Fix: a single INSERT policy that lets any authenticated user create a
-- business they own: `WITH CHECK (owner_id = auth.uid())`. This matches the
-- exact payload the app sends and cannot be abused to create a business
-- owned by someone else.
--
-- Note: migrations 1-14 (base schema, incl. the original `businesses`
-- policies) live in the backend repo / dashboard, so this file drops any
-- pre-existing INSERT policies by name to stay idempotent regardless of
-- what the original policy was called.
--
-- Apply via the Supabase SQL editor.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Drop any existing INSERT policies on `businesses` (name-agnostic)
-- -----------------------------------------------------------------------------
DO $mig$
DECLARE
    p RECORD;
BEGIN
    FOR p IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'businesses'
          AND cmd = 'INSERT'
    LOOP
        EXECUTE format('DROP POLICY %I ON businesses', p.policyname);
        RAISE NOTICE 'Dropped INSERT policy % on businesses', p.policyname;
    END LOOP;
END $mig$;

-- -----------------------------------------------------------------------------
-- 2. Recreate: any authenticated user may create a business they own
-- -----------------------------------------------------------------------------
CREATE POLICY "businesses_insert" ON businesses
    FOR INSERT TO authenticated
    WITH CHECK (owner_id = auth.uid());


-- =============================================================================
-- Verification (run after migration to confirm the policy)
-- =============================================================================
-- SELECT policyname, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'businesses'
--   ORDER BY cmd, policyname;
-- =============================================================================
