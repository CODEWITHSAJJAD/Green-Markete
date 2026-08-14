-- =============================================================================
-- Migration 25 �?" Multi-business RLS support (B1�?"B5 of 05_MultiUser_RBAC_Plan.md)
-- =============================================================================
-- SAFETY CONTRACT (why this can never break the running system):
--
--   * ADDITIVE ONLY. We never drop or weaken an existing policy. Postgres
--     combines policies of the same command type with OR, so every policy this
--     file creates can only WIDEN access �?" it cannot hide rows, and it never
--     touches INSERT/UPDATE/DELETE policies, so no 42501 on writes.
--   * The existing `my_business_id()` / `i_am_owner()` / `i_am_editor()` and
--     the migration-22 RETURNING semantics are left untouched.
--   * Every section is a DO block guarded by to_regclass() + information_schema
--     column checks; missing tables/columns are NOTICEd and skipped, never fatal.
--   * The two triggers swallow ALL exceptions internally �?" even if they fail
--     they cannot roll back the row they were fired for.
--   * Data is only ever exposed for businesses the caller owns or is a claimed
--     member of (`my_business_ids()`), never for other businesses.
--
-- Apply via the Supabase SQL editor (statements run sequentially; each is
-- independent and idempotent, so re-running is safe).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- B3a. Multi-business identity helper (SECURITY DEFINER, no RLS recursion).
--      Returns every business the current user owns OR has a claimed
--      membership in. Exact same rule set the SELECT policies already grant,
--      just for all businesses at once instead of `LIMIT 1`.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION my_business_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.id FROM businesses b WHERE b.owner_id = auth.uid()
  UNION
  SELECT bp.business_id FROM business_partners bp WHERE bp.user_id = auth.uid()
$$;

-- ---------------------------------------------------------------------------
-- B3b. Per-business resolution helpers (used by policies/triggers/future code).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION access_level_for(p_business_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT 'owner' FROM businesses
      WHERE id = p_business_id AND owner_id = auth.uid() LIMIT 1),
    (SELECT access_level FROM business_partners
      WHERE business_id = p_business_id AND user_id = auth.uid() LIMIT 1),
    'viewer'
  );
$$;

CREATE OR REPLACE FUNCTION side_role_for(p_business_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT 'owner' FROM businesses
      WHERE id = p_business_id AND owner_id = auth.uid() LIMIT 1),
    (SELECT role FROM business_partners
      WHERE business_id = p_business_id AND user_id = auth.uid() LIMIT 1),
    NULL
  );
$$;

CREATE OR REPLACE FUNCTION i_am_owner_for(p_business_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM businesses
    WHERE id = p_business_id AND owner_id = auth.uid()
  ) OR EXISTS (
    SELECT 1 FROM business_partners
    WHERE business_id = p_business_id AND user_id = auth.uid()
      AND (role = 'owner' OR access_level = 'owner')
  );
$$;

-- ---------------------------------------------------------------------------
-- B4. Cross-side grant column (owner flips this to let a partner edit the
--     OTHER side too). Additive; existing rows default to false.
-- ---------------------------------------------------------------------------
DO $b4$
BEGIN
  IF to_regclass('public.business_partners') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE business_partners ADD COLUMN IF NOT EXISTS manage_other_side boolean NOT NULL DEFAULT false';
    RAISE NOTICE 'business_partners.manage_other_side ready';
  ELSE
    RAISE NOTICE 'SKIP B4 �?" business_partners missing';
  END IF;
END $b4$;

-- ---------------------------------------------------------------------------
-- B2. Auto-link a newly added partner whose phone already belongs to a
--     registered user. AFTER INSERT + full exception swallowing means the
--     INSERT itself can never be blocked. No-op when no profile matches.
--     The function is created UNCONDITIONALLY so the GRANT below can never
--     fail with 42883; only the trigger attachment is guarded.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_link_business_partner()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.user_id IS NULL AND NEW.phone IS NOT NULL THEN
    BEGIN
      UPDATE business_partners bp
      SET user_id = (
        SELECT up.user_id FROM user_profiles up WHERE up.phone = NEW.phone LIMIT 1
      ),
      is_claimed = true
      WHERE bp.id = NEW.id
        AND bp.user_id IS NULL
        AND EXISTS (SELECT 1 FROM user_profiles up WHERE up.phone = NEW.phone);
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'auto_link skipped for phone %: %', NEW.phone, SQLERRM;
    END;
  END IF;
  RETURN NULL;
