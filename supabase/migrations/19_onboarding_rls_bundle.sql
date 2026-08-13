-- =============================================================================
-- Migration 19 — Onboarding RLS bundle (fix 42501 on signup / business creation)
-- =============================================================================
-- One file covering EVERY table written during onboarding + setup-business:
--   businesses        INSERT: owner_id = auth.uid()
--   business_partners INSERT: user_id = auth.uid() OR owner/editor of existing
--   user_profiles     INSERT/UPDATE: user_id = auth.uid() (covers the upsert
--                                    in AuthRepository.createUserProfile)
--
-- The DO block first drops ALL existing policies of those commands
-- (name-agnostic, since migrations 1-14 live in the backend repo/dashboard)
-- and NOTICEs each drop, so the output tells you exactly what was replaced.
--
-- Apply via the Supabase SQL editor. If you still get 42501 afterwards,
-- paste the FULL error message — its "message" field names the table.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Drop existing INSERT/UPDATE policies on the three tables
-- -----------------------------------------------------------------------------
DO $mig$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT tablename, cmd, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND (tablename, cmd) IN (
            ('businesses',       'INSERT'),
            ('business_partners','INSERT'),
            ('user_profiles',    'INSERT'),
            ('user_profiles',    'UPDATE')
          )
    LOOP
        EXECUTE format('DROP POLICY %I ON %I', t.policyname, t.tablename);
        RAISE NOTICE 'Dropped % policy % on %', t.cmd, t.policyname, t.tablename;
    END LOOP;
END $mig$;

-- -----------------------------------------------------------------------------
-- 2. Recreate the policies
-- -----------------------------------------------------------------------------
CREATE POLICY "businesses_insert" ON businesses
    FOR INSERT TO authenticated
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY "business_partners_insert" ON business_partners
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        OR (
            business_id = my_business_id()
            AND (i_am_owner() OR i_am_editor())
        )
    );

CREATE POLICY "user_profiles_insert" ON user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_profiles_update" ON user_profiles
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());


-- =============================================================================
-- Verification (run after migration — must print all rows below)
-- =============================================================================
-- SELECT tablename, cmd, with_check FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('businesses','business_partners','user_profiles')
--     AND cmd IN ('INSERT','UPDATE')
--   ORDER BY tablename, cmd;
-- =============================================================================
