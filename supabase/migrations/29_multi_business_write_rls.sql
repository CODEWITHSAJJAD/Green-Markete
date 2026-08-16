-- =============================================================================
-- Migration 29 — Fix write RLS for multi-business membership + viewer own-side writes
-- =============================================================================
-- Found auditing 05_MultiUser_RBAC_Plan.md against the DEPLOYED policies
-- (migration 20). Two gaps let the database reject or over-grant writes in
-- ways the Flutter app (auth_provider.dart, capability.dart) does not expect:
--
-- 1. VIEWER CANNOT WRITE AT ALL.
--    `partner_repository.dart` defaults every new partner to
--    `access_level = 'viewer'`. Per 05_MultiUser_RBAC_Plan.md §3.3 (and the
--    user's explicit requirement), a viewer keeps full write access on their
--    OWN side (purchaser/seller) — only cross-cutting writes (create/close
--    batch, partner management) are owner/editor-only. But migration 20's
--    write policies require `i_am_owner() OR i_am_editor()`, and
--    `i_am_editor()` only matches `access_level = 'editor'`. A freshly
--    invited viewer partner gets a 42501 RLS rejection the first time they
--    try to record a purchase or sale, even though `CapabilityService`
--    correctly allowed the action client-side. (Side-specific and
--    cross-cutting restrictions remain enforced by the app, exactly as
--    migration 20's owner-or-editor gate never distinguished side either.)
--
-- 2. SINGLE-BUSINESS HELPERS BREAK MULTI-BUSINESS USERS.
--    `my_business_id()` is `... LIMIT 1` with no ORDER BY — for a user who
--    belongs to more than one business (owns one, partners in another),
--    writes against every business except whichever one that arbitrary
--    LIMIT 1 happens to return are rejected. Worse: `businesses_update` /
--    `businesses_delete` gate on `i_am_owner()`, which is TRUE if the caller
--    owns ANY business anywhere and is not correlated to the row being
--    written — so, as deployed, any business owner can update or delete a
--    business they do not own, as long as they own some business themselves.
--
-- Fix: per-row membership helpers (parallel to migration 25's `my_business_ids()`
-- for SELECT) used to rebuild every INSERT/UPDATE/DELETE policy so it checks
-- the specific business_id/owner_id on the row, and so any CLAIMED member
-- (owner/editor/viewer/accountant) of that business can write to its
-- business- and batch-scoped tables. Partner management (business_partners
-- writes) stays owner-only, matching the role matrix in
-- 05_MultiUser_RBAC_Plan.md §3.3 exactly (editor was never supposed to add/
-- edit partners either).
--
-- Every step is guarded (to_regclass / column checks / exception handlers)
-- so a table or column missing from this database is skipped with a NOTICE,
-- never aborting the migration — same contract as migrations 20 and 25.
-- Apply via the Supabase SQL editor.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Per-row membership helpers.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION i_am_member_of(p_business_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM businesses WHERE id = p_business_id AND owner_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM business_partners
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND is_claimed = true
  );
$$;

CREATE OR REPLACE FUNCTION i_am_owner_or_editor_of(p_business_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM businesses WHERE id = p_business_id AND owner_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM business_partners
    WHERE business_id = p_business_id
      AND user_id = auth.uid()
      AND is_claimed = true
      AND access_level = 'editor'
  );
$$;

GRANT EXECUTE ON FUNCTION i_am_member_of(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION i_am_owner_or_editor_of(uuid) TO anon, authenticated;

-- -----------------------------------------------------------------------------
-- 2. businesses — fix row-independent owner check on UPDATE/DELETE.
-- -----------------------------------------------------------------------------
DO $biz$
BEGIN
  IF to_regclass('public.businesses') IS NULL THEN
    RAISE NOTICE 'SKIP businesses — table missing';
    RETURN;
  END IF;

  BEGIN
    DROP POLICY IF EXISTS businesses_update ON businesses;
    CREATE POLICY businesses_update ON businesses
      FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
    RAISE NOTICE 'Rebuilt businesses_update (row-correlated owner check)';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'ERROR rebuilding businesses_update: %', SQLERRM;
  END;

  BEGIN
    DROP POLICY IF EXISTS businesses_delete ON businesses;
    CREATE POLICY businesses_delete ON businesses
      FOR DELETE USING (owner_id = auth.uid());
    RAISE NOTICE 'Rebuilt businesses_delete (row-correlated owner check)';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'ERROR rebuilding businesses_delete: %', SQLERRM;
  END;
END $biz$;

-- -----------------------------------------------------------------------------
-- 3. business_partners — partner management stays owner-only, but resolved
--    per-row instead of via the single-business my_business_id().
-- -----------------------------------------------------------------------------
DO $bp$
BEGIN
  IF to_regclass('public.business_partners') IS NULL THEN
    RAISE NOTICE 'SKIP business_partners — table missing';
    RETURN;
  END IF;

  BEGIN
    DROP POLICY IF EXISTS partners_insert ON business_partners;
    CREATE POLICY partners_insert ON business_partners
      FOR INSERT TO authenticated
      WITH CHECK (
        user_id = auth.uid()
        OR EXISTS (SELECT 1 FROM businesses WHERE id = business_id AND owner_id = auth.uid())
      );
    RAISE NOTICE 'Rebuilt partners_insert (per-row owner check)';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'ERROR rebuilding partners_insert: %', SQLERRM;
  END;

  BEGIN
    DROP POLICY IF EXISTS partners_update ON business_partners;
    CREATE POLICY partners_update ON business_partners
      FOR UPDATE
      USING (
        user_id = auth.uid()
        OR EXISTS (SELECT 1 FROM businesses WHERE id = business_id AND owner_id = auth.uid())
      )
      WITH CHECK (
        user_id = auth.uid()
        OR EXISTS (SELECT 1 FROM businesses WHERE id = business_id AND owner_id = auth.uid())
      );
    RAISE NOTICE 'Rebuilt partners_update (per-row owner check)';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'ERROR rebuilding partners_update: %', SQLERRM;
  END;

  BEGIN
    DROP POLICY IF EXISTS partners_delete ON business_partners;
    CREATE POLICY partners_delete ON business_partners
      FOR DELETE
      USING (EXISTS (SELECT 1 FROM businesses WHERE id = business_id AND owner_id = auth.uid()));
    RAISE NOTICE 'Rebuilt partners_delete (per-row owner check)';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'ERROR rebuilding partners_delete: %', SQLERRM;
  END;
END $bp$;

-- -----------------------------------------------------------------------------
-- 4. Business-scoped tables — any claimed member (owner/editor/viewer/
--    accountant) can write; app enforces side + cross-cutting restrictions.
-- -----------------------------------------------------------------------------
DO $mig$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT v.tablename
        FROM (VALUES
            ('markets'), ('products'), ('customers'), ('customer_payments'),
            ('customer_shares'), ('vehicles'), ('expenses'),
            ('partner_transactions'), ('supplier_payments'), ('suppliers'),
            ('product_batches'), ('batch_settlements')
        ) AS v(tablename)
    LOOP
        IF to_regclass('public.' || t.tablename) IS NULL THEN
            RAISE NOTICE 'SKIP % — table does not exist', t.tablename;
            CONTINUE;
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = t.tablename
              AND column_name = 'business_id'
        ) THEN
            RAISE NOTICE 'SKIP % — column business_id missing', t.tablename;
            CONTINUE;
        END IF;

        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_insert', t.tablename);
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_update', t.tablename);
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_delete', t.tablename);
            EXECUTE format('CREATE POLICY %I ON %I FOR INSERT TO authenticated WITH CHECK (i_am_member_of(business_id))', t.tablename || '_insert', t.tablename);
            EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE USING (i_am_member_of(business_id)) WITH CHECK (i_am_member_of(business_id))', t.tablename || '_update', t.tablename);
            EXECUTE format('CREATE POLICY %I ON %I FOR DELETE USING (i_am_member_of(business_id))', t.tablename || '_delete', t.tablename);
            RAISE NOTICE 'Rebuilt write policies on % (any claimed member)', t.tablename;
        EXCEPTION WHEN others THEN
            RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
        END;
    END LOOP;
END $mig$;

-- -----------------------------------------------------------------------------
-- 5. Batch-scoped tables — same rule, resolved through product_batches.
-- -----------------------------------------------------------------------------
DO $mig2$
DECLARE
    t RECORD;
BEGIN
    FOR t IN
        SELECT v.tablename
        FROM (VALUES
            ('sales'), ('packing_records'), ('packing_returns'),
            ('batch_vehicles'), ('batch_purchases'), ('batch_partners')
        ) AS v(tablename)
    LOOP
        IF to_regclass('public.' || t.tablename) IS NULL THEN
            RAISE NOTICE 'SKIP % — table does not exist', t.tablename;
            CONTINUE;
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = t.tablename
              AND column_name = 'batch_id'
        ) THEN
            RAISE NOTICE 'SKIP % — column batch_id missing', t.tablename;
            CONTINUE;
        END IF;

        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_insert', t.tablename);
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_update', t.tablename);
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_delete', t.tablename);
            EXECUTE format(
                'CREATE POLICY %I ON %I FOR INSERT TO authenticated WITH CHECK (batch_id IN (SELECT id FROM product_batches WHERE i_am_member_of(business_id)))',
                t.tablename || '_insert', t.tablename
            );
            EXECUTE format(
                'CREATE POLICY %I ON %I FOR UPDATE USING (batch_id IN (SELECT id FROM product_batches WHERE i_am_member_of(business_id))) WITH CHECK (batch_id IN (SELECT id FROM product_batches WHERE i_am_member_of(business_id)))',
                t.tablename || '_update', t.tablename
            );
            EXECUTE format(
                'CREATE POLICY %I ON %I FOR DELETE USING (batch_id IN (SELECT id FROM product_batches WHERE i_am_member_of(business_id)))',
                t.tablename || '_delete', t.tablename
            );
            RAISE NOTICE 'Rebuilt write policies on % (any claimed member)', t.tablename;
        EXCEPTION WHEN others THEN
            RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
        END;
    END LOOP;
END $mig2$;

-- =============================================================================
-- Verification (run after migration)
-- =============================================================================
-- 1. Confirm the row-correlated business owner policies:
--   SELECT policyname, qual, with_check FROM pg_policies
--     WHERE schemaname = 'public' AND tablename = 'businesses' ORDER BY policyname;
--
-- 2. Confirm every business/batch table now has member-scoped write policies:
--   SELECT tablename, policyname, cmd FROM pg_policies
--     WHERE schemaname = 'public' AND policyname LIKE '%_insert'
--     ORDER BY tablename;
--
-- 3. As a viewer-level partner, INSERT a row into a table on their own side
--    (e.g. `sales` for a seller-side viewer) — should now succeed.
-- =============================================================================
