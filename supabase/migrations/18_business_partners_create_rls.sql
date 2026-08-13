-- =============================================================================
-- Migration 18 — Allow the owner's first business_partner row (RLS fix #2)
-- =============================================================================
-- Symptom: after migration 17, creating a business still fails with 42501
-- ("new row violates row-level security policy") — now on `business_partners`.
--
-- Root cause: `BusinessRepository.create` inserts the owner row into
-- `business_partners` (`business_repository.dart:35-43`) right after the
-- `businesses` insert. A policy that requires `business_id = my_business_id()`
-- can never pass for this row: `my_business_id()` reads `business_partners`,
-- and the row being inserted is the FIRST one for this user/business, so the
-- lookup returns NULL → RLS rejects.
--
-- Fix: allow two cases on INSERT:
--   * self-registration: the row's `user_id` is the current user
--     (covers the creation flow AND the "claim by phone" flow in
--     `AuthRepository.claimBusinessByPhone`),
--   * invitation: an owner/editor of an existing business adds a partner.
--
-- Note: migrations 1-14 (base schema, incl. the original `business_partners`
-- policies) live in the backend repo / dashboard, so existing INSERT policies
-- are dropped name-agnostically to stay idempotent.
--
-- Apply via the Supabase SQL editor.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Drop any existing INSERT policies on `business_partners`
-- -----------------------------------------------------------------------------
DO $mig$
DECLARE
    p RECORD;
BEGIN
    FOR p IN
        SELECT policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'business_partners'
          AND cmd = 'INSERT'
    LOOP
        EXECUTE format('DROP POLICY %I ON business_partners', p.policyname);
        RAISE NOTICE 'Dropped INSERT policy % on business_partners', p.policyname;
    END LOOP;
END $mig$;

-- -----------------------------------------------------------------------------
-- 2. Recreate: self-registration OR owner/editor adding a partner
-- -----------------------------------------------------------------------------
CREATE POLICY "business_partners_insert" ON business_partners
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        OR (
            business_id = my_business_id()
            AND (i_am_owner() OR i_am_editor())
        )
    );


-- =============================================================================
-- Verification (run after migration to confirm the policy)
-- =============================================================================
-- SELECT policyname, cmd, qual, with_check FROM pg_policies
--   WHERE schemaname = 'public' AND tablename = 'business_partners'
--   ORDER BY cmd, policyname;
-- =============================================================================
