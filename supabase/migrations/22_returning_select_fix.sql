-- =============================================================================
-- Migration 22 — Fix SELECT policies for RETURNING (the real 42501 root cause)
-- =============================================================================
-- Symptom: business creation still 42501 even with grants (migration 21) and
-- correct INSERT/UPDATE/DELETE policies (migration 20) verified.
--
-- Root cause: PostgREST performs `INSERT ... RETURNING *` and the RETURNING
-- rows are filtered through the table's SELECT policy. At the moment of the
-- very FIRST insert:
--   * `businesses_select`   = id = my_business_id()   -> my_business_id()
--     reads business_partners, returns NULL (no partner row yet) -> row is
--     invisible -> PostgREST raises 42501 "new row violates row-level
--     security policy" even though the INSERT's WITH CHECK passed.
--   * `business_partners_select` = business_id = my_business_id() -> same
--     problem for the owner's first partner row.
--
-- Fix: extend the SELECT policies so a user always sees rows they own/created:
--   * businesses:       id = my_business_id() OR owner_id = auth.uid()
--   * business_partners: business_id = my_business_id() OR user_id = auth.uid()
-- (The last branch also covers the phone-claim flow.)
--
-- Apply via the Supabase SQL editor. Idempotent.
-- =============================================================================

DO $mig$
BEGIN
    IF to_regclass('public.businesses') IS NOT NULL THEN
        DROP POLICY IF EXISTS businesses_select ON businesses;
        CREATE POLICY businesses_select ON businesses
            FOR SELECT USING (id = my_business_id() OR owner_id = auth.uid());
        RAISE NOTICE 'businesses_select updated (owner sees own business)';
    END IF;

    IF to_regclass('public.business_partners') IS NOT NULL THEN
        DROP POLICY IF EXISTS partners_select ON business_partners;
        CREATE POLICY partners_select ON business_partners
            FOR SELECT USING (business_id = my_business_id() OR user_id = auth.uid());
        RAISE NOTICE 'partners_select updated (user sees own partner row)';
    END IF;
END $mig$;

-- =============================================================================
-- Verification
-- =============================================================================
-- SELECT tablename, policyname, qual FROM pg_policies
--   WHERE schemaname = 'public'
--     AND policyname IN ('businesses_select','partners_select');
-- =============================================================================