END;
$$;

DO $b2$
BEGIN
  IF to_regclass('public.business_partners') IS NULL OR to_regclass('public.user_profiles') IS NULL THEN
    RAISE NOTICE 'SKIP B2 trigger - business_partners/user_profiles missing';
    RETURN;
  END IF;
  BEGIN
    DROP TRIGGER IF EXISTS trg_auto_link_partner ON business_partners;
    CREATE TRIGGER trg_auto_link_partner
    AFTER INSERT ON business_partners
    FOR EACH ROW EXECUTE FUNCTION auto_link_business_partner();
    RAISE NOTICE 'B2 auto-link trigger ready';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'B2 trigger creation failed: %', SQLERRM;
  END;
END $b2$;

-- ---------------------------------------------------------------------------
-- B5. Audit access/role changes on business_partners. Append-only; swallows
--     every error so UPDATEs keep working even if the audit write fails.
--     The function is created UNCONDITIONALLY so the GRANT below can never
--     fail with 42883; the trigger is attached only when audit_logs has the
--     columns the app reads.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit_partner_access_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.access_level IS DISTINCT FROM OLD.access_level
     OR NEW.role IS DISTINCT FROM OLD.role
     OR NEW.manage_other_side IS DISTINCT FROM OLD.manage_other_side THEN
    BEGIN
      INSERT INTO audit_logs (table_name, record_id, action, performed_by, old_values, new_values)
      VALUES (
        'business_partners',
        NEW.id::text,
        'UPDATE',
        auth.uid()::text,
        jsonb_build_object(
          'access_level', OLD.access_level,
          'role', OLD.role,
          'manage_other_side', OLD.manage_other_side
        ),
        jsonb_build_object(
          'access_level', NEW.access_level,
          'role', NEW.role,
          'manage_other_side', NEW.manage_other_side
        )
      );
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'audit write skipped: %', SQLERRM;
    END;
  END IF;
  RETURN NULL;
END;
$$;

DO $b5$
DECLARE
  has_cols boolean;
BEGIN
  IF to_regclass('public.business_partners') IS NULL OR to_regclass('public.audit_logs') IS NULL THEN
    RAISE NOTICE 'SKIP B5 trigger - business_partners/audit_logs missing';
    RETURN;
  END IF;

  -- Require EVERY column the app reads to be present (not: every column of
  -- the table to be one of these five).
  SELECT bool_and(EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema = 'public' AND c.table_name = 'audit_logs'
      AND c.column_name = req.col
  ))
  INTO has_cols
  FROM (VALUES ('table_name'),('record_id'),('action'),('old_values'),('new_values'))
       AS req(col);

  IF has_cols IS NOT TRUE THEN
    RAISE NOTICE 'SKIP B5 trigger - audit_logs missing expected columns';
    RETURN;
  END IF;

  BEGIN
    DROP TRIGGER IF EXISTS trg_audit_partner_access ON business_partners;
    CREATE TRIGGER trg_audit_partner_access
    AFTER UPDATE ON business_partners
    FOR EACH ROW EXECUTE FUNCTION audit_partner_access_change();
    RAISE NOTICE 'B5 audit trigger ready';
  EXCEPTION WHEN others THEN
    RAISE NOTICE 'B5 trigger creation failed: %', SQLERRM;
  END;
END $b5$;

-- ---------------------------------------------------------------------------
-- B3c. ADDITIVE multi-business SELECT policies.
--      For every table below we add ONE extra policy named `<table>_multi_biz_select`
--      with the SAME scoping expression the existing `_select` policy uses, but
--      resolved against ALL of the user's businesses instead of the single
--      `my_business_id()`. OR-combination widens; nothing is removed.
-- ---------------------------------------------------------------------------
DO $b3$
DECLARE
  t RECORD;
  scope_expr TEXT;
