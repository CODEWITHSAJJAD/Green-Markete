# Green Market — Multi-User Role-Based Access Control (RBAC) Plan

**Status:** PLANNED — not yet implemented. This document is the audit record + roadmap for turning Green Market from a single-user-per-business app into a true **multi-user, per-business role-based** system. Implementation starts only after this plan is accepted; each phase below gets its own commit and a `project_state.md` entry.

**Repo:** `C:\Users\SUQOON\Downloads\frontend\green_market\`
**Related docs:** `03_Security_Access.md` (current single-business RLS + role matrix), `OPERATIONS_FEATURES_PLAN.md` (requirements map), `project_state.md` (session log).

---

## 1. Goal (in the user's own words, normalized)

- A person creates **their account**, then **creates a business**, then **adds a partner** (name + **phone** + role) and gives the partner an access level (e.g. **viewer**).
- The partner then **signs up with the same phone**. After signup they see **that business in their own business list**, with **their role**, and can **work inside it**.
- The same applies to **accountants** and every other role — anyone added as a partner/employee to a business appears in their app under that business.
- **Side-scoped permissions (the core requirement):** a partner can *edit their own side* but only *view the other side*.
  - Example: owner = **seller**, partner = **purchaser**. When the purchaser logs in they can create **purchases and purchaser-side entries** (purchaser expenses, transport, packing, purchase payments), but they **cannot create sales or seller-side expenses** — until the owner **changes their permissions**.
  - Roles are **business-scoped**: the same phone/user may be a purchaser in business A, an accountant in business B, and a seller in business C, each with its own access level.

## 2. Current state (verified against the code on 2026-08-14)

### 2.1 What already exists

| Item | Location | Notes |
|------|----------|-------|
| Email+password AND phone-OTP auth | `auth_repository.dart`, `auth_provider.dart` | OTP flow calls `claimBusinessByPhone` on verify |
| Business list + switcher | `auth_provider.dart:34` (`loadBusinesses`), `business_switcher_page.dart` | Shows all businesses where `business_partners.user_id = me`; no role badge |
| Onboarding / business creation | `BusinessRepository.create` | Inserts `businesses` + owner row into `business_partners` (`role`='owner', `access_level`='owner', `is_claimed`=true) |
| Phone → partner claim | `auth_repository.dart:157` `claimBusinessByPhone` | **Claims only ONE** unclaimed `business_partners` row (`maybeSingle`) |
| Single role string | `auth_repository.dart:98` `getMyRole` | Maps `access_level`/`role` → `owner` \| `editor` \| `viewer` \| `accountant` |
| Role-based capability check | `capability.dart` `CapabilityService` | **Owner** all; **Editor** most writes; **Viewer/Accountant** read-only (`isReadOnlyRole`) |
| Partner CRUD + `updateAccess` | `partner_repository.dart`, `partner_provider.dart:72` | Owner changes a partner's access level |
| Side data model (exists in DATA, not in permissions) | `batch_partners.role` (purchaser/seller/both), `expenses.expense_side`, `batch.transportPaidBy`, `get_batch_pl` purchaser/seller breakdowns | The system already knows *which side a partner works on* per batch — but nothing enforces side permissions |
| RLS + role matrix doc | `03_Security_Access.md` | Assumes **one business per user** |

### 2.2 Gaps this plan closes

1. **Claim is single-row.** A partner added to several businesses, or to a second business later, is not linked to all of them. Also, adding a partner whose phone already has a registered account does not link them at creation time.
2. **Session picks only the first business.** `restoreSession` → `getMyBusinessId` uses `maybeSingle` (`auth_repository.dart:88`). Second+ memberships are invisible at login.
3. **Role goes stale on switch.** `AuthProvider.switchBusiness` (and `setBusinessId`) copies the *current* `role` onto the new business (`auth_provider.dart:46-61, 213-228`) — switching to a business where the user is a viewer keeps the previous role.
4. **No side-awareness in permissions.** `CapabilityService` is a flat role string. Any editor can record sales, add seller expenses, create purchases, etc. — the "own side = edit, other side = view" rule does not exist.
5. **Accountant semantics conflict.** `capability.dart` treats accountant as read-only; `03_Security_Access.md` §2.2 lets accountants add expenses. Needs one source of truth.
6. **No `access_level` in the partner form.** `create_partner_page.dart` only sets `role` (purchaser/seller/both/accountant/partner); the owner cannot pick viewer/editor there. Access changes happen later via `updateAccess`.
7. **RLS is single-business.** `my_business_id()` returns `LIMIT 1` (`03_Security_Access.md` §3.1). Multi-business must scope by "any business I belong to" + active-business filtering, and write-policies must check access_level per business.

## 3. Target model

### 3.1 Definitions (single source of truth)

- **User** — an auth account (`auth.users` + `user_profiles`), identified by `user_id`. One user = one phone.
- **Business** — a company/operation. Owned by exactly one user (`businesses.owner_id`).
- **Membership** — a row in `business_partners` linking `user_id` → `business_id`. A user has **one membership row per business**.
- **access_level** — overall write privilege inside a business: `owner` \| `editor` \| `viewer`.
- **side role (role)** — which half of the operation the partner works: `purchaser` \| `seller` \| `both` \| `accountant`.
- **side** — a per-batch concept: `purchaser` side (purchases, packing, transport, purchaser expenses, purchase payments) vs `seller` side (sales, seller expenses, settlements, customer payments). `both` covers both sides.

### 3.2 The membership & claim flow (target)

1. **Owner creates business** → owner membership row (`role`='owner', `access_level`='owner', `is_claimed`=true, `user_id`=owner).
2. **Owner adds a partner** → `business_partners` row with `full_name`, `phone`, `role`, `access_level` (**default `viewer`**), `user_id` = NULL, `is_claimed` = false.
   - If a `user_profiles` row already exists with the same phone → link immediately (`user_id` set at creation).
3. **Partner signs up with the same phone** (OTP or email) → system **claims ALL unclaimed** `business_partners` rows with that phone (one or many businesses) → sets `user_id` = the new auth id, `is_claimed` = true, `joined_at` = now. Security: claim only matches rows where `phone` matches **exactly** and `is_claimed` = false; the user never writes `user_id` directly (done by a security-definer RPC).
4. **On login**, the app loads **all memberships** (not just the first), and the user picks which business to open (persisted last-active selection). Each membership carries its own `access_level` + `role`.

### 3.3 Effective capability matrix (side-scoped)

Rules:
- **Owner** — everything, both sides, all domains.
- **Editor, side = purchaser / seller / both** — full write on **own side** domains; **read-only** on the other side.
- **Viewer, side = purchaser / seller / both** — same own-side domain writes as editor (per user's requirement "his side he has editor access") **but cannot do cross-cutting writes** (create batches, change status, close, void, partner management, settlements with the owner).
- **Accountant** — read all + record expenses (see §7 open decision D5). No side.
- **Cross-side write** is only possible when the owner **changes the partner's permissions** (raise access_level, or set role = `both`, or enable a per-partner cross-side grant — see §4 backend item B4).

| Domain (side) | Owner | Editor (purchaser) | Editor (seller) | Viewer (purchaser) | Viewer (seller) | Accountant |
|---|---|---|---|---|---|---|
| Create / edit / close batch | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Purchases (add, pay supplier) — purchaser | ✅ | ✅ | 👁 | ✅ | 👁 | 👁 |
| Purchaser expenses / transport / packing — purchaser | ✅ | ✅ | 👁 | ✅ | 👁 | 👁 (record-only, see D5) |
| Sales — seller | ✅ | 👁 | ✅ | 👁 | ✅ | 👁 |
| Seller expenses — seller | ✅ | 👁 | ✅ | 👁 | ✅ | 👁 (record-only, see D5) |
| Customer payments / credit collect — seller | ✅ | 👁 | ✅ | 👁 | ✅ | 👁 |
| Settlements (partner transactions) — seller | ✅ | 👁 | ✅ | ❌ | ❌ (owner-settles; see D6) | 👁 |
| Reports / P&L (read) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ all |
| Partner management (add / change permissions) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Business settings / currency / audit logs | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

`✅` write, `👁` read-only, `❌` hidden. Open decisions that may shift cells are flagged as D4/D5/D6 in §7.

## 4. Backend prerequisites (for the backend repo — not this repo)

> **Status (daily-94):** drafted as `supabase/migrations/25_multi_business_rls.sql` in THIS repo for review. It is **additive-only** (never drops/weakens an existing policy; OR-combined SELECT widening only; B4 column; B2/B5 triggers swallow errors), so applying it cannot produce RLS/42501 regressions. Apply via the SQL editor when ready; the frontend works without it.

Applied to the backend/Supabase side; listed here so the frontend plan is complete. The frontend must keep working **before** these land (defensive pattern: if a column/RPC is absent, degrade).

- **B1 — Claim all by phone.** Replace/extend the signup hook so an unclaimed `business_partners` row is claimed for **every** business matching the signup phone. Security-definer; exact phone match; guarded by `is_claimed = FALSE`.
- **B2 — Link existing users.** RPC or trigger: when a partner is created and `user_profiles.phone` already exists, set `user_id` + `is_claimed = TRUE` at creation.
- **B3 — Multi-business RLS.** Replace single-business helpers:
  - `my_business_ids()` (set-returning: all `business_id` where `user_id = auth.uid()`) for SELECT policies,
  - `i_am_owner_for(biz_id)`, `access_level_for(biz_id)`, `side_role_for(biz_id)` parameterized helpers for write policies.
  - SELECT stays "any business I belong to" (active-business scoping is app-side filtering — matches current repo behaviour). Write policies additionally require the right access_level/side role.
  - Keep the migration-22 pattern (`businesses_select` must allow `owner_id = auth.uid()` and `business_partners` its own first row so RETURNING works on creation).
- **B4 — Per-partner cross-side grant.** `business_partners.manage_other_side boolean default false` (owner-set). When true, the partner's editor/viewer writes extend to the other side too. (Cheapest way to implement "owner changed his permissions".)
- **B5 — Audit.** `audit_logs` entries on access_level / role / manage_other_side changes (trigger or app-recorded via an RPC).

## 5. Frontend implementation phases

Each phase: code → `flutter analyze` (3 baseline info lints) + `flutter test` green → commit → `project_state.md` entry.

### P1 — Membership & claim (foundation)
- `AuthRepository`:
  - `claimBusinessByPhone` → claim **all** unclaimed rows for the phone (loop or a single RPC if B1 exists; otherwise keep row-by-row via anon+RLS).
  - New `listMyMemberships(userId)` → all `business_partners` rows for the user (`business_id, role, access_level, is_claimed`).
- `AuthProvider.restoreSession`:
  - Load memberships; `_businesses` from memberships (drop the `maybeSingle` first-business logic).
  - Active business = persisted last-active id (SharedPreferences) if still a membership, else the first; `_needsOnboarding` = no memberships at all.
  - Populate `role`/`accessLevel`/`sideRole` from the **active membership** (not the profile).
- Onboarding (`completeOnboarding`, OTP verify): after profile create, run claim (all rows) so the partner immediately sees invited businesses.
- New model `MembershipModel { businessId, role, accessLevel, isClaimed, businessName }`.

### P2 — Role per business + switcher
- Fix `switchBusiness` / `setBusinessId` (`auth_provider.dart:46,213`) to re-derive `role`+`accessLevel`+`sideRole` from the target membership and persist the new last-active id.
- `business_switcher_page.dart`: show a role/access badge per business card (e.g. "Editor · Purchaser", "Viewer · Seller", "Owner"), plus a "claimed" hint. Refreshes after claim.
- Settings/onboarding: surface "Businesses I was added to" distinctly from "Businesses I own".

### P3 — Capability matrix + UI gating (the core)
- Rework `capability.dart`:
  - `CapabilityService(accessLevel, sideRole, {manageOtherSide})`.
  - New domain caps: `recordPurchase`, `addPurchaserExpense`, `addSellerExpense`, `addPacking`, `manageTransport`, `recordSale`, `recordCustomerPayment`, `createSettlement`, `createBatch`, `manageAccess`.
  - Side resolver: `bool canEditSide(String side)` — own-side rule per §3.3.
  - Keep the existing `canEditBatch`/`canVoidExpense` extension API so call sites don't churn, reimplemented on top.
- Gate the UI (hide/disable, never just hard-fail):
  - `batch_detail_page.dart`: Expenses tab — filter the **expense side** dropdown to sides the user may write; hide FABs for sales on non-seller sides; Transport/Packing add buttons per side; Settlements tab write actions for seller-side/owner only.
  - `batch_list_page.dart` / wizard entry: only `canCreateBatch`.
  - Quick sale, customer payments, purchase entry: per matrix.
  - Reports: read-only everywhere (already mostly true).
- `capability.dart` `isReadOnlyRole` updated to the new model (accountant decision per D5).

### P4 — Partner management UI (owner)
- `create_partner_page.dart`: add **access level** selector (Viewer / Editor) next to the role dropdown; default Viewer; optional "Can edit the other side" switch (B4) shown only when role ≠ `both`; if B2 exists, creation links existing users automatically.
- `partner_list_page.dart`: columns/badges for role, access level, claimed status; owner actions: change access level, toggle cross-side grant, resend/claim status.
- Owner-only actions already gated by `canManageAccess`.

### P5 — Backend alignment + end-to-end test
- Apply B1–B5 in the backend repo (separate PR); verify frontend degrades cleanly before they land.
- Test script (manual, phone OTP on a second device): owner creates business → adds partner (viewer, purchaser) → partner signs up with same phone → sees business + role → can add purchases/purchaser expenses → **cannot** record a sale or seller expense → owner raises access or enables cross-side → partner can now.
- Confirm `flutter analyze` clean + `flutter test` green after each phase.

## 6. Acceptance criteria (user-visible)

1. Adding a partner by phone makes that business appear in the partner's app **after they sign up with the same phone** — no owner-side magic required.
2. On login, the partner sees **all businesses** they belong to, each with its role.
3. Purchaser partner: purchases, purchaser expenses, packing, transport, purchase payments are available; **sales, seller expenses and customer-payment actions are not** (until the owner grants them).
4. Seller partner: the mirror image.
5. Roles are per business: the same login shows a different role in a different business.
6. Owner can change any partner's access level / cross-side permission and it takes effect immediately.
7. `flutter analyze` clean, `flutter test` green, one commit + `project_state.md` note per phase.

## 7. Open decisions to confirm before/during implementation

- **D1.** Viewer semantics — this plan takes the user's statement literally: *viewer still writes on their own side*, just no cross-cutting writes. Confirm the exact viewer/editor split for own-side domains.
- **D2.** Who creates the batch — currently owner/editor. With side roles, keep "owner or editor creates the batch and assigns partner sides" (recommended), or let a purchaser create it too.
- **D3.** Cross-side grant mechanism — simple `manage_other_side` boolean (recommended) vs a richer per-domain permission set.
- **D4.** Settlements — should seller-side **viewer** partners be able to record settlements (see matrix) or owner/editor only.
- **D5.** Accountant — read-only, or can also record expenses (current doc §2.2 says yes, current code says no). Pick one.
- **D6.** `partner` role value (old default in the create form) — fold into `both` or keep as a side-less legacy value.

## 8. Risks & notes

- **RLS ordering risk:** multi-business RLS must keep the migration-22 RETURNING fix semantics or business creation breaks again (42501). Do not "simplify" `businesses_select` to `id = my_business_id()`.
- **Claim security:** phone claim must never overwrite an already-claimed row and must be exact-phone; ownership stays with the business owner.
- **Stale roles:** the switchBusiness bug is the #1 source of "wrong permissions" bugs — P2 fixes it before P3 ships gating.
- **Backend-out-of-scope rule:** everything in §4 is a prerequisite note for the backend repo; the frontend must never hard-fail on their absence.
- **Audit:** every permission change should land in `audit_logs` (B5) so the role history is inspectable — the user explicitly wants this documented for audit purposes.
