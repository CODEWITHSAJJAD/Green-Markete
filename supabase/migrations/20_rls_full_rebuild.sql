-- =============================================================================
-- Migration 20 — Full RLS rebuild (deterministic, crash-proof, notices every step)
-- =============================================================================
-- Rebuilds RLS for ALL application tables with one consistent model that
-- mirrors the app's code-side scoping (every repository filters by
-- business_id / batch_id from secure storage):
--
--   business_id tables : SELECT/INSERT/UPDATE/DELETE scoped to my business,
--                        writes owner-or-editor
--   batch_id tables    : scoped via product_batches (owner-or-editor writes)
--   businesses         : SELECT own, INSERT owner_id = auth.uid(),
--                        UPDATE/DELETE owner
--   business_partners  : SELECT business-scoped, INSERT/UPDATE self-or-
--                        owner/editor (covers onboarding + phone claim),
--                        DELETE owner
--   user_profiles      : own row only
--   audit_logs         : append-only for authenticated (INSERT WITH CHECK true)
--
-- Every policy creation is individually guarded inside BEGIN/EXCEPTION:
-- tables/columns that do not exist in THIS database are skipped with a
-- NOTICE instead of aborting — so this file can never fail mid-way again.
-- Existing policies of all commands are dropped name-agnostically first
-- (migrations 1-14 live in the backend repo / dashboard).
--
-- Apply via the Supabase SQL editor.
-- =============================================================================

DO $mig$
DECLARE
    t    RECORD;
    pol  TEXT;
    grp  TEXT;