BEGIN
  FOR t IN
    SELECT v.tablename, v.colname, v.grp
    FROM (VALUES
      ('businesses',          'owner_id',    'root'),
      ('business_partners',   'user_id',     'partners'),
      ('markets',             'business_id', 'biz'),
      ('products',            'business_id', 'biz'),
      ('customers',           'business_id', 'biz'),
      ('customer_payments',   'business_id', 'biz'),
      ('customer_shares',     'business_id', 'biz'),
      ('vehicles',            'business_id', 'biz'),
      ('expenses',            'business_id', 'biz'),
      ('partner_transactions','business_id', 'biz'),
      ('supplier_payments',   'business_id', 'biz'),
      ('suppliers',           'business_id', 'biz'),
      ('product_batches',     'business_id', 'biz'),
      ('batch_settlements',   'business_id', 'biz'),
      ('sales',               'batch_id',    'batch'),
      ('packing_records',     'batch_id',    'batch'),
      ('packing_returns',     'batch_id',    'batch'),
      ('batch_vehicles',      'batch_id',    'batch'),
      ('batch_purchases',     'batch_id',    'batch'),
      ('batch_partners',      'batch_id',    'batch')
    ) AS v(tablename, colname, grp)
  LOOP
    IF to_regclass('public.' || t.tablename) IS NULL THEN
      RAISE NOTICE 'SKIP % �?" table does not exist', t.tablename;
      CONTINUE;
    END IF;
    IF t.grp = 'root' OR t.grp = 'partners' THEN
      -- businesses / business_partners have no scoping column to check.
      NULL;
    ELSIF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = t.tablename
        AND column_name = t.colname
    ) THEN
      RAISE NOTICE 'SKIP % �?" column % missing', t.tablename, t.colname;
      CONTINUE;
    END IF;

    IF t.grp = 'root' THEN
      scope_expr := 'id IN (SELECT my_business_ids())';
    ELSIF t.grp = 'partners' THEN
      scope_expr := 'business_id IN (SELECT my_business_ids())';
    ELSIF t.grp = 'biz' THEN
      scope_expr := 'business_id IN (SELECT my_business_ids())';
    ELSE -- batch
      scope_expr := 'batch_id IN (SELECT id FROM product_batches WHERE business_id IN (SELECT my_business_ids()))';
    END IF;

    BEGIN
      EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_multi_biz_select', t.tablename);
      EXECUTE format(
        'CREATE POLICY %I ON %I FOR SELECT USING (%s)',
        t.tablename || '_multi_biz_select',
        t.tablename,
        scope_expr
      );
      RAISE NOTICE 'Added multi-biz SELECT policy on %', t.tablename;
    EXCEPTION WHEN others THEN
      RAISE NOTICE 'ERROR adding multi-biz SELECT on %: %', t.tablename, SQLERRM;
    END;
  END LOOP;
END $b3$;

-- ---------------------------------------------------------------------------
-- GRANTs (same set migration 21 established for every function).
-- ---------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION my_business_ids() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION access_level_for(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION side_role_for(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION i_am_owner_for(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION auto_link_business_partner() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION audit_partner_access_change() TO anon, authenticated;

-- =============================================================================
-- Verification (run manually after applying):
--   SELECT tablename, policyname FROM pg_policies
--   WHERE schemaname = 'public' AND policyname LIKE '%multi_biz_select'
--   ORDER BY tablename;
--
--   SELECT bp.id, b.name, bp.role, bp.access_level
--   FROM business_partners bp JOIN businesses b ON b.id = bp.business_id
--   WHERE bp.user_id = auth.uid();
--
--   -- Confirm `manage_other_side` exists:
--   SELECT column_name, data_type, column_default
--   FROM information_schema.columns
--   WHERE table_name = 'business_partners' AND column_name = 'manage_other_side';
-- =============================================================================
