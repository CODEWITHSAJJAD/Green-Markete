-- =============================================================================
-- Green Market — Database schema & data audit (frontend-driven)
-- =============================================================================
-- Purpose: map the live Supabase schema against every table/view/RPC the Flutter
-- app references, so missing tables, missed inserts, and bad data are found.
--
-- Background (2026-08-12): batch delete failed with `42P01: relation
-- "batch_purchases" does not exist`. The app writes per-supplier purchase lines
-- into `batch_purchases`, but the wizard's insert is defensive (try/catch →
-- silently skip), so batches created while that table was missing still saved to
-- `product_batches` while their purchase lines were silently dropped.
--
-- Safe to run on a partially-migrated database: every dynamic check is guarded
-- so a missing table is reported, never fatal.
--
-- Run the whole file in the Supabase SQL editor, in order.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tables the app expects vs what actually exists
--    (`suppliers` is optional — Phase 9 registry, migration 15)
-- -----------------------------------------------------------------------------
SELECT
  e.tablename,
  CASE WHEN to_regclass('public.' || quote_ident(e.tablename)) IS NOT NULL
       THEN 'EXISTS' ELSE 'MISSING' END AS status
FROM (VALUES
  ('audit_logs'), ('batch_partners'), ('batch_purchases'), ('batch_vehicles'),
  ('business_partners'), ('businesses'), ('customer_payments'), ('customer_shares'),
  ('customers'), ('expenses'), ('markets'), ('packing_records'), ('packing_returns'),
  ('partner_transactions'), ('product_batches'), ('products'), ('sales'),
  ('supplier_payments'), ('suppliers'), ('user_profiles'), ('vehicles')
) AS e(tablename)
ORDER BY status, e.tablename;

-- -----------------------------------------------------------------------------
-- 2. REAL row counts for every table the app writes to
--    (guarded: MISSING TABLE is reported per line)
-- -----------------------------------------------------------------------------
DO $$
DECLARE t TEXT; cnt BIGINT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
      'product_batches','batch_purchases','batch_partners','packing_records',
      'packing_returns','batch_vehicles','expenses','sales',
      'customers','customer_payments','customer_shares','partner_transactions',
      'supplier_payments','vehicles','markets','products',
      'businesses','business_partners','user_profiles','audit_logs'
  ]
  LOOP
    IF to_regclass(format('public.%I', t)) IS NOT NULL THEN
      EXECUTE format('SELECT count(*) FROM %I', t) INTO cnt;
      RAISE NOTICE 'count % = %', t, cnt;
    ELSE
      RAISE NOTICE 'count % = MISSING TABLE', t;
    END IF;
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 3. All public tables: approx rows + RLS status (overview)
-- -----------------------------------------------------------------------------
SELECT t.tablename, s.n_live_tup AS approx_rows, t.rowsecurity AS rls_enabled
FROM pg_tables t
LEFT JOIN pg_stat_user_tables s
  ON s.schemaname = t.schemaname AND s.relname = t.tablename
WHERE t.schemaname = 'public'
ORDER BY t.tablename;

-- -----------------------------------------------------------------------------
-- 4. Views (the app reads v_city_market_performance)
-- -----------------------------------------------------------------------------
SELECT viewname FROM pg_views WHERE schemaname = 'public' ORDER BY viewname;

-- -----------------------------------------------------------------------------
-- 5. RLS policies per table (look for tables with SELECT but no INSERT/UPDATE/DELETE)
-- -----------------------------------------------------------------------------
SELECT tablename, policyname, cmd, permissive, roles::text AS roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- -----------------------------------------------------------------------------
-- 6. Foreign keys (spot missing constraints / non-cascade rules)
-- -----------------------------------------------------------------------------
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS references_table,
  ccu.column_name AS references_column,
  rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema
JOIN information_schema.referential_constraints rc
  ON tc.constraint_name = rc.constraint_name AND tc.table_schema = rc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- -----------------------------------------------------------------------------
