-- =============================================================================
-- MandiRoznamcha (منڈی روزنامچہ) — Production RLS & Access Policies
-- =============================================================================
-- Security Architecture:
-- 1. Multi-Business Scoping: All entities are isolated per Mandi Commission Shop (business_id).
-- 2. Role-Based Access Control (RBAC):
--    - Arthi (Shop Owner): Full administrative, financial, and Safaya permissions.
--    - Hissedar (Partner): Access to assigned lots, shared capital, and partner P&L.
--    - Munshi (Accountant): Access to Roznamcha daybook, Bikri Parchis, and Khata Wasooli.
--    - Purchaser / Field Agent: Access to Aamad Maal, Zamindar purchase logging, and vehicle loading.
--    - Seller / Auctioneer: Access to Boli auction sales, Customer lot distribution, and daily Bikri.
-- 3. Core Tables Protected:
--    - `businesses` (Mandi Commission Shops)
--    - `business_partners` (Hissedar & Munshi directory)
--    - `product_batches` (Aamad Maal / Produce Lots)
--    - `batch_purchases` (Zamindar / Beopari / Arhat Shop procurement)
--    - `batch_sales` (Bikri & Boli auctions)
--    - `customers` (Khareedar / Customer directory)
--    - `customer_payments` (Baqaya Wasooli records)
--    - `supplier_settlements` (Zamindar Safaya & commission deduction statements)
--    - `transactions` (Roznamcha ledger transactions)
--    - `products`, `markets`, `vehicles` (Catalogs, Mandis, and transport fleet)
-- =============================================================================

-- Ensure RLS is active on all core tables
ALTER TABLE IF EXISTS public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.business_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.product_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.batch_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.batch_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.customer_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.supplier_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.markets ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.vehicles ENABLE ROW LEVEL SECURITY;

-- Note: Policies leverage the multi-business helper `my_business_ids()` established in Migration 25.