BEGIN
    FOR t IN
        SELECT v.tablename, v.colname, v.grp
        FROM (VALUES
            ('businesses',        'owner_id',  'root'),
            ('business_partners', 'user_id',   'partners'),
            ('user_profiles',     'user_id',   'profiles'),
            ('markets',           'business_id','biz'),
            ('products',          'business_id','biz'),
            ('customers',         'business_id','biz'),
            ('customer_payments', 'business_id','biz'),
            ('customer_shares',   'business_id','biz'),
            ('vehicles',          'business_id','biz'),
            ('expenses',          'business_id','biz'),
            ('partner_transactions','business_id','biz'),
            ('supplier_payments', 'business_id','biz'),
            ('suppliers',         'business_id','biz'),
            ('product_batches',   'business_id','biz'),
            ('batch_settlements', 'business_id','biz'),
            ('sales',             'batch_id',  'batch'),
            ('packing_records',   'batch_id',  'batch'),
            ('packing_returns',   'batch_id',  'batch'),
            ('batch_vehicles',    'batch_id',  'batch'),
            ('batch_purchases',   'batch_id',  'batch'),
            ('batch_partners',    'batch_id',  'batch'),
            ('audit_logs',        'id',        'audit')
        ) AS v(tablename, colname, grp)
    LOOP
        IF to_regclass('public.' || t.tablename) IS NULL THEN
            RAISE NOTICE 'SKIP % — table does not exist', t.tablename;
            CONTINUE;
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = t.tablename
              AND column_name = t.colname
        ) THEN
            RAISE NOTICE 'SKIP % — column % missing', t.tablename, t.colname;
            CONTINUE;
        END IF;

        -- Drop EVERY existing policy on this table (all commands)
        FOR pol IN
            SELECT policyname FROM pg_policies
            WHERE schemaname = 'public' AND tablename = t.tablename
        LOOP
            BEGIN
                EXECUTE format('DROP POLICY %I ON %I', pol, t.tablename);
                RAISE NOTICE 'Dropped policy % on %', pol, t.tablename;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'Drop failed on %: %', t.tablename, SQLERRM;
            END;
        END LOOP;

        grp := t.grp;

        -- Root: businesses ------------------------------------------------
        IF grp = 'root' THEN
            BEGIN
                EXECUTE format('CREATE POLICY businesses_select ON %I FOR SELECT USING (id = my_business_id())', t.tablename);
                EXECUTE format('CREATE POLICY businesses_insert ON %I FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid())', t.tablename);
                EXECUTE format('CREATE POLICY businesses_update ON %I FOR UPDATE USING (id = my_business_id()) WITH CHECK (i_am_owner())', t.tablename);
                EXECUTE format('CREATE POLICY businesses_delete ON %I FOR DELETE USING (i_am_owner())', t.tablename);
                RAISE NOTICE 'Rebuilt root policies on %', t.tablename;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
            END;

        -- Partners (self-registration + owner/editor) ----------------------
        ELSIF grp = 'partners' THEN
            BEGIN
                EXECUTE format('CREATE POLICY partners_select ON %I FOR SELECT USING (business_id = my_business_id())', t.tablename);
                EXECUTE format('CREATE POLICY partners_insert ON %I FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() OR (business_id = my_business_id() AND (i_am_owner() OR i_am_editor())))', t.tablename);
                EXECUTE format('CREATE POLICY partners_update ON %I FOR UPDATE USING (business_id = my_business_id() OR user_id = auth.uid()) WITH CHECK (user_id = auth.uid() OR (business_id = my_business_id() AND (i_am_owner() OR i_am_editor())))', t.tablename);
                EXECUTE format('CREATE POLICY partners_delete ON %I FOR DELETE USING (business_id = my_business_id() AND i_am_owner())', t.tablename);
                RAISE NOTICE 'Rebuilt partner policies on %', t.tablename;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
            END;

        -- Own profile row ---------------------------------------------------
        ELSIF grp = 'profiles' THEN
            BEGIN
                EXECUTE format('CREATE POLICY profiles_select ON %I FOR SELECT USING (user_id = auth.uid())', t.tablename);
                EXECUTE format('CREATE POLICY profiles_insert ON %I FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid())', t.tablename);
                EXECUTE format('CREATE POLICY profiles_update ON %I FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())', t.tablename);
                RAISE NOTICE 'Rebuilt profile policies on %', t.tablename;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
            END;

        -- Business-scoped tables --------------------------------------------
        ELSIF grp = 'biz' THEN
            BEGIN
                EXECUTE format('CREATE POLICY %I_select ON %I FOR SELECT USING (business_id = my_business_id())', t.tablename, t.tablename);
                EXECUTE format('CREATE POLICY %I_insert ON %I FOR INSERT TO authenticated WITH CHECK (business_id = my_business_id() AND (i_am_owner() OR i_am_editor()))', t.tablename, t.tablename);
                EXECUTE format('CREATE POLICY %I_update ON %I FOR UPDATE USING (business_id = my_business_id()) WITH CHECK (business_id = my_business_id() AND (i_am_owner() OR i_am_editor()))', t.tablename, t.tablename);
                EXECUTE format('CREATE POLICY %I_delete ON %I FOR DELETE USING (business_id = my_business_id() AND (i_am_owner() OR i_am_editor()))', t.tablename, t.tablename);
                RAISE NOTICE 'Rebuilt business-scoped policies on %', t.tablename;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
            END;

        -- Batch-scoped tables ------------------------------------------------
        ELSIF grp = 'batch' THEN
            BEGIN
                EXECUTE format('CREATE POLICY %I_select ON %I FOR SELECT USING (batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id()))', t.tablename, t.tablename);
                EXECUTE format('CREATE POLICY %I_insert ON %I FOR INSERT TO authenticated WITH CHECK (batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id()) AND (i_am_owner() OR i_am_editor()))', t.tablename, t.tablename);
                EXECUTE format('CREATE POLICY %I_update ON %I FOR UPDATE USING (batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id())) WITH CHECK (batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id()) AND (i_am_owner() OR i_am_editor()))', t.tablename, t.tablename);
                EXECUTE format('CREATE POLICY %I_delete ON %I FOR DELETE USING (batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id()) AND (i_am_owner() OR i_am_editor()))', t.tablename, t.tablename);
                RAISE NOTICE 'Rebuilt batch-scoped policies on %', t.tablename;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
            END;

        -- Audit log (append-only) ----------------------------------------------
        ELSIF grp = 'audit' THEN
            BEGIN
                EXECUTE format('CREATE POLICY audit_select ON %I FOR SELECT USING (true)', t.tablename);
                EXECUTE format('CREATE POLICY audit_insert ON %I FOR INSERT TO authenticated WITH CHECK (true)', t.tablename);
                RAISE NOTICE 'Rebuilt audit policies on %', t.tablename;
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'ERROR rebuilding %: %', t.tablename, SQLERRM;
            END;
        END IF;
    END LOOP;
END $mig$;


-- =============================================================================
-- Verification (run after migration to confirm every table has policies)
-- =============================================================================
-- SELECT tablename, count(*) AS policies FROM pg_policies
--   WHERE schemaname = 'public' GROUP BY tablename ORDER BY tablename;
-- =============================================================================