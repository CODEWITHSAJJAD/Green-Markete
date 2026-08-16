-- =============================================================================
-- Migration 30 — Business-owned measurement units & packing types
-- =============================================================================
-- Feature request: purchases and packing were hardcoded to a fixed list of
-- units (kg, mann/40kg, 5/10/60/100kg bags, 15/20kg crates) baked into the
-- Flutter app (`core/utils/unit_converter.dart`). Real mandi operations vary
-- per business — a purchaser needs to record a purchase against whatever
-- measurement a specific supplier uses (e.g. a 25kg "peti"), and packing
-- needs whatever bag/crate sizes are actually on hand. This migration adds
-- two new business-scoped reference tables so each business can create its
-- own units/packing types on top of the app's built-in defaults (the fixed
-- list stays as-is for backward compatibility — this is additive, not a
-- replacement).
-- =============================================================================

CREATE TABLE IF NOT EXISTS measurement_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name text NOT NULL,
  kg_per_unit numeric NOT NULL CHECK (kg_per_unit > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS packing_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name text NOT NULL,
  kg_capacity numeric NOT NULL CHECK (kg_capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE measurement_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE packing_types ENABLE ROW LEVEL SECURITY;

-- Same per-row membership model as every other business-scoped table
-- (migration 29's i_am_member_of): any claimed member can read/write; the
-- app gates the "Units & Packing" management page to owner/purchaser-editor
-- roles, matching how Vehicles is gated.
DO $mig$
DECLARE
    t RECORD;
BEGIN
    FOR t IN SELECT unnest(ARRAY['measurement_units', 'packing_types']) AS tablename
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_select', t.tablename);
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_insert', t.tablename);
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_update', t.tablename);
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t.tablename || '_delete', t.tablename);
            EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (business_id IN (SELECT my_business_ids()))', t.tablename || '_select', t.tablename);
            EXECUTE format('CREATE POLICY %I ON %I FOR INSERT TO authenticated WITH CHECK (i_am_member_of(business_id))', t.tablename || '_insert', t.tablename);
            EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE USING (i_am_member_of(business_id)) WITH CHECK (i_am_member_of(business_id))', t.tablename || '_update', t.tablename);
            EXECUTE format('CREATE POLICY %I ON %I FOR DELETE USING (i_am_member_of(business_id))', t.tablename || '_delete', t.tablename);
            RAISE NOTICE 'RLS policies ready on %', t.tablename;
        EXCEPTION WHEN others THEN
            RAISE NOTICE 'ERROR adding RLS on %: %', t.tablename, SQLERRM;
        END;
    END LOOP;
END $mig$;

-- =============================================================================
-- Verification (run after migration)
-- =============================================================================
-- SELECT tablename, policyname, cmd FROM pg_policies
--   WHERE schemaname = 'public' AND tablename IN ('measurement_units', 'packing_types')
--   ORDER BY tablename, cmd;
-- =============================================================================
