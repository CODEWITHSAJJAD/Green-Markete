-- =============================================================================
-- Migration 24 — allow all purchase payment modes on product_batches.purchase_payment_mode
-- =============================================================================
-- The live CHECK on product_batches.purchase_payment_mode was created by the
-- backend's ALTER and only accepted 'cash'/'debt'. The app's purchase form
-- (purchase_entry_form.dart) offers richer per-line modes
-- ('cash','bank_transfer','debt','credit','pdc','part_credit'), and the wizard
-- aggregates them onto purchase_payment_mode (single mode when all lines match,
-- 'part_credit' when mixed). Sending any non-('cash'/'debt') value raised
-- 23514 check_violation and aborted batch creation.
--
-- Fix: drop whichever legacy constraint name exists and re-add an explicitly
-- named constraint accepting every mode the app sends. Existing rows only ever
-- held 'cash'/'debt' (or NULL), all of which remain valid, so the new CHECK
-- cannot fail on backfill.
-- =============================================================================

DO $$
BEGIN
  ALTER TABLE product_batches
    DROP CONSTRAINT IF EXISTS product_batches_purchase_payment_mode_check;
  ALTER TABLE product_batches
    DROP CONSTRAINT IF EXISTS product_batches_payment_mode_check;
END $$;

ALTER TABLE product_batches
  ADD CONSTRAINT product_batches_purchase_payment_mode_check
  CHECK (purchase_payment_mode IN ('cash','bank_transfer','debt','credit','pdc','part_credit'));


-- =============================================================================
-- Verification (run after applying):
-- SELECT conname, pg_get_constraintdef(oid)
--   FROM pg_constraint
--   WHERE conrelid = 'product_batches'::regclass AND contype = 'c';
-- Expect a single row: product_batches_purchase_payment_mode_check with
-- CHECK ((purchase_payment_mode = ANY (ARRAY['cash'::text, ...])))
-- =============================================================================
