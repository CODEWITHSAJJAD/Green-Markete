-- =============================================================================
-- Migration 23 — Create the missing tables: batch_purchases, suppliers, customer_shares
-- =============================================================================
-- Why these are missing: migration 15 created `supplier_payments` (lines
-- 25-64) then hit `ALTER TABLE batch_purchases ENABLE ROW LEVEL SECURITY`
-- (line 88) which raised 42P01 on DBs without `batch_purchases` — aborting
-- the rest of the file, so the `suppliers` table (line 155+) never ran.
-- `customer_shares` comes from a backend migration never applied here.
--
-- Consequences this fixes (all silently skipped today):
--   * supplier dropdown empty (suggestions come from distinct
--     `batch_purchases.supplier_name`) — "acts like a text field"
--   * per-supplier purchase lines not saved on batch create
--   * Supplier Settlements / Ledger show nothing
--   * customer sharing probes return "not supported"
--
-- Tables (columns match the app's exact payloads):
--   * batch_purchases — one row per purchase line (same supplier may repeat
--     within a batch); payload from `batch_repository.dart:219-229`
--   * suppliers      — optional registry (migration 15 definition)
--   * customer_shares— both column shapes the app probes
--     (`customer_repository.dart:53-81`): business_id (shared WITH this
--     business) and shared_with_business_id (shared to another business)
--
-- RLS: same policy model as migration 20 (batch-scoped / business-scoped,
-- owner-or-editor writes). Idempotent.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. batch_purchases — per-supplier purchase lines of a batch
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS batch_purchases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID NOT NULL REFERENCES product_batches(id) ON DELETE CASCADE,
    market_id       UUID REFERENCES markets(id),
    supplier_name   TEXT NOT NULL,
    unit_label      TEXT,
    unit_kg         NUMERIC,
    quantity        NUMERIC NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price_per_unit  NUMERIC NOT NULL DEFAULT 0 CHECK (price_per_unit >= 0),
    payment_mode    TEXT,
    amount_paid     NUMERIC NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS batch_purchases_batch_idx
    ON batch_purchases (batch_id);
CREATE INDEX IF NOT EXISTS batch_purchases_supplier_idx
    ON batch_purchases (supplier_name);

ALTER TABLE batch_purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY batch_purchases_select ON batch_purchases
    FOR SELECT USING (
        batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id())
    );
CREATE POLICY batch_purchases_insert ON batch_purchases
    FOR INSERT TO authenticated WITH CHECK (
        batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id())
        AND (i_am_owner() OR i_am_editor())
    );
CREATE POLICY batch_purchases_update ON batch_purchases
    FOR UPDATE USING (
        batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id())
    ) WITH CHECK (
        batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id())
        AND (i_am_owner() OR i_am_editor())
    );
CREATE POLICY batch_purchases_delete ON batch_purchases
    FOR DELETE USING (
        batch_id IN (SELECT id FROM product_batches WHERE business_id = my_business_id())
        AND (i_am_owner() OR i_am_editor())
    );


-- -----------------------------------------------------------------------------
-- 2. suppliers — optional registry (Phase 9 foundation, from migration 15)
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

CREATE POLICY suppliers_select ON suppliers
    FOR SELECT USING (business_id = my_business_id());
CREATE POLICY suppliers_insert ON suppliers
    FOR INSERT TO authenticated WITH CHECK (
        business_id = my_business_id() AND (i_am_owner() OR i_am_editor())
    );
CREATE POLICY suppliers_update ON suppliers
    FOR UPDATE USING (business_id = my_business_id())
    WITH CHECK (business_id = my_business_id() AND (i_am_owner() OR i_am_editor()));
CREATE POLICY suppliers_delete ON suppliers
    FOR DELETE USING (business_id = my_business_id() AND (i_am_owner() OR i_am_editor()));


-- -----------------------------------------------------------------------------
-- 3. customer_shares — both column shapes the app probes
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_shares (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id             UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    business_id             UUID REFERENCES businesses(id) ON DELETE CASCADE,
    shared_with_business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (business_id IS NOT NULL OR shared_with_business_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS customer_shares_customer_idx
    ON customer_shares (customer_id);
CREATE INDEX IF NOT EXISTS customer_shares_business_idx
    ON customer_shares (business_id);
CREATE INDEX IF NOT EXISTS customer_shares_shared_with_idx
    ON customer_shares (shared_with_business_id);

ALTER TABLE customer_shares ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_shares_select ON customer_shares
    FOR SELECT USING (
        business_id = my_business_id()
        OR shared_with_business_id = my_business_id()
    );
CREATE POLICY customer_shares_insert ON customer_shares
    FOR INSERT TO authenticated WITH CHECK (
        (business_id = my_business_id() OR shared_with_business_id = my_business_id())
        AND (i_am_owner() OR i_am_editor())
    );
CREATE POLICY customer_shares_update ON customer_shares
    FOR UPDATE USING (
        business_id = my_business_id() OR shared_with_business_id = my_business_id()
    ) WITH CHECK (
        (business_id = my_business_id() OR shared_with_business_id = my_business_id())
        AND (i_am_owner() OR i_am_editor())
    );
CREATE POLICY customer_shares_delete ON customer_shares
    FOR DELETE USING (
        (business_id = my_business_id() OR shared_with_business_id = my_business_id())
        AND (i_am_owner() OR i_am_editor())
    );


-- =============================================================================
-- Verification (run after migration — should list 3 tables, 4/4/4 policies)
-- =============================================================================
-- SELECT tablename, count(*) AS policies FROM pg_policies
--   WHERE schemaname = 'public'
--     AND tablename IN ('batch_purchases','suppliers','customer_shares')
--   GROUP BY tablename ORDER BY tablename;
-- =============================================================================