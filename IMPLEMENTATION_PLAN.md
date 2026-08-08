# Implementation Plan — Green Market V2.0 (Standalone Flutter + Supabase)

**Source of truth (updated requirements):** `green_market/01_PRD.md`, `02_Technical_Architecture.md`, `03_Security_Access.md`, `04_Frontend_Specification.md`
**Date:** 2026-08-08
**Status:** Plan — awaiting confirmation of Decision Points (§3) before Phase 0 execution.

---

## 1. Why This Plan Exists

The current app talks to a local **FastAPI backend** via Dio (Riverpod + go_router). The v2.0 requirements replace that with a **standalone Flutter + Supabase** architecture: no custom backend, PostgREST + Row Level Security, phone-OTP auth, P&L via PostgreSQL RPC functions, Realtime subscriptions, and a specified UI (Provider + ChangeNotifier, `Navigator.push`, 5-tab bottom nav). This plan migrates the existing codebase to that spec instead of building from scratch — reusing the ~135 files that still match (models, widgets, screens) and replacing the transport + state layers.

## 2. Target Architecture

```
Flutter (Android primary / iOS secondary / Web bonus)
  Screens (Navigator.push, no go_router)
    → ChangeNotifier providers (one per domain)
      → Repositories (Supabase queries)
        → supabase_flutter client + .rpc() for P&L engine
          → Supabase: PostgreSQL + RLS + Auth(OTP/email) + Realtime + Storage(receipts)
Local view cache: SharedPreferences (dashboard only). Writes require connectivity.
```

Non-negotiables from the spec:
- **No custom backend.** All CRUD via Supabase PostgREST; complex math only via `supabase.rpc()`.
- **RLS is the authorization layer.** The client bundles the anon key; UI hides actions by role, RLS is the real gate.
- **Soft delete only** (void expenses with reason; never hard-delete customers/partners/batches).

## 3. Decision Points (confirm before coding)

| # | Decision | Spec says | Recommendation |
|---|----------|-----------|----------------|
| D1 | State management | Provider 6.x + ChangeNotifier | **Migrate Riverpod → Provider.** Affects every provider file. Keep the current per-feature StateNotifier *shape* but as `ChangeNotifier`s. |
| D2 | Navigation | Flutter Navigator 1.0, "no go_router" | **Replace go_router with `Navigator.push`.** Delete `routes.dart`; introduce `AuthWrapper` + `MainShell`. |
| D3 | Session storage | Supabase SDK-managed (SharedPreferences) | **Drop `flutter_secure_storage`** for auth; `supabase_flutter` handles tokens internally. Remove `AuthInterceptor`/refresh logic. |
| D4 | Env config | `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) | **Remove `flutter_dotenv`**; use compile-time defines (keep `.env` fallback only if still desired for local dev). |
| D5 | Supabase SQL location | standalone app owns its schema | **Add `supabase/migrations/` inside `green_market/`** (this repo) with the DDL from `02`/`03`. |

If the user prefers to keep Riverpod + go_router, D1/D2 are skippable — all other phases are unchanged.

## 4. Dependency Changes (`pubspec.yaml`)

**Add:**
- `supabase_flutter: ^2.5.0` — client, auth (OTP/email), realtime, storage
- `provider: ^6.1.0` — state (replaces `flutter_riverpod`)
- `shared_preferences: ^2.3.0` — dashboard cache (replaces `flutter_secure_storage` for session)
- `pdf: ^3.11.0` + `printing: ^5.13.0` — batch P&L export
- `flutter_slidable: ^3.1.0` — swipe-to-void expenses
- `cached_network_image: ^3.3.0` — receipt/avatar images
- `equatable: ^2.0.5` — model equality (optional)

**Remove:** `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `flutter_dotenv`, `connectivity_plus` (Supabase errors + a thin check suffice; keep only if the offline banner needs it — see §14).

**Keep:** `intl`, `fl_chart`, `shimmer`, `google_fonts` (spec fonts are Poppins/Inter/RobotoMono — decide: bundle via google_fonts or add font assets).

## 5. Supabase Project Setup (prerequisite infra)

Create from `02` §5–6 and `03` §3. Deliver as `green_market/supabase/migrations/`:

