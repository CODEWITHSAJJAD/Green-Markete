-- =============================================================================
-- Migration 26 — RLS-proof phone claim (fixes "partner can't see my business")
-- =============================================================================
-- Why the client-side claim never worked:
--   * partners_select = business_id = my_business_id() OR user_id = auth.uid()
--     -> for an unclaimed row user_id IS NULL and my_business_id() returns
--        NULL for the brand-new user, so the SELECT silently returns 0 rows.
--   * partners_update USING has the same gap -> any UPDATE would raise 42501.
-- Fix: claim through a SECURITY DEFINER function that runs as the table owner
-- (bypasses RLS) and can ONLY ever link rows where user_id IS NULL, so it can
-- never steal an already-claimed business. Idempotent and exception-safe:
-- missing table / null inputs -> returns 0, never raises.
-- The normalizer maps local (03XXXXXXXXX) and E.164 (+92 3XXXXXXXXX) forms to
-- the same canonical digits so OTP sign-ins claim rows the owner typed locally.
-- =============================================================================

CREATE OR REPLACE FUNCTION normalize_phone(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  WITH d AS (
    SELECT regexp_replace(coalesce(p, ''), '\D', '', 'g') AS digits
  )
  SELECT CASE
    WHEN digits ~ '^0[0-9]{10}$' THEN substring(digits, 2)          -- 03XXXXXXXXX -> 3XXXXXXXXX
    WHEN digits ~ '^92[0-9]{10}$' THEN substring(digits, 3)         -- 92/92 3XXXXXXXXX -> 3XXXXXXXXX
    ELSE digits
  END
  FROM d;
$$;

CREATE OR REPLACE FUNCTION claim_partner_by_phone(p_user_id uuid, p_phone text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  IF p_user_id IS NULL OR p_phone IS NULL OR btrim(p_phone) = '' THEN
    RETURN 0;
  END IF;

  IF to_regclass('public.business_partners') IS NULL THEN
    RETURN 0;
  END IF;

  -- Only ever claims rows that are still unclaimed (user_id IS NULL).
  UPDATE business_partners
  SET user_id = p_user_id,
      is_claimed = true
  WHERE user_id IS NULL
    AND normalize_phone(phone) = normalize_phone(p_phone);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION normalize_phone(text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION claim_partner_by_phone(uuid, text) TO anon, authenticated;

-- =============================================================================
-- Verification
-- =============================================================================
-- SELECT claim_partner_by_phone('00000000-0000-0000-0000-000000000000', '03211234567');
--   -> returns the number of claimed partner rows (0 for the fake uuid).
-- =============================================================================
