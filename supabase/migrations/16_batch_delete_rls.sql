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
-- Robust/idempotent: every statement is guarded by `to_regclass`, so the
-- migration also runs on databases that predate some child tables (e.g.
-- `batch_purchases`, created by the daily-59 migration in the backend repo).
-- Safe to re-run at any time; policies are created for whichever tables exist.
--
-- Apply via the Supabase SQL editor (or `supabase db push`).
-- =============================================================================

-- Drop the old owner-only batch_purchases policy if the table exists.
DO $$
BEGIN
  IF to_regclass('public.batch_purchases') IS NOT NULL THEN
    EXECUTE 'DROP POLICY IF EXISTS "batch_purchases_delete" ON batch_purchases';
  END IF;
END $$;

-- Owner-or-editor DELETE policy on the batch and its child tables.
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
      'product_batches',
      'sales',
      'expenses',
      'packing_records',
      'packing_returns',
      'batch_vehicles',
      'batch_purchases',
      'batch_partners'
  ]
  LOOP
    IF to_regclass(format('public.%I', t)) IS NOT NULL THEN
      EXECUTE format('DROP POLICY IF EXISTS "batch_delete" ON %I', t);
      IF t = 'product_batches' THEN
        EXECUTE format(
          'CREATE POLICY "batch_delete" ON %I FOR DELETE USING '
          || '((i_am_owner() OR i_am_editor()) AND business_id = my_business_id())',
          t);
      ELSE
        EXECUTE format(
          'CREATE POLICY "batch_delete" ON %I FOR DELETE USING '
          || '((i_am_owner() OR i_am_editor()) AND batch_id IN ('
          || 'SELECT id FROM product_batches WHERE business_id = my_business_id()))',
          t);
      END IF;
    END IF;
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
