-- =============================================================================
-- Migration 28 — Add member_type & permissions columns to business_partners
-- =============================================================================
-- Symptom: Partner Profile > "Access & Role Controls" lets an owner switch a
-- member between Staff/Employee and Business Partner, and toggle granular
-- permissions (can_purchase, can_sell, can_transport, can_expense,
-- can_close_batch). `PartnerRepository.updateMemberType` /
-- `.updatePermission` (partner_repository.dart) write these to the
-- `member_type` and `permissions` columns on `business_partners` — but those
-- columns were never added to this database. Every write silently failed
-- (caught) and the app fell back to storing member_type in on-device
-- SharedPreferences only, so it never synced across devices and never showed
-- up in the database. Granular permissions had no fallback at all for most
-- keys and were simply lost.
--
-- Fix: add the columns the Dart code has always expected so these controls
-- persist server-side like every other partner attribute.
-- =============================================================================

ALTER TABLE business_partners
  ADD COLUMN IF NOT EXISTS member_type text NOT NULL DEFAULT 'employee',
  ADD COLUMN IF NOT EXISTS permissions jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE business_partners
  DROP CONSTRAINT IF EXISTS business_partners_member_type_check;
ALTER TABLE business_partners
  ADD CONSTRAINT business_partners_member_type_check
  CHECK (member_type IN ('employee', 'partner'));

-- Owners are always business partners by definition.
UPDATE business_partners SET member_type = 'partner' WHERE role = 'owner';

-- PostgREST caches the schema; nudge it to pick up the new columns
-- immediately instead of waiting for the next automatic reload.
NOTIFY pgrst, 'reload schema';

-- =============================================================================
-- Verification (run after migration)
-- =============================================================================
 SELECT column_name, data_type, column_default
   FROM information_schema.columns
   WHERE table_name = 'business_partners'
     AND column_name IN ('member_type', 'permissions');
-- =============================================================================
