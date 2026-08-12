-- =============================================================================
-- Migration 15 — Supplier Settlement (daily-61)
-- =============================================================================
-- Adds the `supplier_payments` table needed by the Supplier Settlements
-- feature (sidebar > Manage > Supplier Settlements). Per-line outstanding is
-- computed from `batch_purchases` (Σ quantity × price_per_unit − amount_paid
-- per supplier_name); this table stores post-purchase payments so the
-- "Record Payment" flow can settle a supplier's running balance.
--
-- Mirrors `customer_payments` (the customer-credit analog):
--   business_id + customer_id ↔ supplier_name (free-text, since supplier
--   registry is still PLANNED — Phase 9 of `OPERATIONS_FEATURES_PLAN.md`).
--
-- Frontend defensive code: BatchRepository wraps every access in `_safeSelect`
-- (`PGRST205` / `42P01` / `42703` → empty list) so the UI degrades to an
-- empty settlements list if this table is missing.
--
-- Apply via the Supabase SQL editor (or `supabase db push`).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. `supplier_payments` — post-purchase payments to a supplier
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS supplier_payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id     UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    supplier_name   TEXT NOT NULL,
    amount          NUMERIC NOT NULL CHECK (amount > 0),
    payment_mode    TEXT NOT NULL CHECK (payment_mode IN ('cash','bank_transfer')),
    bank_reference  TEXT,
    payment_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    received_by     UUID REFERENCES business_partners(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS supplier_payments_business_name_idx
    ON supplier_payments (business_id, supplier_name);

CREATE INDEX IF NOT EXISTS supplier_payments_business_date_idx
    ON supplier_payments (business_id, payment_date DESC);

ALTER TABLE supplier_payments ENABLE ROW LEVEL SECURITY;

-- Anyone in the business can view supplier payments.
CREATE POLICY "supplier_payments_select" ON supplier_payments
    FOR SELECT USING (business_id = my_business_id());

-- Owner and editor can record supplier payments.
CREATE POLICY "supplier_payments_insert" ON supplier_payments
    FOR INSERT WITH CHECK (
        business_id = my_business_id()
        AND (i_am_owner() OR i_am_editor())
    );

-- Only owner can update payment records (audit trail).
CREATE POLICY "supplier_payments_update" ON supplier_payments
    FOR UPDATE USING (business_id = my_business_id())
    WITH CHECK (i_am_owner() AND business_id = my_business_id());

-- Only owner can delete payment records (audit trail).
CREATE POLICY "supplier_payments_delete" ON supplier_payments
    FOR DELETE USING (i_am_owner() AND business_id = my_business_id());


-- -----------------------------------------------------------------------------
-- 2. `batch_purchases` RLS — assumed missing (daily-59 ship without it)
-- -----------------------------------------------------------------------------
-- The wizard inserts one row per supplier-line into `batch_purchases` on
-- batch create (`batch_repository.dart:170-190`). The Supplier Settlements
-- ledger needs to read from this table joined to `product_batches`. Without
-- RLS, the row-level gateway is open (any logged-in user can see any
-- business's purchase lines), so add the policies below.
--
-- Idempotent: skip if RLS is already enabled.
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'public' AND tablename = 'batch_purchases'
    ) THEN
        RAISE NOTICE 'batch_purchases table not present — run daily-59 migration first';
    END IF;
END $$;

ALTER TABLE batch_purchases ENABLE ROW LEVEL SECURITY;

-- Read: anyone in the business. SELECT can't easily filter by batch_id's
-- business_id from a RLS policy on `batch_purchases` alone, so use a subquery.
CREATE POLICY "batch_purchases_select" ON batch_purchases
    FOR SELECT USING (
        batch_id IN (
            SELECT id FROM product_batches
            WHERE business_id = my_business_id()
        )
    );

-- Write: owner or editor, on batches that aren't closed.
CREATE POLICY "batch_purchases_insert" ON batch_purchases
    FOR INSERT WITH CHECK (
        batch_id IN (
            SELECT id FROM product_batches
            WHERE business_id = my_business_id()
              AND status != 'closed'
        )
        AND (i_am_owner() OR i_am_editor())
    );

CREATE POLICY "batch_purchases_update" ON batch_purchases
    FOR UPDATE USING (
        batch_id IN (
            SELECT id FROM product_batches
            WHERE business_id = my_business_id()
              AND status != 'closed'
        )
    )
    WITH CHECK (
        batch_id IN (
            SELECT id FROM product_batches
            WHERE business_id = my_business_id()
        )
        AND (i_am_owner() OR i_am_editor())
    );

CREATE POLICY "batch_purchases_delete" ON batch_purchases
    FOR DELETE USING (
        i_am_owner()
        AND batch_id IN (
            SELECT id FROM product_batches
            WHERE business_id = my_business_id()
        )
    );


-- -----------------------------------------------------------------------------
-- 3. Realtime — enable for supplier_payments so the ledger auto-refreshes
-- -----------------------------------------------------------------------------
-- The Flutter pages `SupplierSettlementPage` and `SupplierLedgerPage` subscribe
-- to `supplier_payments` writes via `postgres_changes`. Realtime must be
-- enabled on the table for those subscriptions to fire.
-- -----------------------------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE supplier_payments;


-- -----------------------------------------------------------------------------
-- 4. (Optional) `suppliers` registry — Phase 9 foundation
-- -----------------------------------------------------------------------------
-- The Phase 9 registry table from `OPERATIONS_FEATURES_PLAN.md`. The Frontend
-- app does NOT depend on this yet — it accepts free-text supplier names and
-- groups by `supplier_name`. This is here so you can add the table now and
-- the app will probe it defensively later.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suppliers (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id   UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name          TEXT NOT NULL,
    phone         TEXT,
    city          TEXT,
    market_id     UUID REFERENCES markets(id),
    notes         TEXT,
    is_archived   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (business_id, name)
);

CREATE INDEX IF NOT EXISTS suppliers_business_name_idx
    ON suppliers (business_id, name);

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "suppliers_select" ON suppliers
    FOR SELECT USING (business_id = my_business_id());

CREATE POLICY "suppliers_insert" ON suppliers
    FOR INSERT WITH CHECK (i_am_owner() AND business_id = my_business_id());

CREATE POLICY "suppliers_update" ON suppliers
    FOR UPDATE USING (i_am_owner() AND business_id = my_business_id())
    WITH CHECK (i_am_owner() AND business_id = my_business_id());

CREATE POLICY "suppliers_delete" ON suppliers
    FOR DELETE USING (i_am_owner() AND business_id = my_business_id());


-- =============================================================================
-- Verification (run after migration to confirm RLS + tables)
-- =============================================================================
-- SELECT tablename, rowsecurity FROM pg_tables
--   WHERE schemaname = 'public'
--     AND tablename IN ('supplier_payments','batch_purchases','suppliers');
-- SELECT tablename, policyname FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('supplier_payments','batch_purchases','suppliers')
--   ORDER BY tablename, policyname;
-- =============================================================================
