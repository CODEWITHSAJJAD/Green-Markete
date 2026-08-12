-- =============================================================================
-- Migration 16 — Batch delete RLS (daily-64)
-- =============================================================================
-- Enables permanent batch deletion from the app (Batch list → swipe left, or
-- multi-select → trash icon). Before this migration every batch-related table
-- had either no DELETE policy or an owner-only one:
--   * `batch_purchases` had `batch_purchases_delete` (owner only, migration 15)
--   * `product_batches`, `sales`, `expenses`, `packing_records`,
--     `packing_returns`, `batch_vehicles`, `batch_partners` had none
-- So an editor (or a user before migration 15 ran) hit
--   "new row violates row-level security policy" (42501) on `batch_purchases`
-- the moment a batch with purchase lines was deleted.
--
-- Delete is now allowed for owner OR editor, scoped to the user's business:
--   * `product_batches` is scoped by its own `business_id`.
--   * child tables are scoped via their `batch_id` against `product_batches`.
--
-- Matches the existing insert/update pattern (`(i_am_owner() OR i_am_editor())`
-- in migration 15) and the daily-56 delete-hardening SQL for
-- markets/vehicles/products.
--
-- Idempotent: DROP IF EXISTS + CREATE on every table, safe to re-run.
-- Apply via the Supabase SQL editor (or `supabase db push`).
-- =============================================================================

DROP POLICY IF EXISTS "batch_purchases_delete" ON batch_purchases;

DROP POLICY IF EXISTS "batch_delete" ON product_batches;
CREATE POLICY "batch_delete" ON product_batches
    FOR DELETE USING (
        (i_am_owner() OR i_am_editor())
        AND business_id = my_business_id()
    );

DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
      'sales',
      'expenses',
      'packing_records',
      'packing_returns',
      'batch_vehicles',
      'batch_purchases',
      'batch_partners'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "batch_delete" ON %I', t);
    EXECUTE format(
      'CREATE POLICY "batch_delete" ON %I FOR DELETE USING '
      || '((i_am_owner() OR i_am_editor()) AND batch_id IN ('
      || 'SELECT id FROM product_batches WHERE business_id = my_business_id()))',
      t);
  END LOOP;
END $$;

-- Verification:
-- SELECT tablename, policyname FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('product_batches','sales','expenses','packing_records',
--                       'packing_returns','batch_vehicles','batch_purchases',
--                       'batch_partners')
--   ORDER BY tablename, policyname;
-- =============================================================================
