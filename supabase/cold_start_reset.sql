-- =============================================================================
-- COLD START RESET — TRUNCATE ALL DATA (DESTRUCTIVE, NO UNDO)
-- =============================================================================
-- Wipes every business table so the app starts fresh. Run ONCE in the
-- Supabase SQL editor, then sign up again — the onboarding flow will recreate
-- the user profile, business and business_partner rows.
--
-- NOT touched:
--   * auth.users / auth schema — sign-in accounts survive (user_profiles rows
--     below are wiped; they are recreated by AuthRepository.createUserProfile
--     on next login/onboarding).
--   * v_city_market_performance — a VIEW; it cannot be truncated (its data
--     derives from the underlying tables above).
--
-- CASCADE also truncates any OTHER table with an FK into the listed tables,
-- so nothing referencing the business graph survives.
-- =============================================================================

TRUNCATE TABLE
    user_profiles,
    businesses,
    business_partners,
    products,
    markets,
    customers,
    customer_payments,
    customer_shares,
    vehicles,
    product_batches,
    batch_partners,
    batch_purchases,
    batch_vehicles,
    batch_settlements,
    packing_records,
    packing_returns,
    sales,
    expenses,
    partner_transactions,
    supplier_payments,
    suppliers,
    audit_logs
RESTART IDENTITY CASCADE;

-- =============================================================================
-- Verification (optional — should print 22 rows, all 0 counts)
-- =============================================================================
-- SELECT tablename, n_live_tup FROM pg_stat_user_tables
--   WHERE schemaname = 'public' ORDER BY tablename;
-- =============================================================================
