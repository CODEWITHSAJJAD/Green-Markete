# 🔒 Security & Access Control Document
## Green Market — Supabase RLS & Auth Policy

**Version:** 2.1 (Operations Features) — Supersedes 2.0
**Date:** August 2026

> **Planned (see `05_MultiUser_RBAC_Plan.md`):** this document still assumes one business per user (`my_business_id()` returns a single id). The multi-user RBAC plan replaces the single-business helpers with `my_business_ids()` + per-business access helpers, extends the role matrix with **side-scoped** permissions (edit own side / view other side), and adds a per-partner cross-side grant. That rework is **not implemented yet** — until it lands, this v2.1 document is the live security reference.

> **Version 2.1 changes:** adds role rules for the operations features (day-end close, supplier payables, per-batch credit, packing returns, shared customers/vehicles), RLS policy templates for the **[PLANNED]** tables (`batch_vehicles`, `vehicle_loads`, `packing_returns`, `suppliers`, `packing_materials`, `customer_shares`, `vehicle_shares`), and a note on the app's defensive probing of unbacked tables. RLS template form for new tables is the same as §3 — read on.

---

## Table of Contents

1. [Authentication Design](#1-authentication-design)
2. [Role System](#2-role-system)
3. [Row Level Security (RLS) Policies](#3-row-level-security-rls-policies)
4. [Flutter Client Security](#4-flutter-client-security)
5. [Sensitive Data Handling](#5-sensitive-data-handling)
6. [Audit Trail](#6-audit-trail)
7. [Profile Claim Flow Security](#7-profile-claim-flow-security)
8. [Pre-Launch Security Checklist](#8-pre-launch-security-checklist)

---

## 1. Authentication Design

### 1.1 Provider: Supabase Auth

All authentication is handled by Supabase Auth. JWTs are issued by Supabase, signed with project-scoped keys, and validated automatically by PostgREST on every database call.

### 1.2 Login Methods

| Method | Details |
|--------|---------|
| **Phone OTP (Primary)** | 6-digit SMS code, expires in 5 minutes, 3 attempts max before lockout |
| **Email + Password (Secondary)** | Standard Supabase email auth, minimum 8-character password |

### 1.3 Session Management

| Setting | Value |
|---------|-------|
| Access token expiry | 1 hour |
| Refresh token expiry | 30 days (rolling) |
| Storage in Flutter | `SharedPreferences` (Supabase handles internally) |
| Auto-refresh | Supabase Flutter SDK handles silently |
| Logout | Calls `supabase.auth.signOut()` → clears all tokens |

### 1.4 OTP Security Rules

- OTP expires after **5 minutes**.
- Maximum **3 failed attempts** → 30-minute lockout.
- OTP cannot be reused.
- Rate limit: **5 OTP requests per phone per hour** (Supabase default; configure in dashboard).

### 1.5 Profile Claim via Phone Match

When a user signs up with a phone number that matches an existing `business_partners.phone` entry with `is_claimed = FALSE`:

```sql
-- Supabase Auth webhook / trigger on auth.users INSERT
CREATE OR REPLACE FUNCTION handle_new_user_claim()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if a business_partners record with this phone is unclaimed
  UPDATE business_partners
  SET
    user_id    = NEW.id,
    is_claimed = TRUE,
    joined_at  = NOW()
  WHERE phone = NEW.phone
    AND is_claimed = FALSE;

  -- Create user_profile record
  INSERT INTO user_profiles (id, full_name, phone)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.phone)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user_claim();
```

---

## 2. Role System

### 2.1 Role Definitions

Roles are stored in `business_partners.role` and `business_partners.access_level`. The JWT does **not** carry the role — it is always fetched from the database at runtime and enforced via RLS.

```
business_partners.role:
  purchaser  → buys products
  seller     → sells products
  both       → handles both (single-owner mode)
  accountant → financial visibility only

business_partners.access_level:
  editor → can write (create batches, add expenses, record sales)
  viewer → read-only
```

### 2.2 What Each Level Can Do

| Action | Owner | Editor Partner | Viewer Partner | Accountant |
|--------|:-----:|:--------------:|:--------------:|:----------:|
| Create batch | ✅ | ✅ | ❌ | ❌ |
| Add expenses to batch | ✅ | ✅ own batches | ❌ | ✅ |
| Record sale | ✅ | ✅ (seller role) | ❌ | ❌ |
| Record customer payment | ✅ | ✅ | ❌ | ❌ |
| Void expense (soft delete) | ✅ | ❌ | ❌ | ❌ |
| Change batch status | ✅ | ✅ own batches | ❌ | ❌ |
| Create partner profile | ✅ | ❌ | ❌ | ❌ |
| Change partner access level | ✅ | ❌ | ❌ | ❌ |
| Create markets | ✅ | ❌ | ❌ | ❌ |
| View P&L | ✅ | ✅ own batches | ✅ own batches | ✅ all |
| View customer ledger | ✅ | ✅ | ✅ | ✅ |
| Export PDF | ✅ | ✅ | ✅ | ✅ |
| View audit logs | ✅ | ❌ | ❌ | ❌ |
| **Day-end close** (V2.1) | ✅ | ✅ (seller role) | ❌ | ❌ |
| **Supplier payable** view/pay (V2.1) | ✅ | ✅ own batches | ✅ own batches | ✅ |
| **Packing return / reusable material** (V2.1) | ✅ | ✅ own batches | ❌ | ❌ |
| **Per-batch credit collection** (V2.1) | ✅ | ✅ | ❌ | ❌ |
| **Shared customers/vehicles** (V2.1) | ✅ | ✅ | ✅ | ✅ |

> **V2.1 note:** the matrix above extends the 2.0 baseline. Sharing rows (customers/vehicles) are readable by all members of any business that shares them; write access stays with the owning business.

---

## 3. Row Level Security (RLS) Policies

**Golden rule:** Every table has `ALTER TABLE <name> ENABLE ROW LEVEL SECURITY;` applied before any policy. No exceptions.

### 3.1 Helper Function

```sql
-- Returns the business_id for the current authenticated user
CREATE OR REPLACE FUNCTION my_business_id()
RETURNS UUID AS $$
  SELECT business_id FROM business_partners
  WHERE user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Returns TRUE if the current user is the owner of their business
CREATE OR REPLACE FUNCTION i_am_owner()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM businesses
    WHERE owner_id = auth.uid()
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Returns TRUE if current user is an editor-level partner in their business
CREATE OR REPLACE FUNCTION i_am_editor()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM business_partners
    WHERE user_id = auth.uid()
      AND access_level = 'editor'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

### 3.2 `user_profiles`

```sql
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Read own profile OR profiles of partners in same business
CREATE POLICY "user_profiles_select" ON user_profiles
  FOR SELECT USING (
    id = auth.uid()
    OR id IN (
      SELECT up2.id FROM user_profiles up2
      JOIN business_partners bp2 ON bp2.user_id = up2.id
      WHERE bp2.business_id = my_business_id()
    )
  );

-- Only update own profile
CREATE POLICY "user_profiles_update" ON user_profiles
  FOR UPDATE USING (id = auth.uid());

-- Insert only on signup (handled by trigger)
CREATE POLICY "user_profiles_insert" ON user_profiles
  FOR INSERT WITH CHECK (id = auth.uid());
```

### 3.3 `businesses`

```sql
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

-- See own business only
CREATE POLICY "businesses_select" ON businesses
  FOR SELECT USING (
    id = my_business_id()
  );

-- Create own business (on onboarding)
CREATE POLICY "businesses_insert" ON businesses
  FOR INSERT WITH CHECK (owner_id = auth.uid());

-- Only owner can update business settings
CREATE POLICY "businesses_update" ON businesses
  FOR UPDATE USING (owner_id = auth.uid());
```

### 3.4 `business_partners`

```sql
ALTER TABLE business_partners ENABLE ROW LEVEL SECURITY;

-- All partners in same business can see each other
CREATE POLICY "bp_select" ON business_partners
  FOR SELECT USING (business_id = my_business_id());

-- Only owner can create/modify partner records
CREATE POLICY "bp_insert" ON business_partners
  FOR INSERT WITH CHECK (
    i_am_owner()
    AND business_id = my_business_id()
  );

CREATE POLICY "bp_update" ON business_partners
  FOR UPDATE USING (i_am_owner() AND business_id = my_business_id());
```

### 3.5 `markets`

```sql
ALTER TABLE markets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "markets_select" ON markets
  FOR SELECT USING (business_id = my_business_id());

-- Only owner can manage markets
CREATE POLICY "markets_insert" ON markets
  FOR INSERT WITH CHECK (i_am_owner() AND business_id = my_business_id());

CREATE POLICY "markets_update" ON markets
  FOR UPDATE USING (i_am_owner() AND business_id = my_business_id());
```

### 3.6 `products`

```sql
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "products_select" ON products
  FOR SELECT USING (business_id = my_business_id());

-- Editors and owners can create products
CREATE POLICY "products_insert" ON products
  FOR INSERT WITH CHECK (
    business_id = my_business_id()
    AND (i_am_owner() OR i_am_editor())
  );
```

### 3.7 `product_batches`

```sql
ALTER TABLE product_batches ENABLE ROW LEVEL SECURITY;

-- Partners can only see batches they are assigned to (or all if owner/accountant)
CREATE POLICY "batches_select" ON product_batches
  FOR SELECT USING (
    business_id = my_business_id()
    AND (
      i_am_owner()
      OR id IN (
        SELECT batch_id FROM batch_partners bp
        WHERE bp.partner_id IN (
          SELECT id FROM business_partners WHERE user_id = auth.uid()
        )
      )
      OR EXISTS (
        SELECT 1 FROM business_partners
        WHERE user_id = auth.uid()
          AND role = 'accountant'
          AND business_id = my_business_id()
      )
    )
  );

-- Editors and owners can create batches
CREATE POLICY "batches_insert" ON product_batches
  FOR INSERT WITH CHECK (
    business_id = my_business_id()
    AND (i_am_owner() OR i_am_editor())
  );

-- Editors can update their own batches; owner can update any
CREATE POLICY "batches_update" ON product_batches
  FOR UPDATE USING (
    business_id = my_business_id()
    AND (
      i_am_owner()
      OR (i_am_editor() AND id IN (
        SELECT batch_id FROM batch_partners
        WHERE partner_id IN (
          SELECT id FROM business_partners WHERE user_id = auth.uid()
        )
      ))
    )
  );
```

### 3.8 `expenses`

```sql
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- View expenses on accessible batches
CREATE POLICY "expenses_select" ON expenses
  FOR SELECT USING (
    business_id = my_business_id()
    AND batch_id IN (
      SELECT id FROM product_batches  -- inherits batch_select logic
    )
  );

-- Editors and accountants can add expenses; batch must be accessible
CREATE POLICY "expenses_insert" ON expenses
  FOR INSERT WITH CHECK (
    business_id = my_business_id()
    AND (i_am_owner() OR i_am_editor() OR EXISTS (
      SELECT 1 FROM business_partners
      WHERE user_id = auth.uid() AND role = 'accountant' AND business_id = my_business_id()
    ))
    AND batch_id IN (SELECT id FROM product_batches WHERE status != 'closed')
  );

-- Only owner can void expenses (soft delete)
CREATE POLICY "expenses_update" ON expenses
  FOR UPDATE USING (i_am_owner() AND business_id = my_business_id());
```

### 3.9 `sales`

```sql
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sales_select" ON sales
  FOR SELECT USING (
    business_id = my_business_id()
    AND batch_id IN (SELECT id FROM product_batches)  -- inherits batch visibility
  );

-- Only seller-role partners (or owner) can record sales
CREATE POLICY "sales_insert" ON sales
  FOR INSERT WITH CHECK (
    business_id = my_business_id()
    AND (
      i_am_owner()
      OR (
        i_am_editor()
        AND EXISTS (
          SELECT 1 FROM batch_partners bp
          JOIN business_partners bizp ON bizp.id = bp.partner_id
          WHERE bp.batch_id = sales.batch_id
            AND bizp.user_id = auth.uid()
            AND bp.role IN ('seller', 'both')
        )
      )
    )
    AND batch_id IN (SELECT id FROM product_batches WHERE status = 'selling')
  );
```

### 3.10 `customers`

```sql
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customers_all" ON customers
  FOR ALL USING (business_id = my_business_id())
  WITH CHECK (business_id = my_business_id());
```

### 3.11 `customer_payments`

```sql
ALTER TABLE customer_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customer_payments_select" ON customer_payments
  FOR SELECT USING (business_id = my_business_id());

CREATE POLICY "customer_payments_insert" ON customer_payments
  FOR INSERT WITH CHECK (
    business_id = my_business_id()
    AND (i_am_owner() OR i_am_editor())
  );
```

### 3.12 `partner_transactions`

```sql
ALTER TABLE partner_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "partner_tx_all" ON partner_transactions
  FOR ALL USING (business_id = my_business_id())
  WITH CHECK (business_id = my_business_id());
```

### 3.13 `audit_logs`

```sql
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Only owner can read audit logs
CREATE POLICY "audit_select" ON audit_logs
  FOR SELECT USING (i_am_owner());

-- Only the system (SECURITY DEFINER functions) can insert
-- No user-facing insert policy → all inserts via trusted functions
```

### 3.14 `packing_records`

```sql
ALTER TABLE packing_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "packing_select" ON packing_records
  FOR SELECT USING (
    batch_id IN (SELECT id FROM product_batches)
  );

CREATE POLICY "packing_insert" ON packing_records
  FOR INSERT WITH CHECK (
    batch_id IN (
      SELECT id FROM product_batches WHERE status != 'closed'
    )
    AND batch_id IN (SELECT id FROM product_batches)
    AND (i_am_owner() OR i_am_editor())
  );
```

### 3.15 Planned Tables (V2.1) — RLS Templates

These tables are **[PLANNED]** (Phases 7–11, see `OPERATIONS_FEATURES_PLAN.md`). Apply these policies **when the backend adds each table**. Until then the app must not assume they exist — it probes defensively and degrades (see §4.5).

**`batch_vehicles` / `vehicle_loads`** — business-scoped like batches:
```sql
ALTER TABLE batch_vehicles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "batch_vehicles_select" ON batch_vehicles
  FOR SELECT USING (business_id = my_business_id());
CREATE POLICY "batch_vehicles_write" ON batch_vehicles
  FOR INSERT WITH CHECK ((i_am_owner() OR i_am_editor()) AND business_id = my_business_id());
-- UPDATE / DELETE mirror bp_update (owner/editor, same business)
-- vehicle_loads: same pattern keyed off batch_id (SELECT via product_batches join, write for owner/editor on non-closed batches)
```

**`packing_returns`** — read by batch members, write for owner/editor on non-closed batches:
```sql
ALTER TABLE packing_returns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "packing_returns_select" ON packing_returns
  FOR SELECT USING (batch_id IN (SELECT id FROM product_batches));
CREATE POLICY "packing_returns_insert" ON packing_returns
  FOR INSERT WITH CHECK (
    batch_id IN (SELECT id FROM product_batches WHERE status != 'closed')
    AND (i_am_owner() OR i_am_editor())
  );
```

**`suppliers` / `packing_materials`** — business-scoped registries, owner-managed writes:
```sql
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "suppliers_select" ON suppliers
  FOR SELECT USING (business_id = my_business_id());
CREATE POLICY "suppliers_write" ON suppliers
  FOR INSERT WITH CHECK (i_am_owner() AND business_id = my_business_id());
-- UPDATE only owner. packing_materials: identical shape.
```

**`customer_shares` / `vehicle_shares`** — **cross-business**. A share row grants read access to a second business:
```sql
ALTER TABLE customer_shares ENABLE ROW LEVEL SECURITY;
CREATE POLICY "customer_shares_select" ON customer_shares
  FOR SELECT USING (
    business_id = my_business_id()                    -- owning business
    OR shared_with_business_id = my_business_id()     -- receiving business
  );
CREATE POLICY "customer_shares_write" ON customer_shares
  FOR INSERT WITH CHECK (
    i_am_owner() AND business_id = my_business_id()
  );
-- UPDATE/DELETE: owning business owner only.
-- vehicle_shares: identical shape.
```
> Do not rely on these tables today — `customer_shares` currently returns PostgREST 404 (table absent). The app handles that gracefully (Phase 6 indicator + Phase 11 full support).

### 4.1 ANON Key Is Safe to Bundle

The Supabase `ANON_KEY` is a public key — it is not a secret. RLS policies enforce all access restrictions. The service role key is **never** used in the Flutter app.

```dart
// SAFE — anon key + RLS controls access
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
```

### 4.2 JWT Validation

Every Supabase database call from Flutter automatically includes the JWT in the `Authorization: Bearer` header. PostgREST validates the JWT signature on every request — no manual token passing needed.

### 4.3 Input Validation (Dart-Side)

Before any Supabase call, validate:
- Amount fields: must be numeric, ≥ 0
- Quantity sold: must not exceed remaining quantity
- Dates: not in the future for expense/sale records
- Phone numbers: 11-digit Pakistan format validation
- Batch status transitions: must follow the allowed forward-only flow

```dart
class Validators {
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final n = double.tryParse(value);
    if (n == null) return 'Enter a valid number';
    if (n < 0) return 'Amount cannot be negative';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final clean = value.replaceAll(' ', '').replaceAll('-', '');
    if (!RegExp(r'^(03\d{9}|\+923\d{9})$').hasMatch(clean)) {
      return 'Enter a valid Pakistan phone number';
    }
    return null;
  }
}
```

### 4.4 No Sensitive Data in Logs

```dart
// Production: disable all debug logging
void logError(String context, dynamic error) {
  if (kDebugMode) {
    debugPrint('[$context] Error: $error');
  }
  // Never log user data, tokens, or financial amounts in production
}
```

### 4.5 Defensive Probing of Unbacked Tables (V2.1)

Features on the roadmap read/write tables that may not exist yet. The app **probes** before depending on them and degrades gracefully:

```dart
// Example: probe a column before sending it (customer_payments.batch_id)
final ok = await _client
    .from('customer_payments')
    .select('batch_id')
    .limit(1)
    .maybeSingle();          // 4xx / 42703 → treat column as absent

// Example: probe a whole table before reading it (customer_shares)
final rows = await _client
    .from('customer_shares')
    .select('id')
    .limit(1)
    .catchError((_) => <Map<String, dynamic>>[]);   // 404 → unsupported
```

Rules: (1) a probe failure is **never** a crash — it flips a capability flag to `false`; (2) 4xx on an unbacked table is expected, not an error to surface; (3) feature UI hides/disables itself when the flag is false (e.g., "Shared" filter only appears when the probe succeeds).

---

## 5. Sensitive Data Handling

| Field | Handling |
|-------|---------|
| Phone number | Stored plaintext — needed for OTP auth and claim matching |
| CNIC | Optional. If stored, use pgcrypto to encrypt at rest |
| Bank account | Store last 4 digits only; display as `****1234` |
| JWT tokens | Managed by Supabase Flutter SDK (stored in app-level storage) |
| Financial amounts | No encryption needed — RLS prevents unauthorized access |
| Receipts/photos | Stored in Supabase Storage private bucket — requires authenticated URL |

### 5.1 CNIC Encryption (Optional)

```sql
-- Enable pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Store encrypted
UPDATE user_profiles
SET cnic = pgp_sym_encrypt(cnic_plaintext, current_setting('app.encryption_key'))
WHERE id = <user_id>;

-- Read decrypted (only in SECURITY DEFINER functions)
SELECT pgp_sym_decrypt(cnic::bytea, current_setting('app.encryption_key'))
FROM user_profiles WHERE id = <user_id>;
```

---

## 6. Audit Trail

All critical write operations (expense void, batch status change, partner access change) log to `audit_logs` via PostgreSQL triggers.

### 6.1 Expense Void Trigger

```sql
CREATE OR REPLACE FUNCTION log_expense_void()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_voided = TRUE AND OLD.is_voided = FALSE THEN
    INSERT INTO audit_logs (table_name, record_id, action, performed_by, old_values, new_values)
    VALUES (
      'expenses', OLD.id, 'VOID',
      auth.uid(),
      jsonb_build_object('amount', OLD.amount, 'description', OLD.description, 'is_voided', FALSE),
      jsonb_build_object('is_voided', TRUE, 'voided_reason', NEW.voided_reason)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_log_expense_void
  AFTER UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION log_expense_void();
```

### 6.2 Batch Status Change Trigger

```sql
CREATE OR REPLACE FUNCTION log_batch_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status != OLD.status THEN
    INSERT INTO audit_logs (table_name, record_id, action, performed_by, old_values, new_values)
    VALUES (
      'product_batches', OLD.id, 'UPDATE',
      auth.uid(),
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_log_batch_status
  AFTER UPDATE ON product_batches
  FOR EACH ROW EXECUTE FUNCTION log_batch_status_change();
```

---

## 7. Profile Claim Flow Security

The profile claim is security-sensitive because it links an auth user to an existing partner record.

**Security constraints:**
1. Claim only works when `is_claimed = FALSE` — cannot steal a claimed profile.
2. Claim only works when the signup phone **exactly matches** `business_partners.phone`.
3. The claim trigger runs as `SECURITY DEFINER` — user cannot directly write to `business_partners.user_id`.
4. After claim, the claiming user does NOT automatically become an editor — their `access_level` remains whatever the owner set (default: `viewer`).
5. The inviting owner receives no notification (V1) — they can see `is_claimed = TRUE` on the partner list.

---

## 8. Pre-Launch Security Checklist

```
Authentication
□ Phone OTP enabled in Supabase dashboard
□ OTP expiry set to 5 minutes
□ Rate limiting configured for OTP (5/hour per phone)
□ Email confirmations disabled (phone-only flow)

Database
□ RLS enabled on ALL tables (verify with: SELECT tablename FROM pg_tables WHERE schemaname='public')
□ All helper functions (my_business_id, i_am_owner, i_am_editor) created
□ All RLS policies applied and tested
□ audit_logs table has no DELETE policy
□ batch_code generation trigger installed
□ profile_claim trigger installed on auth.users
□ No table allows direct user-facing DELETE (soft delete only)

Flutter
□ No service role key in Flutter code
□ SUPABASE_URL and SUPABASE_ANON_KEY passed via --dart-define (not hardcoded)
□ No financial data or tokens logged in production
□ Input validation on all forms before Supabase calls
□ Connectivity check before all write operations

Supabase
□ Supabase project NOT in "public schema" anonymous mode
□ Storage bucket 'receipts' set to private (authenticated access only)
□ Supabase Realtime enabled only on required tables
□ Database backups enabled (Point-in-time recovery)
□ Project region chosen close to Pakistan users (AWS Mumbai or Bahrain)

Data
□ Bank account numbers stored as last 4 digits only
□ CNIC encrypted at rest (if collected)
□ Soft delete implemented — no hard deletes in app
```
