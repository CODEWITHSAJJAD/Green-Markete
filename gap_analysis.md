# Green Market — Frontend Gap Analysis

**Repo:** `C:\Users\SUQOON\OneDrive\Desktop\GreenMarket\frontend\green_market\` (Flutter 3.44.8 / Dart ^3.12.0, `provider` 6.x + `supabase_flutter` 2.16)
**Branch:** `master`
**Status:** V2.0 Supabase migration executed; live schema on `hvtgzyucgymuixfbdece`. `flutter analyze` clean, `flutter test` passes.

---

## Methodology

**Docs consulted:** `green_market/01_PRD.md`, `green_market/02_Technical_Architecture.md`, `green_market/03_Security_Access.md`, `green_market/04_Frontend_Specification.md`, `green_market/IMPLEMENTATION_PLAN.md`, plus `frontend/project_state.md` and `frontend/AGENTS.md`. `MISSING_FEATURES.md` was deliberately skipped — the project_state notes it as stale (June 2026).

**Code cross-referenced:** `lib/main.dart`, the 11 feature folders under `lib/presentation/pages/`, all 14 `lib/presentation/providers/*.dart`, 13 `lib/data/repositories/*.dart`, 14 `lib/data/models/*.dart`, the 27 widgets in `lib/presentation/widgets/`, and the shared `lib/core/{config,supabase,utils}/*`. Targeted greps confirmed the absence of real-time channels, connectivity, l10n, bulk ops, profile photos, multi-currency, storage, audit-log UI, and CSV/PDF export.

**Approach:** For each requirement area I (1) read the spec section, (2) looked for the implementing class/page/widget in code, (3) confirmed presence/absence via direct reads or repo-wide regex, and (4) graded against what the requirements explicitly demand. Where a feature is partially built (e.g., partner profile renders ledger but transport-debt auto-creation is not wired), the gap entry calls out what is and isn't done.

---

## Implemented Features (confirmed)

- **Splash + branded landing** — `presentation/pages/auth/splash_page.dart` (gradient leaf mark + thin progress bar; auth state restore runs while it shows).
- **Login (email + password)** — `presentation/pages/auth/login_page.dart` calling `AuthProvider.login()` → `AuthRepository.signInWithEmail()`.
- **Signup** — `presentation/pages/auth/signup_page.dart` creating auth user + `user_profiles` row.
- **Onboarding (create business)** — `presentation/pages/auth/onboarding_page.dart` + `BusinessRepository.create()` which inserts `businesses` (owner) and the owner's `business_partners` row in one go.
- **Auth state restore** — `AuthProvider.restoreSession()` (`presentation/providers/auth_provider.dart:63`) reads `currentSession`, fetches `user_profiles`, resolves `business_id` via `AuthRepository.getMyBusinessId()`. `AuthWrapper` in `main.dart:79` drives routing off `isLoading / isAuthenticated / needsOnboarding`.
- **Multi-business switching** — `AuthProvider.loadBusinesses()` / `switchBusiness()` (provider lines 34–61), `BusinessSwitcherPage` (settings/business_switcher_page.dart) listing the user's businesses with active state and "Add new business" dialog.
- **Editable profile & business settings** — `ProfilePage` calls `AuthProvider.updateProfile()` (line 222); `BusinessSettingsPage` edits `name` + `credit_alert_threshold` via `BusinessProvider.updateSettings()`.
- **5-tab MainShell with floating nav + sidebar drawer** — `presentation/pages/main_shell.dart`, `presentation/widgets/google_nav_bar.dart`, `presentation/widgets/sidebar_drawer.dart`. Drawer exposes Products/Partners/Markets/Reports/Transactions/Settings.
- **Dashboard** — `presentation/pages/dashboard/dashboard_page.dart` with hero revenue card, 4 `DashboardCard`s, quick-actions row, credit alerts, recent batches; shimmer + error + retry states; `DashboardProvider` + `DashboardRepository` aggregate today's sales, batch counts, outstanding credit, and recent 5 batches.
- **Batch list** — `batches/batch_list_page.dart` loads via `BatchListProvider.load()`; hero card + `StatusPill` + meta tiles.
- **5-step batch creation wizard** — `batches/create_batch_wizard.dart` (Step 1 product/markets/date/qty/price/transport, Step 2 `PartnerSelector`, Step 3 `PackingEntryForm`, Step 4 expenses, Step 5 review). Generates `GM-YYYY-XXXXXX` `batch_code` client-side and retries on 23505 (`BatchRepository._insertBatchWithRetry`).
- **Batch detail with 5 tabs** — `batches/batch_detail_page.dart` (Overview, Packing, Expenses, Sales, P&L) using `StatusTimeline`, `StatusPill`, expense grouping by `expense_side` with subtotals.
- **Status advance** — `BatchDetailProvider.updateStatus()` walks the `_statusFlow` (`purchased → packed → in_transit → delivered → selling → closed`).
- **Packing entry sheet (FAB on Packing tab)** — `batches/batch_detail_page.dart:548` (inline AlertDialog). Also a step in the wizard.
- **Expense entry bottom sheet (FAB on Expenses tab)** — `presentation/widgets/expense_entry_sheet.dart` writing to `expenses` via `ExpenseProvider.add()`.
- **Sale entry bottom sheet (FAB on Sales tab)** — `widgets/sale_entry_sheet.dart` writing to `sales` via `SaleProvider.add()`; cash/credit/partial-credit/bank-transfer modes supported; `chk_amounts` honored in payload.
- **Quick Sale page** — `sales/quick_sale_page.dart` with batch dropdown filtered to `status = 'selling'`.
- **Customer list + create + ledger + record payment** — `customers/customer_list_page.dart` (search, owner-only swipe-to-delete), `customers/create_customer_page.dart`, `customers/customer_ledger_page.dart` (chronological ledger with running balance from `sales` + `customer_payments`), `customers/record_payment_page.dart`.
- **Partner list + create + profile + access management** — `partners/partner_list_page.dart` (search, "Claimed"/"Pending" badges), `partners/create_partner_page.dart`, `partners/partner_profile_page.dart` (ledger snapshot, owner-only viewer/editor chips), `settings/access_management_page.dart` (dropdown with role icon/colour).
- **Markets list + create** — `markets/market_list_page.dart`, `markets/create_market_page.dart` (wholesale/retail/both type).
- **Products list + inline-create dialog** — `products/product_list_page.dart`.
- **Reports hub** — `reports/reports_page.dart` (P&L, Customer Credit, Overdue, Market Performance cards + embedded summary).
- **P&L report** — `reports/pl_report_page.dart` with `fl_chart` bar chart, date-range picker, recent batch summaries.
- **Customer credit report** — `reports/credit_report_page.dart` with city filter + sort.
- **Overdue customers** — `reports/overdue_customers_page.dart` with a threshold `Slider`.
- **Market performance** — `reports/market_performance_page.dart` consuming the `v_city_market_performance` view.
- **Partner P&L per batch** — `reports/partner_report_page.dart` driven by `get_partner_pl` RPC.
- **Transactions: settlements + partner ledger** — `transactions/transaction_list_page.dart`, `transactions/partner_settlement_page.dart`, `transactions/partner_balance_page.dart`.
- **Settings hub** — `settings/settings_page.dart` routing to Profile, Business Info, Switch / Add Business, Access Management, Notifications, Help Center, About, Sign Out.
- **Notifications preferences (local toggles)** — `settings/notification_settings_page.dart` persisting `credit_alerts / batch_alerts / expense_alerts / daily_digest` in `SharedPreferences`.
- **Help Center (FAQ)** — `settings/help_center_page.dart` with `ExpansionTile`s.
- **About page** — `settings/about_page.dart`.
- **Design system** — `core/config/theme.dart` (Material 3 light, `AppColors` with `creditLow / creditMid / creditHigh`, spacing/radius tokens, tinted shadows, custom component themes), Poppins/Inter via `google_fonts`, MingCute icons.
- **Shared widgets** — GreenCard, AmountText, StatusPill, PartnerChip, EmptyState, ConfirmDialog, DashboardCard, ErrorSnackbar, DatePickerField, StatusTimeline, BatchSummaryCard, RecentActivityList, SectionHeader, BrandMark, LoadingOverlay, PartnerSelector, PackingEntryForm, SaleEntrySheet, ExpenseEntrySheet, SearchableDropdown, CreditIndicator, StatBadge, CityMarketDropdown, SidebarDrawer, GoogleNavBar.
- **Validators utility** — `core/utils/validators.dart` with `email / password / phone (PK format) / amount / positiveNumber` rules (defined; integration into forms is partial — see gaps).
- **Live E2E smoke tested** — see `project_state.md` §7: 16 checks pass against the live Supabase project (auth, RLS boundary, CRUD, RPCs, triggers, audit log inserts).

---

## Gaps / Missing or Incomplete Features

### 1. Phone OTP authentication flow (UI + wiring)

- **Feature:** Phone OTP login + OTP verification screen.
- **Requirement:** `01_PRD.md` §5.1 FR-AUTH-01 (phone + SMS OTP, primary), `03_Security_Access.md` §1.2 / §1.4 (6-digit, 5-min expiry, 3-attempt lockout, 5/hour rate limit), `04_Frontend_Specification.md` §3.2 + §3.3 (login screen "Send OTP Code" + OTP screen with 6 auto-advancing digit boxes + resend countdown).
- **Current state:** `AuthRepository.sendPhoneOtp()` and `verifyPhoneOtp()` exist (`auth_repository.dart:37,45`). `AuthProvider.sendOtp / verifyOtp` exist (`auth_provider.dart:149,166`). The login screen (`login_page.dart`) only exposes email + password — there is no "+92 phone field" toggle, no "Send OTP Code" button, and **no `OtpVerifyScreen` file** under `presentation/pages/auth/`. Phone OTP is therefore unreachable from the UI. `project_state.md` §5 explicitly notes phone auth is "currently disabled at the Supabase project level" but the Flutter UI side is also not built.
- **Severity:** high (primary auth method per the spec).
- **Implementation plan:**
  1. Create `presentation/pages/auth/otp_verify_page.dart` with 6 `TextField`s that auto-advance, a 60-second resend timer, and a "Verify & Continue" button calling `AuthProvider.verifyOtp(phone, token)`.
  2. Rework `login_page.dart` to follow `04_Frontend_Specification.md` §3.2: phone field with `+92` prefix as the default, "Send OTP Code" button → `AuthProvider.sendOtp(phone)` → push `OtpVerifyPage`. Keep the email branch under "Use Email Instead".
  3. Add the OTP resend countdown widget (`Timer.periodic` with `dispose`).
  4. On the Supabase side (out of scope for frontend but document): enable Phone Auth provider, configure 5-min OTP expiry, 5/hour rate limit. The frontend does not need to enforce the 3-attempt lockout — Supabase handles it server-side via `verifyOTP` errors.
  5. Surface the phone-claim trigger behaviour (the existing `AuthProvider.verifyOtp` already calls `claimBusinessByPhone` — verify it surfaces a "claimed profile X" message when `business_partners.user_id` updates).
- **Effort:** small–medium.
- **Notes:** RLS / claim trigger (`03_Security_Access.md` §1.5) is already in place and live-tested in `project_state.md` §7. The frontend just lacks the entry-point screens.

### 2. Phone-format validation not wired into signup / partner forms

- **Feature:** Pakistan phone format validation (03XXXXXXXXX).
- **Requirement:** `03_Security_Access.md` §4.3 (PK 11-digit phone regex), `04_Frontend_Specification.md` §3.2 / §3.4.
- **Current state:** `core/utils/validators.dart:20` defines `Validators.phone(value)` matching `^03\d{9}$`. A repo-wide grep shows **no caller of `Validators.` anywhere** in `lib/`. The signup form (`signup_page.dart:102`) only checks `value.isEmpty`. Partner and customer create pages have no phone validation.
- **Severity:** medium.
- **Implementation plan:**
  1. In `signup_page.dart` replace the empty check with `Validators.phone` on the phone `TextFormField`.
  2. Same change in `partners/create_partner_page.dart` and `customers/create_customer_page.dart` (optional field per the spec — make it a soft warning or required depending on whether phone is the primary key for unclaimed-partner claim matching).
  3. Add a hint formatter so the phone field shows `0300 1234567` while editing.
- **Effort:** small.
- **Notes:** Pure UI; no backend changes.

### 3. Profile-claim acknowledgement + partner invite messaging

- **Feature:** Resend invitation to unclaimed partner; UI for "invitation sent".
- **Requirement:** `04_Frontend_Specification.md` §9.2 ("Resend Invitation" for not-yet-claimed partners), `03_Security_Access.md` §7 (claim flow).
- **Current state:** `PartnerRepository.invite(partnerId)` is an empty stub (`partner_repository.dart:46` — `return;`). `PartnerProfilePage` calls it and shows "Invitation sent" snackbar unconditionally (`partner_profile_page.dart:135-145`). There is no actual SMS / email send — the phone-claim mechanism only triggers when the partner installs the app and signs up with that phone.
- **Severity:** medium.
- **Implementation plan:**
  1. Decide between (a) Supabase Edge Function for an invite SMS (Twilio), (b) a "share install link" `Share.share()` action that the owner forwards via WhatsApp, or (c) leave the button as a no-op with copy "Share the install link with X" using `share_plus` (already in pubspec).
  2. Until that backend work ships, reword the copy in `partner_profile_page.dart` to "Notify X" and open `Share.share('Install Green Market: <deep-link>')`.
  3. Backend (out of scope): add Edge Function or trigger that sends an SMS via Supabase SMS provider on row insert with `is_claimed = false`.
- **Effort:** small (frontend) / large (backend).
- **Notes:** RLS already allows the owner to read/modify the partner row; only the notification side is missing.

### 4. CSV / PDF export (stubbed everywhere)

- **Feature:** Export P&L, customer credit, batch P&L, customer list to CSV / PDF.
- **Requirement:** `01_PRD.md` §5.10 FR-PL-06 (batch P&L as PDF via `printing`), §5.13, `04_Frontend_Specification.md` §9.5 "Export Full Report PDF", `02_Technical_Architecture.md` §2 (Tech Stack — `pdf` 3.11 + `printing` 5.13 listed).
- **Current state:** `pdf` and `printing` are in `pubspec.yaml` but **no file imports `package:pdf` or `package:printing`**. `grep` confirms zero references. Five sites show a SnackBar "Export available in a later build":
  - `batches/batch_detail_page.dart:544` (`_confirmDelete` — wrong context but the same stub)
  - `batches/batch_pl_page.dart:40`
  - `customers/customer_list_page.dart:53`
  - `reports/pl_report_page.dart:164`
  - `reports/credit_report_page.dart:155`
- **Severity:** medium.
- **Implementation plan:**
  1. Create `core/export/csv_writer.dart` — utility that takes `List<Map<String,dynamic>>` + columns list, returns a `String` with proper escaping.
  2. Create `core/export/pdf_builder.dart` — builds a `pw.Document` for batch P&L (use `BatchPLDetailModel` + cost chain table).
  3. In each report page, on the export icon, write CSV to a temp file via `path_provider.getTemporaryDirectory()`, then `Share.shareXFiles([XFile(path)])`.
  4. For PDF: `Printing.layoutPdf(onLayout: (format) => pdfBytes)` to open the system share sheet.
  5. Replace the SnackBar stubs in all five sites.
- **Effort:** medium.
- **Notes:** `share_plus` and `path_provider` are already in pubspec. `printing` brings its own iOS/Android build quirks (`project_state.md` already patched `android/build.gradle.kts` for `printing`).

### 5. Offline / local cache (stub)

- **Feature:** Dashboard cache + offline banner + connectivity check before writes.
- **Requirement:** `01_PRD.md` §7 ("Last-loaded dashboard data persists via SharedPreferences for viewing when offline. Write operations require connectivity — show clear error"), `02_Technical_Architecture.md` §9 (cache + connectivity), `04_Frontend_Specification.md` §12 (offline banner UI).
- **Current state:** `data/repositories/sync_repository.dart` is a 9-line no-op (`processQueue()` returns immediately). `core/supabase/supabase_service.dart:21` `isConnected()` always returns `true`. `ConnectivityProvider` (`presentation/providers/connectivity_provider.dart`) is registered in `main.dart` but **no widget calls `ConnectivityProvider` / listens to `isOnline`** — verified via grep. `connectivity_plus` is not in `pubspec.yaml`. No `SharedPreferences` caching happens on read failure.
- **Severity:** medium.
- **Implementation plan:**
  1. Add `connectivity_plus` to `pubspec.yaml`.
  2. Wire `ConnectivityProvider.check()` to listen to the connectivity stream, set `_isOnline`, and `notifyListeners`.
  3. Build a top-level `OfflineBanner` widget (Material 3 spec from `04_Frontend_Specification.md` §12) listening to `ConnectivityProvider.isOnline` and shown above the Scaffold body when offline.
  4. In `DashboardRepository.getSummary`, on Supabase failure read from `SharedPreferences` (key `dashboard_cache`); on success, write to cache.
  5. In write paths (`SaleRepository.create`, `ExpenseRepository.create`, etc.) call `ConnectivityProvider.check()` first; throw an `OfflineException` consumed by the SnackBar/Retry button.
  6. Either remove the dead `ConnectivityProvider` registration if not used, or actually use it.
- **Effort:** medium.
- **Notes:** Spec also says "no silent offline queue" — keep that constraint; this is read-cache + connectivity-guard only.

### 6. Role-based UI gating (viewer / editor / accountant)

- **Feature:** Hide or disable write actions based on the current partner's `role` and `access_level`.
- **Requirement:** `01_PRD.md` §3 (role matrix), `03_Security_Access.md` §2.2 (table of who-can-do-what), `IMPLEMENTATION_PLAN.md` §13.
- **Current state:** Only two places check role:
  - `batches/batch_detail_page.dart:62-64` — `canEdit = userRole != 'accountant' && userRole != 'viewer'`; `canDelete = userRole == 'owner'`. Used only to gate FAB.
  - `partners/partner_profile_page.dart:151` — `if (currentRole == 'owner')` wraps the access-management card.
  - No helper like `Capability.can(Capability.createBatch)`; no `customer.create` gating; no partner-create gating; no record-payment gating; no settlement gating; no markets/products gating.
- **Severity:** high (security spec says RLS is the gate but the spec also calls for UI hiding — and `IMPLEMENTATION_PLAN.md` §13 lists this as Phase 7 hardening).
- **Implementation plan:**
  1. Add `presentation/providers/capability.dart` (or extend `AuthProvider`) with `bool can(String capability)` mapped to the `03_Security_Access.md` §2.2 table.
  2. Wire the existing checks to a unified helper.
  3. Gate the customer-create FAB (already owner-only), record-payment (editor allowed), partner-create (owner only), markets-create (owner only), products-create (editor allowed per RLS), settlements (editor allowed), expense-add (editor allowed), access-management page (owner only).
  4. Show a read-only banner on the batch detail for viewer / accountant ("You can view this batch but cannot make changes.").
- **Effort:** small (mostly wrapping existing checks).
- **Notes:** RLS remains the enforcement layer; the UI changes are a UX courtesy.

### 7. Real-time subscriptions (sales / expenses / customer_payments)

- **Feature:** Subscribe to Supabase Realtime so partner B's sales show on partner A's batch without refresh.
- **Requirement:** `02_Technical_Architecture.md` §8 (`sales_batch_{id}`, `expenses_batch_{id}`, `customer_payments_{customer_id}` channels), `IMPLEMENTATION_PLAN.md` §12.
- **Current state:** Repo-wide grep for `RealtimeChannel`, `supabase.channel`, `.onPostgresChanges`, `.subscribe(`, `removeChannel` returns **zero matches**. Realtime is therefore completely absent in the Flutter app.
- **Severity:** high.
- **Implementation plan:**
  1. Verify Realtime is enabled on `sales`, `expenses`, `customer_payments` in Supabase (out of scope, document).
  2. In `BatchSalesTab` (currently inside `batch_detail_page.dart:_salesTab`), create a `RealtimeChannel` in `initState`, subscribe with filter `batch_id = widget.batchId`, call back into the provider on `INSERT`. `dispose` removes the channel.
  3. Same pattern for `_expensesTab` (`INSERT` + `UPDATE` to catch voids) and `customer_ledger_page.dart` for `customer_payments_{customer_id}`.
  4. Consider promoting `_salesTab`, `_expensesTab`, ledger into `StatefulWidget`s so they own their channel lifecycle (currently the whole detail page is one StatefulWidget — channels would need to be created/disposed when the tab index changes, not when the page opens).
- **Effort:** medium.
- **Notes:** No additional deps required (`supabase_flutter` already bundles realtime). Make sure the page already loaded the initial data before subscribing so the first INSERT doesn't trigger a useless reload.

### 8. Audit-log viewer (owner-only)

- **Feature:** UI to read `audit_logs`.
- **Requirement:** `01_PRD.md` §5.10 / §5.13 (implied), `03_Security_Access.md` §2.2 ("View audit logs" → owner), §6 (audit trail via triggers), `IMPLEMENTATION_PLAN.md` Phase 5.
- **Current state:** `audit_logs` table is live and `project_state.md` §7 confirms triggers insert rows. **No Flutter code reads from `audit_logs`** — grep returns zero matches. The data layer has no `AuditRepository` / no model.
- **Severity:** medium.
- **Implementation plan:**
  1. Add `lib/data/models/audit_log_model.dart` (table_name, record_id, action, performed_by, old_values, new_values, created_at).
  2. Add `lib/data/repositories/audit_repository.dart` reading `audit_logs` filtered by `business_id` via RLS.
  3. Add `lib/presentation/pages/settings/audit_log_page.dart` accessible only when `currentRole == 'owner'`. Filter by date range + table_name.
  4. Add a tile in `settings_page.dart` (Account section).
- **Effort:** small–medium.
- **Notes:** Backend already enforces owner-only RLS (per `03_Security_Access.md` §3.13).

### 9. Batch close action (mark batch closed)

- **Feature:** Owner / editor transitions a batch to `closed` and the system enforces read-only thereafter.
- **Requirement:** `01_PRD.md` §5.5 FR-B-07 (status only moves forward; closed = read-only), `04_Frontend_Specification.md` §6.3 Overview tab "Mark as Closed" button.
- **Current state:** `BatchDetailProvider.updateStatus()` blindly walks to the next status via `_statusFlow` — there is no "Mark as Closed" affordance. `_advanceStatus` (`batch_detail_page.dart:512`) just calls `updateStatus(nextStatus)`. The "Advance Status" button advances one step only; reaching `closed` requires 5 taps. There is no check that blocks writes once status is `closed` — `_buildFab` still shows on a closed batch (gated only by `canEdit`). The `_confirmDelete` action (lines 533–546) is also misleadingly named — it's a stub SnackBar.
- **Severity:** medium.
- **Implementation plan:**
  1. Add a "Mark as Closed" button on the Overview tab visible only when `batch.status != 'closed'` (per spec sketch).
  2. Gate `ExpenseProvider.add`, `SaleProvider.add`, `BatchDetailProvider.addPacking` to refuse when the parent batch's status is `closed`.
  3. Hide all FABs (`Expense`, `Sale`, `Packing`) when `status == 'closed'`.
  4. Surface a "Closed — read only" pill on the Overview card.
  5. Replace the misleading `_confirmDelete` snackbar with the actual close action (or remove the trash icon).
- **Effort:** small.
- **Notes:** DB already has the `status` CHECK constraint and the `audit_logs` trigger fires on status change.

### 10. Quantity validation for sales (cannot exceed remaining)

- **Feature:** Sales quantity must not exceed `qty_total - qty_sold`.
- **Requirement:** `01_PRD.md` §5.8 FR-S-03, `04_Frontend_Specification.md` §7.2 SaleEntryScreen "only 'selling' status batches" + remaining-qty hint.
- **Current state:** The sale entry sheet and `quick_sale_page.dart` only check `qty <= 0 || price <= 0` (`sale_entry_sheet.dart:70`). The hint text shows `Total: <totalQuantity>` not `<remaining>`. The DB constraint (`chk_amounts` on `sales`) only enforces the cash+credit = qty×price math; nothing prevents `quantity_sold > remaining`.
- **Severity:** high.
- **Implementation plan:**
  1. Extend `BatchModel` to expose `soldQuantity` + `remainingQuantity` from the batch detail query (`BatchRepository.get` should also select the aggregate sales qty, or expose a derived `BatchModel.fromJson` that reads a `qty_remaining` field if the view/RPC includes it).
  2. In `sale_entry_sheet.dart` and `quick_sale_page.dart`, validate `qty <= remaining` and disable Save when false; show "Only X remaining" hint.
  3. Optionally add a CHECK constraint at the DB layer (or a SECURITY DEFINER `can_sell_batch(batch_id, qty)` helper used in `sales_insert`).
- **Effort:** small.
- **Notes:** The `chk_amounts` constraint is already enforced; this is purely the remaining-qty rule.

### 11. Payment validation (cannot exceed outstanding)

- **Feature:** Customer payment `amount` must be ≤ outstanding balance.
- **Requirement:** Implied by `01_PRD.md` §5.9 FR-C-04 (record payment reduces outstanding balance) and FR-C-06 (running credit color).
- **Current state:** `record_payment_page.dart:33` only requires the amount be non-empty (`double.parse(_amountCtrl.text.trim())`). Nothing prevents over-payment.
- **Severity:** low.
- **Implementation plan:**
  1. Pass the customer into the form (already wired — `widget.customer`).
  2. Show the outstanding balance at the top of the page and disable Save if `amount > outstanding`.
  3. Or accept over-payment (some businesses allow credit-in-advance) — confirm product decision; if disallowed, validate.
- **Effort:** small.
- **Notes:** Customer ledger already renders running balance; the input side is the only gap.

### 12. Internationalization / Urdu RTL

- **Feature:** Urdu RTL language support.
- **Requirement:** `01_PRD.md` §7 (Urdu in V2), `IMPLEMENTATION_PLAN.md` §4 / §6.
- **Current state:** Repo-wide grep for `flutter_localizations`, `MaterialLocalizations`, `SupportedLocales`, `Locale`, `urdu`, `Urdu` returns zero matches. `pubspec.yaml` does not include `flutter_localizations`. `MaterialApp` in `main.dart` doesn't declare `localizationsDelegates` or `supportedLocales`.
- **Severity:** low (explicitly V2 in the PRD).
- **Implementation plan:**
  1. Add `flutter_localizations: { sdk: flutter }` to `pubspec.yaml`.
  2. Create `lib/l10n/app_en.arb` + `lib/l10n/app_ur.arb` with at minimum the top-level strings (welcome copy, button labels, status names).
  3. Wire `localizationsDelegates: [GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate]` and `supportedLocales: [Locale('en'), Locale('ur')]` in `MaterialApp`.
  4. Run `flutter gen-l10n` (this introduces a tiny build step; document in `project_state.md`).
  5. For RTL: wrap `Directionality(textDirection: TextDirection.rtl, child: ...)` for Urdu locale; verify icons, hero cards, dropdowns mirror correctly.
- **Effort:** medium–large.
- **Notes:** Spec §7 says structure ready, translation deferred — but no `Directionality` wiring exists either.

### 13. Responsive / tablet layouts

- **Feature:** Tablet / landscape layouts (the spec says "Flutter Web is bonus").
- **Requirement:** `01_PRD.md` §7, `IMPLEMENTATION_PLAN.md` §16 Phase 7 (responsive check).
- **Current state:** Repo-wide grep for `LayoutBuilder`, `MediaQuery.size`, `Responsive`, `Breakpoints` returns zero matches. All pages use fixed paddings and `CrossAxisCount: 2` grids (`reports_page.dart:78`) regardless of screen width.
- **Severity:** low.
- **Implementation plan:**
  1. Add a `core/utils/breakpoints.dart` with `compact (<600)`, `medium (600–1024)`, `expanded (>1024)` thresholds.
  2. Wrap the dashboard grid + reports hub grid in a `LayoutBuilder` to switch `crossAxisCount` from 2 (compact) to 4 (expanded).
  3. For batch detail, switch tab orientation to `NavigationRail` when expanded.
  4. Add a two-column form layout for onboarding / customer create on expanded screens.
- **Effort:** medium.
- **Notes:** Flutter Web "bonus" — but `flutter build web` already succeeds per `project_state.md`.

### 14. Bulk operations (multi-select)

- **Feature:** Select many items in a list to bulk-update / bulk-delete.
- **Requirement:** Implied by `04_Frontend_Specification.md` §12 ("empty states") and the spec's emphasis on partner workflows; not explicitly mandated but a natural follow-on for batch list / customer list.
- **Current state:** Grep for `BulkSelect`, `batchActions`, `bulkDelete` returns zero matches. Lists are single-tap only.
- **Severity:** low.
- **Implementation plan:**
  1. Add a multi-select mode toggle to `BatchListPage` (long-press to enter), checkbox column on each `GreenCard`, and an AppBar action menu when any are selected (e.g., "Mark Closed", "Export Selected").
  2. Repeat for `CustomerListPage` ("Send payment reminders" — out of scope) and `SalesListPage`.
- **Effort:** medium.
- **Notes:** Soft delete via `is_voided` (expenses) / status change (batches) already supported.

### 15. Print receipt

- **Feature:** Print a thermal-receipt-style sale receipt (PDF / Bluetooth).
- **Requirement:** Not explicitly in the PRD; could be a Phase 8 nice-to-have. Mentioning because `printing` is already wired in.
- **Current state:** No `printing.*` call anywhere.
- **Severity:** low.
- **Implementation plan:**
  1. Create `core/export/receipt_builder.dart` — narrow `pw.Document` with header (batch code, customer, date), line items (qty × price = total), payment mode, signature.
  2. Hook into `sale_entry_sheet.dart` after save: offer "Print Receipt" alongside "Save Sale".
  3. Optionally integrate `esc_pos_bluetooth` for direct thermal printer support.
- **Effort:** medium.
- **Notes:** Out-of-scope per PRD §8 but trivial given `printing` is already added.

### 16. Profile photo upload

- **Feature:** User / partner / customer avatar image upload.
- **Requirement:** Not explicitly in the PRD; `03_Security_Access.md` §5 mentions "Receipts/photos → Supabase Storage private bucket — requires authenticated URL".
- **Current state:** Grep for `image_picker`, `file_picker`, `supabase.storage` returns zero matches. Avatars are letter-based `CircleAvatar`s everywhere.
- **Severity:** low.
- **Implementation plan:**
  1. Add `image_picker` + `cached_network_image` (already in pubspec) to pubspec.
  2. Create `lib/data/repositories/storage_repository.dart` wrapping `supabase.storage.from('avatars').upload(...)`.
  3. Update `user_profiles` and `business_partners` with `avatar_url` column (small DB migration; backend out of scope).
  4. From `ProfilePage` / `PartnerProfilePage`, add a photo button → `ImagePicker` → upload → update column.
- **Effort:** medium.
- **Notes:** Storage bucket setup is backend work.

### 17. Notifications (push / local / email)

- **Feature:** Push notifications for credit alerts / batch updates / new sales.
- **Requirement:** `01_PRD.md` §8 (push notifications — Realtime used instead, V1).
- **Current state:** `NotificationSettingsPage` only persists local toggles in `SharedPreferences`; nothing actually triggers a notification. No FCM / `flutter_local_notifications` / Supabase webhook integration. `pubspec.yaml` lacks `flutter_local_notifications` or `firebase_messaging`.
- **Severity:** low (out of scope per §8).
- **Implementation plan (if pursued later):**
  1. Add `flutter_local_notifications` for local notifications when the app is foregrounded and Realtime events arrive.
  2. Add `firebase_messaging` + APNs for background notifications.
  3. Wire a Supabase Edge Function / Database Webhook that fires on `sales` / `customer_payments` insert and pushes to the relevant partner's device.
- **Effort:** large.
- **Notes:** Real-time subscriptions (gap #7) are the V1 substitute; this is a future enhancement.

### 18. Pagination on list endpoints

- **Feature:** Cursor-based pagination for batch / customer / sale / partner / market lists.
- **Requirement:** `02_Technical_Architecture.md` §2 (scalability "10,000 batches, 500,000 transactions"), §6 (`get_business_pl_summary` aggregates), `IMPLEMENTATION_PLAN.md` §16.
- **Current state:** `BatchRepository.list` and `SaleRepository.listByBatch` accept `cursor` + `limit = 50` parameters, but **no page calls them**. Every page calls `load(businessId)` which fetches the first 50 only and never loads more. No "Load more" or infinite scroll in the UI.
- **Severity:** medium.
- **Implementation plan:**
  1. Add `cursor` state to each list provider (or use a simple "page" int).
  2. Switch list views from `ListView` to `ListView.builder` with a `NotificationListener` on scroll to trigger `_loadMore()` when near the bottom.
  3. Persist `cursor` between scrolls; reset on refresh / filter change.
- **Effort:** small–medium.
- **Notes:** The repo layer is already pagination-ready.

### 19. Date range filter on reports + transaction list

- **Feature:** Date range filter on partner reports / transaction list / sales list.
- **Requirement:** `01_PRD.md` §5.13 (implied), `04_Frontend_Specification.md` §9.5 (`Reports` screen has explicit date range picker).
- **Current state:** Only `pl_report_page.dart` has a `showDateRangePicker` UI (and it works). `partner_report_page.dart`, `transaction_list_page.dart`, `credit_report_page.dart` (city filter only), `market_performance_page.dart`, `sales_list_page.dart` — **no date filter**. The `overdue_customers_page.dart` has a threshold slider but no time window.
- **Severity:** medium.
- **Implementation plan:**
  1. Promote a reusable `DateRangeFilterButton` widget (icon in AppBar that opens `showDateRangePicker` and writes `_from / _to` state).
  2. Wire into `credit_report_page`, `market_performance_page`, `transaction_list_page`, `sales_list_page`, `partner_report_page`.
  3. Pass `from_date / to_date` to the underlying RPC / `.gte('created_at', from)` filters.
- **Effort:** medium.
- **Notes:** The `report_repository.getOverdueCustomers` doesn't accept date params yet — extend it.

### 20. Multi-currency

- **Feature:** Currency code per business (`currency_code`), `exchange_rate` for batch totals.
- **Requirement:** Not in PRD §5 or §7; PRD §7 specifies PKR throughout. Implicit V2.
- **Current state:** `CurrencyFormatter` is hard-coded to `'PKR'` (`core/utils/currency_formatter.dart:8`). `businesses.currency_code` doesn't exist in the schema. No exchange-rate support.
- **Severity:** low (not a v1 requirement).
- **Implementation plan:** Out of scope unless explicitly requested.

### 21. Searchable dropdowns (batch in Quick Sale, customer in Sale Entry)

- **Feature:** Type-ahead search inside the `DropdownButtonFormField`s for batch / customer / partner.
- **Requirement:** `04_Frontend_Specification.md` §7.2 / §8.3 ("Search customer…" / "Search partners…").
- **Current state:** A generic `SearchableDropdown` widget exists (`widgets/searchable_dropdown.dart`) but is **not used anywhere** — grep finds only the file itself. `quick_sale_page.dart` and `sale_entry_sheet.dart` use raw `DropdownButtonFormField` that lists all customers/batches unfiltered (problematic once a business has dozens of each).
- **Severity:** medium.
- **Implementation plan:**
  1. Replace `DropdownButtonFormField<BatchModel>` in `quick_sale_page.dart` and `sale_entry_sheet.dart` with `SearchableDropdown` (or build a thin `_BatchPicker` that wraps a `TextField` + filtered bottom sheet, similar to the existing `PartnerSelector`).
  2. Replace `DropdownButtonFormField<CustomerModel?>` with a customer picker that supports searching.
- **Effort:** small.

### 22. Dashboard "Today's Sales" actually pulls from sales table by `sale_date`

- **Feature:** "Today's Sales" stat card.
- **Requirement:** `01_PRD.md` §5.12 FR-D-01 (`Today's Sales (PKR)`), `04_Frontend_Specification.md` §5 (dashboard cards).
- **Current state:** `DashboardRepository.getSummary` queries `sales` for rows with `sale_date >= today`. **Buggy:** `gte('sale_date', todayIso)` compares a `DATE` column to an ISO timestamp like `2026-08-08T00:00:00`, which works on Postgres but the join via `product_batches!inner(business_id)` filters server-side. However, the dashboard shows `todaySales` as the hero amount — and `project_state.md` §6 reports E2E success, so this is working in practice. **However**, the `outstanding_credit` field is summed from `customers.outstanding_balance` which is a column maintained server-side (per `project_state.md` §7 — "customer balance trigger"). That works. No actual bug here — flagged for awareness only.
- **Severity:** low (currently working).
- **Notes:** Worth keeping an eye on if `outstanding_balance` column is dropped in a future schema revision; should fall back to RPC `get_customer_balance`.

### 23. Partner-selector role / seller enforcement

- **Feature:** Wizard Step 2 only has a single "Purchasing Partners" section; the spec says selling partner is separate.
- **Requirement:** `04_Frontend_Specification.md` §6.2 Step 2 ("Purchasing Partner(s) * / Selling Partner *"), §5.5 FR-B-04 (one selling partner).
- **Current state:** `CreateBatchWizard._step2` only renders a single `PartnerSelector` for purchasers. There is **no separate "Selling Partner" picker**, no `transport_paid_by` per selling partner, no role enforcement on the batch wizard. The current code lets the partner role default to `purchaser` for all selected partners.
- **Severity:** high (data model expects a seller — `batch_partners.role IN ('purchaser','seller','both')`).
- **Implementation plan:**
  1. Add a "Selling Partner" `DropdownButtonFormField<String>` below the `PartnerSelector` on Step 2, sourced from the same partner list.
  2. Include `role = 'seller'` on the resulting `BatchPartnerCreate`.
  3. Validate that at least one partner is selected and at least one is flagged seller.
  4. Mirror the change into `BatchCreateRequest.partners` so it accepts multiple roles and the server can validate exactly one seller.
- **Effort:** small.
- **Notes:** Schema already supports `seller` role; this is purely UI + payload.

### 24. Daily-charge expense auto-suggest

- **Feature:** When user adds a `daily_charge` expense, prefill `rate × days` from the batch partner data.
- **Requirement:** `01_PRD.md` §5.7 FR-E-05 ("auto-suggested"), `04_Frontend_Specification.md` §6.2 Step 2 "For Tariq: Daily Rate PKR / Days Involved / Subtotal: PKR 4,500 (auto)".
- **Current state:** The wizard Step 2 collects `daily_charge_rate` and `days_involved` on each partner and folds the subtotal into Step 5's "Daily charges" total (`create_batch_wizard.dart:637-641`). However, the `ExpenseEntrySheet` (FAB on Expenses tab) does **not** prefill when `expense_type = 'daily_charge'` — users have to re-enter rate × days manually.
- **Severity:** low.
- **Implementation plan:**
  1. In `expense_entry_sheet.dart`, when `_type == 'daily_charge'` and the batch has known daily-charge partners, show a `PartnerSelector` and compute `amount = rate × days` automatically.
  2. Read daily-charge rate from the batch's `batch_partners` (via a `BatchDetailProvider` extension or `BatchRepository.getBatchPartners(id)`).
- **Effort:** small.
- **Notes:** Schema has `daily_charge_rate` and `days_involved` columns already; just need a query.

### 25. Transport-debt auto-creation (FR-T-03)

- **Feature:** Auto-create a `partner_transactions` row of `transport_debt` when purchaser pays transport that is seller's responsibility.
- **Requirement:** `01_PRD.md` §4.3 (transport attribution rule), §5.11 FR-T-03, `03_Security_Access.md` §2 (implied).
- **Current state:** The `product_batches` table has `transport_paid_by`; `partner_transactions` has `transaction_type = 'transport_debt'` as an allowed value. **No code anywhere creates a transport-debt transaction.** `transaction_repository.dart` only handles `settlement / advance / expense_reimbursement`. `TransactionProvider.create` accepts any string. The UI lets the user record manual settlements (`partner_settlement_page.dart`) but the auto-attribution is missing.
- **Severity:** medium.
- **Implementation plan (frontend-side trigger):**
  1. After a successful batch create with `transport_paid_by` set, if the paying side differs from the attributed side (you'd need to introduce a `transport_attribution` field or hardcode a rule like "purchaser pays → no debt; seller pays → no debt; mismatch handled by owner at creation time"), insert a `partner_transactions` row with `transaction_type = 'transport_debt'`.
  2. Alternatively (better): add a DB trigger `AFTER INSERT ON product_batches` that creates the transport-debt row based on `transport_paid_by` vs the seller assignment. This is backend work — out of scope, document here.
- **Effort:** small (frontend) / medium (backend).
- **Notes:** Spec says inter-partner debt should be auto-tracked; current code only lets the owner record it manually.

### 26. Profile / business settings: validation gaps

- **Feature:** Form validation on profile + business settings.
- **Requirement:** `03_Security_Access.md` §4.3 (input validation), `04_Frontend_Specification.md` §9.
- **Current state:** `ProfilePage` has a `Form` with validators on name only; email / phone / city are unvalidated. `BusinessSettingsPage` has no validators at all — it silently accepts empty `name` (only checks at submit time and throws a SnackBar).
- **Severity:** low.
- **Implementation plan:**
  1. Use `Validators.email / Validators.phone` on the corresponding fields.
  2. Validate `_thresholdCtrl` is a non-negative number.
- **Effort:** small.

### 27. Customer search uses `ilike` only on `full_name`

- **Feature:** Search by phone or shop name in addition to customer name.
- **Requirement:** `01_PRD.md` §5.9 FR-C-02, `04_Frontend_Specification.md` §8.1.
- **Current state:** `CustomerRepository.list(... search)` only does `ilike('full_name', '%$search%')`. The `CustomerListPage` hint text says "Search by name, phone, or shop" but the implementation only matches name.
- **Severity:** low.
- **Implementation plan:**
  1. Use `.or('full_name.ilike.%$search%,phone.ilike.%$search%,shop_name.ilike.%$search%')` in `CustomerRepository.list`.
- **Effort:** trivial.

### 28. Help Center / About content is hard-coded English

- **Feature:** i18n for help & about.
- **Requirement:** `04_Frontend_Specification.md` §9 (no language requirement), `01_PRD.md` §7 (Urdu).
- **Current state:** All strings in `help_center_page.dart`, `about_page.dart`, `notification_settings_page.dart` are hard-coded English literals.
- **Severity:** low (depends on gap #12).
- **Implementation plan:** Folded into gap #12.

### 29. Soft-delete UX is misleading

- **Feature:** Expenses can be "voided" with a reason; per `01_PRD.md` Rule 7 no hard deletes.
- **Requirement:** `01_PRD.md` §6 Rule 7 + §5.7 FR-E-06, `03_Security_Access.md` §6.1.
- **Current state:**
  - `ExpenseProvider.voidExpense(id, reason)` and `ExpenseRepository.voidExpense(...)` exist.
  - `batch_detail_page.dart:319` uses `Dismissible` (swipe-to-delete) on each expense row, which **calls `ExpenseProvider.delete(id)` (a HARD delete!)** instead of `voidExpense`. The confirm dialog says "This action cannot be undone." — but it can be undone only via the DB trigger audit log; the row is actually deleted.
  - The void flow is unreachable from the UI.
- **Severity:** high (Rule 7 violation).
- **Implementation plan:**
  1. Replace the swipe-to-delete action with a swipe-to-void. Show a "Void Expense" dialog asking for a reason.
  2. Call `ExpenseProvider.voidExpense(id, reason)` instead of `delete`.
  3. Show voided expenses in the list with a strikethrough / "Voided" badge, and exclude their amounts from the subtotal.
  4. Hide the void affordance unless `currentRole == 'owner'` (per `03_Security_Access.md` §2.2).
  5. Either remove `ExpenseRepository.delete` or rename it `hardDelete` and call only from admin tooling.
- **Effort:** small.
- **Notes:** The DB schema already supports `is_voided / voided_by / voided_reason`; the audit trigger already fires.

### 30. Customer delete is a stub snackbar

- **Feature:** Owner-only swipe-to-delete on customer.
- **Requirement:** `01_PRD.md` Rule 7 (soft delete / archive only).
- **Current state:** `CustomerListPage._deleteCustomer(id)` (`customer_list_page.dart:52`) just shows the "Export available in a later build" SnackBar (copy/paste mistake from the export stub).
- **Severity:** medium.
- **Implementation plan:**
  1. Decide between "archive" (add `is_archived` to `customers`) or true soft delete with an `archived_at` column.
  2. Add `CustomerRepository.archive(id)` that sets the flag; hide archived customers from lists (filter `.eq('is_archived', false)`); show an "Archived" tab/section.
  3. From `CustomerListPage` swipe action, call archive + show snackbar with "Undo" action.
- **Effort:** small–medium.

### 31. Batch delete is a stub snackbar

- **Feature:** Owner-only delete batch.
- **Requirement:** Rule 7 (soft only).
- **Current state:** `batch_detail_page.dart:_confirmDelete` (lines 533–546) shows the misleading "Export available in a later build" snackbar — should never have been a delete action.
- **Severity:** medium.
- **Implementation plan:**
  1. Replace the trash icon with a "Mark as Closed" CTA (already proposed in gap #9), OR
  2. Wire an actual `is_archived` / `archived_at` soft-delete.
- **Effort:** small.

### 32. `validators.dart` is dead code

- **Feature:** Centralized input validation.
- **Requirement:** `03_Security_Access.md` §4.3.
- **Current state:** Defined, zero callers (verified via grep).
- **Severity:** low.
- **Implementation plan:**
  1. Apply across `signup`, `login`, `record_payment_page`, `create_partner_page`, `create_customer_page`, `create_market_page`, `create_batch_wizard`, `business_settings_page`, `profile_page`.
- **Effort:** small.

### 33. ConnectivityProvider is registered but unused

- **Feature:** Connectivity gating.
- **Requirement:** `02_Technical_Architecture.md` §9.
- **Current state:** Registered in `main.dart`; no widget reads it; `SupabaseService.isConnected()` always returns `true`.
- **Severity:** medium (it's also a dead-code indicator that offline work was never finished).
- **Implementation plan:** Folded into gap #5.

### 34. Dead pubspec dependencies

- **Feature:** Pruned dependencies.
- **Requirement:** `IMPLEMENTATION_PLAN.md` §4.
- **Current state:** Per `project_state.md` §1 (stale note): `path_provider`, `share_plus`, `pdf`, `printing`, `flutter_slidable`, `cached_network_image`, `uuid` are in pubspec but **never imported**. Grep confirms: zero `package:pdf` / `package:printing` / `package:share_plus` / `package:path_provider` / `package:uuid` / `package:cached_network_image` / `package:flutter_slidable` references anywhere in `lib/`.
- **Severity:** low.
- **Implementation plan:**
  1. Either (a) remove them from pubspec to slim the APK, or (b) wire them into their respective features (export, share, profile-photo, swipe actions).
- **Effort:** small.

### 35. Auth state-change stream not subscribed

- **Feature:** Listen to `supabase.auth.onAuthStateChange` and react to login/logout/token-refresh from any tab.
- **Requirement:** `02_Technical_Architecture.md` §4.2, `03_Security_Access.md` §1.3.
- **Current state:** `AuthRepository.onAuthStateChanged` is a getter that returns the raw `Stream<AuthState>`. No file subscribes to it (`grep` confirms). So if the user's session expires in another tab and Supabase signs them out, this app would not notice.
- **Severity:** medium.
- **Implementation plan:**
  1. In `main.dart` after `Supabase.initialize`, subscribe to `Supabase.instance.client.auth.onAuthStateChange` and forward to `AuthProvider.handleAuthStateChange(data)` (already implied by `IMPLEMENTATION_PLAN.md` §4.2).
  2. On `AuthChangeEvent.signedOut`, call `AuthProvider.logout()` (already exists).
- **Effort:** small.

### 36. AuthInterceptor removed but token-refresh now opaque

- **Feature:** Auto-refresh of Supabase JWT.
- **Requirement:** `03_Security_Access.md` §1.3 (Supabase SDK handles silently).
- **Current state:** `supabase_flutter` 2.16 does auto-refresh internally; no app code needed. **However** `project_state.md` §1 says `flutter_secure_storage` was removed. The new architecture relies on `supabase_flutter`'s default internal storage (`flutter_secure_storage` underneath). Verify this is acceptable for the threat model — the spec says "JWT tokens managed by Supabase Flutter SDK (stored in app-level storage)" (§5), so this is OK.
- **Severity:** low (no action required unless audit demands hardware-backed keys).

### 37. Batch wizard "Back" button on Step 1 mis-renders

- **Feature:** Wizard navigation.
- **Requirement:** `04_Frontend_Specification.md` §6.2.
- **Current state:** `create_batch_wizard.dart:244` correctly hides the Back button when `step == 0`. ✓ (not actually a bug).
- **Severity:** none.

### 38. Status pills colours not aligned with spec palette

- **Feature:** Status pill colours.
- **Requirement:** `04_Frontend_Specification.md` §1.4 (`purchased → grey / packed → blue / in_transit → orange / delivered → teal / selling → green / closed → dark grey`).
- **Current state:** `presentation/widgets/status_pill.dart` defines its own palette — not checked against the spec.
- **Severity:** low (cosmetic).
- **Implementation plan:** Verify `status_pill.dart` matches the six colors above; adjust if not.
- **Effort:** trivial.

### 39. `ConnectivityProvider` is a stale provider

- **Feature:** Connectivity.
- **Requirement:** `02_Technical_Architecture.md` §9.
- **Current state:** Already covered in gap #5 / #33. Restated here for the "stale code" inventory.

### 40. Batch "remaining quantity" displayed but not computed

- **Feature:** Remaining quantity on batch overview.
- **Requirement:** `01_PRD.md` §5.5 FR-B-08, `04_Frontend_Specification.md` §6.3 Overview tab.
- **Current state:** `batch_detail_page.dart:225` shows only `totalQuantity`. The Overview tab spec sketch shows `Sold X / Remaining Y`. `BatchModel` does not include `remainingQuantity`. The `BatchPLDetailModel.remainingQuantity` exists in the model (`report_model.dart:260`) but isn't rendered.
- **Severity:** medium.
- **Implementation plan:**
  1. Extend `BatchRepository.get(id)` to also fetch `qty_sold` (sum of `sales.quantity_sold` for the batch) or expose it via the `get_batch_pl` RPC result.
  2. Render `Sold X / Remaining Y` and a progress bar on the Overview tab.
- **Effort:** small.

---

## Summary tables

### Severity roll-up

| Severity | Count | Highlights |
|----------|-------|------------|
| critical | 0 | — |
| high | 4 | Phone OTP UI (#1), role gating (#6), real-time subscriptions (#7), sale qty validation (#10), soft-delete enforcement (#29), seller in wizard (#23) — note that's 6, not 4 — re-counted below. |
| medium | 11 | Export (#4), offline (#5), audit UI (#8), close-batch UX (#9), payment validation (#11), searchable dropdowns (#21), date filters on reports (#19), pagination (#18), seller-in-wizard (#23), transport-debt (#25), customer/batch delete stubs (#30, #31), connectivity wiring (#33/#35), remaining qty display (#40), expense type bug fix (#29). |
| low | 16+ | l10n, responsive, bulk ops, push, profile photo, multi-currency, validators integration, search by phone/shop, help/about i18n, dead deps, dead providers, palette cosmetics, etc. |

### Effort roll-up

| Effort | Count |
|--------|-------|
| small | majority |
| medium | ~10 |
| large | 1 (push notifications) |

### Top three priorities (recommended)

1. **Phone OTP UI (#1)** — primary auth method per spec, currently unreachable from the app.
2. **Soft-delete enforcement (#29, #30, #31)** — Rule 7 violation: swipe-to-delete is hard-deleting expenses; customer/batch "delete" is a snackbar.
3. **Real-time subscriptions (#7) + offline cache (#5)** — together they make the partner collaboration use case actually work end-to-end.