-- 7. Functions the app calls via RPC / RLS helpers
-- -----------------------------------------------------------------------------
SELECT p.proname, pg_get_function_arguments(p.oid) AS args
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'get_business_pl_summary', 'get_partner_pl', 'get_batch_pl',
    'my_business_id', 'i_am_owner', 'i_am_editor'
  )
ORDER BY p.proname;

-- -----------------------------------------------------------------------------
-- 8. Realtime publication (app subscribes to expenses, sales,
--    customer_payments, supplier_payments)
-- -----------------------------------------------------------------------------
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY schemaname, tablename;

-- -----------------------------------------------------------------------------
-- 9. Data integrity checks (missed inserts / orphans / bad values)
--    Each check prints `CHECK <name> => <n>` or `skipped (SQLSTATE: msg)`.
--    Read the messages in the Results/Notifications panel.
-- -----------------------------------------------------------------------------
DO $$
DECLARE chk record; cnt BIGINT;
BEGIN
  FOR chk IN
    SELECT name, q FROM (VALUES
      ('batches_total',            'SELECT count(*) FROM product_batches'),
      ('purchase_lines_total',     'SELECT count(*) FROM batch_purchases'),
      ('batches_with_zero_purchase_lines', $$
        SELECT count(*) FROM (
          SELECT b.id FROM product_batches b
          LEFT JOIN batch_purchases p ON p.batch_id = b.id
          GROUP BY b.id HAVING count(p.id) = 0
        ) x $$),
      ('orphan_purchase_lines',    'SELECT count(*) FROM batch_purchases p WHERE NOT EXISTS (SELECT 1 FROM product_batches b WHERE b.id = p.batch_id)'),
      ('orphan_sales',             'SELECT count(*) FROM sales s WHERE NOT EXISTS (SELECT 1 FROM product_batches b WHERE b.id = s.batch_id)'),
      ('orphan_expenses',          'SELECT count(*) FROM expenses e WHERE NOT EXISTS (SELECT 1 FROM product_batches b WHERE b.id = e.batch_id)'),
      ('orphan_packing_records',   'SELECT count(*) FROM packing_records pr WHERE NOT EXISTS (SELECT 1 FROM product_batches b WHERE b.id = pr.batch_id)'),
      ('orphan_packing_returns',   'SELECT count(*) FROM packing_returns r WHERE NOT EXISTS (SELECT 1 FROM product_batches b WHERE b.id = r.batch_id)'),
      ('orphan_batch_vehicles',    'SELECT count(*) FROM batch_vehicles v WHERE NOT EXISTS (SELECT 1 FROM product_batches b WHERE b.id = v.batch_id)'),
      ('orphan_batch_partners',    'SELECT count(*) FROM batch_partners bp WHERE NOT EXISTS (SELECT 1 FROM product_batches b WHERE b.id = bp.batch_id)'),
      ('batches_cost_mismatch',    'SELECT count(*) FROM product_batches b WHERE b.total_purchase_cost <> round(b.total_quantity * b.purchase_price_per_unit, 2)'),
      ('batches_paid_exceeds_cost','SELECT count(*) FROM product_batches b WHERE b.purchase_amount_paid > b.total_purchase_cost'),
      ('batches_past_packed_no_packing', $$
        SELECT count(*) FROM product_batches b
        WHERE b.status IN ('in_transit','delivered','selling','closed')
          AND NOT EXISTS (SELECT 1 FROM packing_records pr WHERE pr.batch_id = b.id) $$),
      ('batches_sold_over_total',  $$
        SELECT count(*) FROM (
          SELECT b.id FROM product_batches b
          JOIN sales s ON s.batch_id = b.id
          GROUP BY b.id, b.total_quantity
          HAVING sum(s.quantity_sold) > b.total_quantity
        ) x $$),
      ('customers_negative_balance', 'SELECT count(*) FROM customers c WHERE c.outstanding_balance < 0')
    ) AS t(name text, q text)
  LOOP
    BEGIN
      EXECUTE chk.q INTO cnt;
      RAISE NOTICE 'CHECK % => %', chk.name, cnt;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'CHECK % => skipped (%: %)', chk.name, SQLSTATE, SQLERRM;
    END;
  END LOOP;
END $$;
-- =============================================================================
