-- =============================================================================
-- COLD START RESET — TRUNCATE ALL DATA (DESTRUCTIVE, NO UNDO)
-- =============================================================================
-- Wipes every business table that exists in THIS database so the app starts
-- fresh. Run ONCE in the Supabase SQL editor, then sign up again — the
-- onboarding flow will recreate the user profile, business and
-- business_partner rows.
--
-- Robust: only tables that actually exist are truncated. Missing tables are
-- skipped and reported in a NOTICE (their rows would be wiped by CASCADE
-- through parent FKs anyway if a parent exists).
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

DO $reset$
DECLARE
    tbl     TEXT;
    missing TEXT[] := '{}';
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'user_profiles', 'businesses', 'business_partners', 'products',
        'markets', 'customers', 'customer_payments', 'customer_shares',
        'vehicles', 'product_batches', 'batch_partners', 'batch_purchases',
        'batch_vehicles', 'batch_settlements', 'packing_records',
        'packing_returns', 'sales', 'expenses', 'partner_transactions',
        'supplier_payments', 'suppliers', 'audit_logs'
    ]
    LOOP
        IF to_regclass('public.' || tbl) IS NOT NULL THEN
            EXECUTE format('TRUNCATE TABLE %I RESTART IDENTITY CASCADE', tbl);
            RAISE NOTICE 'TRUNCATED %', tbl;
        ELSE
            missing := missing || tbl;
        END IF;
    END LOOP;

    IF array_length(missing, 1) > 0 THEN
        RAISE NOTICE 'SKIPPED MISSING TABLES: %', array_to_string(missing, ', ');
    END IF;
END $reset$;

-- =============================================================================
-- Verification (optional — confirms remaining row counts)
-- =============================================================================
-- SELECT tablename, n_live_tup FROM pg_stat_user_tables
--   WHERE schemaname = 'public' ORDER BY tablename;
-- =============================================================================