1. **Tables (14):** `user_profiles`, `businesses`, `business_partners`, `markets`, `products`, `product_batches`, `batch_partners`, `packing_records`, `expenses`, `customers`, `sales`, `customer_payments`, `partner_transactions`, `audit_logs` — exact DDL in `02` §5.
2. **Helper SQL functions:** `my_business_id()`, `i_am_owner()`, `i_am_editor()` (`03` §3.1).
3. **RLS:** enable on every table; apply policies from `03` §3.2–3.14 verbatim.
4. **Triggers:** `generate_batch_code()` (batch code `GM-YYYY-NNNN`, `02` §5.6), `handle_new_user_claim()` (phone claim, `03` §1.5), `log_expense_void()` + `log_batch_status_change()` (audit, `03` §6).
5. **RPC functions:** `get_batch_pl(batch_id)` → JSONB, `get_business_pl_summary(business_id, from, to)` → JSONB, `get_customer_balance(customer_id)` → NUMERIC (`02` §6).
6. **Realtime:** enable on `sales`, `expenses`, `customer_payments` (`02` §8).
7. **Storage bucket:** `receipts` (private, authenticated).
8. **Auth:** enable Phone provider (OTP: 6-digit, 5-min expiry, 5/hour rate limit), email+password secondary.

## 6. Flutter App Restructure

Adopt the spec layout (`02` §3.1) while minimizing churn. Suggested mapping:

```
lib/
  main.dart                 → Supabase.initialize + MultiProvider + GreenMarketApp
  app.dart                  → NEW: MaterialApp + AuthWrapper
  core/
    constants/              → NEW: app_colors, app_text_styles, app_strings (from 04 §1)
    utils/                  → keep currency_formatter, date_formatter, validators (extend w/ PK phone, amount)
    widgets/                → keep shared widgets (GreenCard, AmountText, StatusPill, PartnerChip, LoadingOverlay, EmptyState, ConfirmDialog)
  models/                   → flat folder (merge data/models + domain/entities); see §7
  repositories/             → keep current *_repository.dart files, re-implement bodies with Supabase
  providers/                → convert StateNotifier → ChangeNotifier
  screens/                  → move + rename presentation/pages/** per spec names (see §9)
  supabase/                 → NEW: client init helpers, rpc wrappers (if not in repositories)
```

## 7. Data Layer Migration

### Models
Reuse current `data/models/*.dart` where the shape matches; **extend/align to new schema**:
- `product_batches`: add `batch_code`, `source_market_id`, `destination_market_id`, `transport_amount/paid_by/mode`, `status` enum, `notes`, `created_by`.
- `batch_partners`: add `role` (`purchaser|seller|both`), `daily_charge_rate`, `days_involved`.
- `expenses`: add `expense_side` (`purchaser|transport|seller`), `expense_type` enum, `paid_by`, `payment_mode`, `bank_reference`, `is_voided`/`voided_by`/`voided_reason`, `created_by`.
- `sales`: add `seller_id`, `payment_mode` (`cash|credit|partial`), `cash_received`, `credit_amount`, `bank_reference`, constraint `cash+credit = qty×price`.
- NEW: `customer_payment`, `partner_transaction`, `packing_record` (existing `packing_record_model.dart` — align to `unit_count × cost_per_unit`), `business_partner`, `user_profile` merge.
- JSON keys are **snake_case** (already the convention).

### Repositories
Keep one repository per domain (`auth`, `batch`, `expense`, `sale`, `customer`, `partner`, `market`, `product`, `report`/`pl`), re-implement bodies:
- Replace `ApiClient`/Dio calls with `Supabase.instance.client.from(...).select()/insert()/update()`.
- P&L calls → `supabase.rpc('get_batch_pl', params: {'p_batch_id': id})` (results already snake_case; model `fromJson` unchanged).
- **Delete the remote-datasource layer** (`data/datasources/remote/*_ds.dart`) — PostgREST is the datasource; repositories call the client directly (matches spec's flat `repositories/` folder).
- Remove `core/network/` (api_client, interceptors) and the Drift `AppDatabase` stub.
- Keep `SyncRepository` only if replaced by the SharedPreferences cache; the spec's offline model is **read-cache, write-requires-connectivity** (§14) — not a queue.

## 8. Auth & Onboarding (`screens/auth/`)

- `SplashScreen` → check `Supabase.instance.client.auth.currentSession`, route to Login/Onboarding/MainShell (spec §4.2).
- `LoginScreen` → phone field with `+92` prefix; **"Send OTP Code"** = `signInWithOtp(phone:)`; **"Use Email Instead"** toggles email+password form (`signInWithPassword`).
- `OTPVerifyScreen` (NEW) → 6 auto-advancing digit boxes, 60s resend countdown, auto-submit; `verifyOTP(phone:token:)`. Phone signup auto-creates the user; the claim trigger (`03` §1.5) links unclaimed profiles.
- `OnboardingScreen` → create business: business name, your name, role (both/purchaser/seller), city. Inserts `businesses` (owner) + `business_partners` (self, editor, claimed).
- `AuthProvider` → ChangeNotifier wrapping `supabase.auth.onAuthStateChange`; expose session, profile, `isOnboarded`; `signOut()` on logout.
- Remove OTP-less email signup page & business-id-from-storage logic (session state comes from Supabase).

## 9. Navigation & Shell

- **Delete** `core/config/routes.dart` + `go_router`. Keep `DashboardShell` concept but rebuild as spec `MainShell` (`02` §4.3): `IndexedStack` + 5-tab `BottomNavigationBar` — Home, Batches, Sales, Customers, **More** (new 5th tab).
- `AuthWrapper` decides top-level screen from auth state (spec §4.2).
- All screens navigate with `Navigator.push(MaterialPageRoute(...))`; login/logout use `pushAndRemoveUntil`.
- **CreateBatchScreen** = single screen, 5-step `PageView` (spec §4.4, steps in `04` §6.2) — replaces current wizard routing.
- **BatchDetailScreen** = 5-tab `DefaultTabController`: Overview | Expenses | Packing | Sales | P&L (spec §4.5, `04` §6.3).

## 10. Feature Screens (per `04`)

| Area | Build / Convert | Key spec points |
|------|-----------------|-----------------|
| Dashboard | Rework `dashboard_page.dart` | 2×2 summary cards (Today's Sales, Active Batches, Credit Pending, P&L this month), Quick Actions grid (+ New Batch / + New Sale / Record Payment / Reports), Active batches top-5, Credit alerts; scope by partner (`FR-D`) |
| Batch list | Rework `batch_list_page.dart` | status filter dropdown, card shows batch code + status pill + route + cost (`04` §6.1) |
| Create batch | NEW 5-step wizard | Product+market+qty+price → partners (daily rate×days, seller, transport) → packing → purchaser expenses → review cost summary |
| Batch detail | Rework `batch_detail_page.dart` | 5 tabs; Overview shows qty sold progress + "Mark as Closed"; Expenses grouped Purchaser/Transport/Seller w/ subtotals + swipe-to-void (owner); Packing list + add; Sales running totals; P&L from RPC + Export PDF |
| Sales | Rework list + `quick_sale_page.dart` | filterable list; SaleEntry picks **only `selling` batches**, customer search/walk-in, qty ≤ remaining, payment mode cash/credit/partial, credit auto-fill |
| Customers | Rework list/ledger/payment | search, color-coded outstanding (green/amber/red, threshold PKR 50k), ledger w/ running balance, record payment w/ live new-balance preview |
| More menu | NEW `MoreScreen` | My Profile, Partners, Markets & Cities, Reports, Settings, Sign Out |
| Partners | Rework list/create/profile | claimed/unclaimed badge, owner changes access level, partner detail shows batches + balance-with-me + Record Settlement |
| Markets | Rework list/create | grouped by city, market type wholesale/retail/both; owner manages |
| Reports | Rework reports hub | date range, business summary (via `get_business_pl_summary`), credit outstanding, revenue-vs-cost bar chart (fl_chart), Export PDF |
| Settings | Rework | business settings (credit threshold), access management, profile, sign out |
| Transactions | Fold into partner flows | `partner_transactions` table; settlement screen + partner balance (transport-debt auto records) |

## 11. P&L Engine & PDF Export

- `PLRepository`: `getBatchPL(batchId)` → `rpc('get_batch_pl')`; `getBusinessPL(from,to)` → `rpc('get_business_pl_summary')`; `getCustomerBalance(id)` → `rpc('get_customer_balance')`.
- Models: keep `report_model.dart` PLSummary shapes; align JSON keys to RPC output (`purchase_cost`, `purchaser_expenses`, `transport_cost`, `seller_expenses`, `packing_cost`, `total_cost`, `total_revenue`, `cash_received`, `credit_outstanding`, `profit_loss`, `qty_total`, `qty_sold`, `qty_remaining`).
- Batch P&L screen: label **"in progress"** when `status != closed`; show expected-on-full-sale estimate.
- PDF: `printing` share sheet rendering a summary (batch code, cost chain lines, revenue split, net P&L).

## 12. Realtime

Per `02` §8, subscribe on the batch detail tabs and customer ledger:
- `sales_batch_{id}` → INSERT → reload sales
- `expenses_batch_{id}` → INSERT/UPDATE → reload expenses
- `customer_payments_{customer_id}` → INSERT → reload ledger
Dispose channels on tab dispose. (Required only where partners collaborate; no push notifications in V1.)

## 13. Role-Based UI Gating

`AuthProvider` exposes the user's `business_partner` record (`role`, `access_level`, `is_claimed`). Helper `can(Capability)` gates buttons:
- Create batch / markets / partners / change access / void expense → owner (or editor per matrix in `03` §2.2).
- Add expense → owner, editor (own batches), accountant.
- Record sale → owner, or editor with `seller|both` on that batch, and only when `status == selling`.
- P&L view → all roles (own-batch scope for non-owner non-accountant).
UI is a convenience layer; **RLS remains the enforcement point** (never trust client-only gating).

## 14. Offline & Cache

Per `02` §9 + `04` §12:
- **Read path:** dashboard (and optionally lists) cached to `SharedPreferences`; on fetch failure show cached data + orange "No internet — showing cached data" banner.
- **Write path:** connectivity check first; on failure show error snackbar with Retry — **no silent offline queue**.
- Loading: `Shimmer` skeleton tiles on every list screen. Empty states per `04` §12 table.

## 15. Milestones & Acceptance Criteria

**Phase 0 — Foundation (D1–D5 confirmed)**
Supabase project + migrations/RLS/RPC/triggers installed; `supabase_flutter` init; `pubspec` deps swapped; `app.dart` + `AuthWrapper` skeleton runs. ✅ `flutter analyze` clean.

**Phase 1 — Data layer**
All repositories converted to Supabase; models aligned to schema; remote-datasource layer deleted. ✅ Existing screens still compile against a mocked/empty dataset.

**Phase 2 — Auth**
Phone OTP + email flows, OTP screen, onboarding creates business, profile claim link, session persistence + logout. ✅ Login→Onboarding→MainShell walkthrough on a test Supabase project.

**Phase 3 — Shell & navigation**
go_router removed; 5-tab `MainShell` with IndexedStack; screens navigate via `Navigator.push`. ✅ All existing entry points reachable; bottom nav preserves scroll.

**Phase 4 — Core flows**
Dashboard, batch list, 5-step wizard, batch detail 5 tabs, quick sale, customer ledger + payment. ✅ Walkthroughs for spec §11 Flows 1–5.

**Phase 5 — Partners, markets, reports**
More menu, partners (claim/access), markets, reports + bar chart, settings. ✅ Owner vs partner vs accountant UI gating verified; RLS policies smoke-tested with a non-owner account.

**Phase 6 — P&L RPC, PDF, realtime, offline**
RPC P&L wired into tabs; PDF export shares; realtime channels live-update; SharedPreferences cache + offline banner; error/empty/loading states. ✅ End-to-end two-partner demo: sale by one partner appears on the other without refresh.

**Phase 7 — Hardening**
Role-matrix audit vs `03` §2.2; input validation (`validators.dart`); production logging policy; responsive check (mobile-first, web bonus); `flutter test` for models/validators/repositories (fake Supabase client).

## 16. Verification & Tooling

- `flutter analyze` must stay clean (currently 3 info lints).
- Tests: expand beyond `widget_test.dart` — unit-test models (`fromJson` on RPC payloads), validators (PK phone, amounts, remaining-qty rule), repositories with a mocked `SupabaseClient`.
- Dev run: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` (project URL/key kept out of git).
- Supabase local emulator can back Phases 1–6 before a cloud project is provisioned.

## 17. Risks & Open Questions

1. **Scope of rewrite:** D1/D2 (Provider + Navigator) touch every provider and page — biggest cost driver. Confirm early.
2. **Backend repo:** the old FastAPI repo (`../backend/`) is out of scope per AGENTS.md and becomes unused by this app once Phase 1 lands — flagging so nothing depends on it.
3. **SMS provider:** Supabase phone OTP needs a real SMS provider (Twilio/Vonage) configured; otherwise email+password is the testable path.
4. **`MISSING_FEATURES.md` and the old `Frontend_Implementation_Plan.md`** (GreenMarket root) are superseded by this plan + `project_state.md`; they describe the FastAPI-era app.
5. **Currency locale:** `01` §7 wants `1,23,456` (Pakistani grouping) — verify `NumberFormat('#,##,##0')` support in current formatter; update `currency_formatter.dart` if needed.
