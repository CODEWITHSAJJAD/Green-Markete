# Green Market Frontend — Missing Features & Remaining Implementation

**Generated:** June 29, 2026  
**Analysis Scope:** `frontend/green_market/` vs `Frontend_Implementation_Plan.md` + PRD + Feature Tickets

---

## 1. SUMMARY

| Category | Planned | Implemented | Missing |
|----------|---------|-------------|---------|
| Dart files (lib/) | ~110+ | 95 | ~25+ |
| Pages/Screens | 37+ | 17 | 20+ |
| Shared Widgets | 22 | 16 | 6 |
| Remote Datasources | 12 | 11 | 1 |
| Repositories | 13 | 11 | 2 |
| Providers | 14+ | 12 | 2+ |
| Local Database | 4 files | 1 (stub) | 3 |
| Offline Sync | Full | Stub only | Complete |
| Models | 16 | 15 | 1 |

---

## 2. MISSING FILES VS IMPLEMENTATION PLAN

### Core Layer — Complete ✅
All files in `core/config/`, `core/network/`, `core/error/`, `core/utils/` are implemented.

### Data Layer — Missing

| File | Status | Notes |
|------|--------|-------|
| `data/datasources/remote/business_remote_ds.dart` | ❌ Missing | `POST /businesses/create` called directly in `onboarding_page.dart` via raw `ApiClient`. Needs dedicated datasource. |
| `data/datasources/local/cache_dao.dart` | ❌ Missing | Drift DAO for cached batches, products, partners |
| `data/datasources/local/sync_queue_dao.dart` | ❌ Missing | DAO for offline operation queue |
| `data/datasources/local/local_ds_constants.dart` | ❌ Missing | Table schemas for Drift |
| `data/models/dashboard_model.dart` | ✅ Moved | DashboardSummary is inside `report_model.dart` instead of its own file |
| `data/repositories/business_repository.dart` | ❌ Missing | Business CRUD — onboarding calls API directly |
| `data/repositories/dashboard_repository.dart` | ❌ Missing | Dashboard page uses `dashboardProvider.notifier.fetchSummary()` directly via ApiClient, not through a repository |

### Domain Layer — Missing

| File | Status | Notes |
|------|--------|-------|
| `domain/usecases/signup_usecase.dart` | ❌ Missing | Signup logic in auth_provider directly |
| `domain/usecases/create_business_usecase.dart` | ❌ Missing | Onboarding calls API directly |

### Presentation: Pages — Missing

| Page | Route | Status | Notes |
|------|-------|--------|-------|
| `presentation/pages/batches/batch_pl_page.dart` | `/batches/:id/pl` | ❌ Missing | P&L is inline inside batch_detail_page tab (Tab 2), not a dedicated screen |
| `presentation/pages/batches/create_batch_wizard.dart` | `/batches/new` | ❌ Missing | Only a simple single-form `batch_create_page.dart` exists — **not** the 5-step wizard |
| `presentation/pages/partners/partner_profile_page.dart` | `/partners/:id` | ❌ Missing | No partner detail/profile page at all |
| `presentation/pages/reports/pl_report_page.dart` | `/reports/pl` | ❌ Missing | P&L is inline on the reports hub page |
| `presentation/pages/reports/credit_report_page.dart` | `/reports/credit` | ❌ Missing | No dedicated credit report page |
| `presentation/pages/reports/overdue_customers_page.dart` | `/reports/overdue` | ❌ Missing | Overdue customers shown inline on reports hub |
| `presentation/pages/reports/partner_report_page.dart` | `/reports/partner/:id` | ❌ Missing | Partner-specific P&L not implemented |
| `presentation/pages/reports/market_performance_page.dart` | `/reports/market-performance` | ❌ Missing | Market performance report not implemented |
| `presentation/pages/transactions/partner_settlement_page.dart` | `/transactions/settle` | ❌ Missing | Settlement is a dialog inside transaction_list_page, not a dedicated page |
| `presentation/pages/transactions/partner_balance_page.dart` | `/transactions/partner/:id` | ❌ Missing | Partner balance is a bottom sheet inside transaction_list_page |
| `presentation/pages/settings/business_settings_page.dart` | `/settings/business` | ❌ Missing | Business Info tile exists but navigates nowhere |
| `presentation/pages/settings/access_management_page.dart` | `/settings/access` | ❌ Missing | Access management screen not implemented |
| `presentation/pages/settings/profile_page.dart` | `/settings/profile` | ❌ Missing | Edit Profile tile exists but navigates nowhere |

### Presentation: Dashboard Widgets — Missing

| Widget | File | Status | Notes |
|--------|------|--------|-------|
| `summary_cards.dart` | Missing from plan | ✅ Replaced | Inline `DashboardCard` widgets used instead |
| `active_batches_card.dart` | ❌ Missing | Top 5 active batches not rendered as card widget |
| `credit_alerts_card.dart` | ❌ Missing | Credit alerts not shown on dashboard |
| `quick_actions_row.dart` | ❌ Missing | No quick action buttons (+New Batch, +New Sale, etc.) |
| `recent_transactions.dart` | ❌ Missing | Uses `RecentActivityList` instead (shows batches, not transactions) |

### Presentation: Batch Widgets — Missing

| Widget | Status | Notes |
|--------|--------|-------|
| `widgets/status_timeline.dart` | ❌ Missing | Visual timeline for batch status |
| `widgets/partner_selector.dart` | ❌ Missing | Search and add partners to batch |
| `widgets/packing_entry_form.dart` | ❌ Missing | Packing entry form widget |
| `widgets/expense_entry_sheet.dart` | ❌ Missing | Bottom sheet for adding expenses |
| `widgets/sale_entry_sheet.dart` | ❌ Missing | Bottom sheet for recording sales |
| `widgets/batch_summary_card.dart` | ❌ Missing | Summary card for batch confirmation |

### Presentation: Shared Widgets — Missing

| Widget | Status | Notes |
|--------|--------|-------|
| `widgets/overdue_banner.dart` | ❌ Missing | Yellow banner for unclaimed partner profiles |
| `widgets/rate_limiter_handler.dart` | ❌ Missing | Handle 429 rate-limit responses |

---

## 3. MISSING ROUTES (go_router)

Routes defined in the plan but **not in implementation** (`core/config/routes.dart`):

| Route | Page | Missing? |
|-------|------|----------|
| `/batches/:id/pl` | BatchPLPage | ❌ Not routed |
| `/reports/pl` | PLReportPage | ❌ Not routed |
| `/reports/credit` | CreditReportPage | ❌ Not routed |
| `/reports/overdue` | OverdueCustomersPage | ❌ Not routed |
| `/reports/partner/:id` | PartnerReportPage | ❌ Not routed |
| `/reports/market-performance` | MarketPerformancePage | ❌ Not routed |
| `/transactions/settle` | PartnerSettlementPage | ❌ Not routed |
| `/transactions/partner/:id` | PartnerBalancePage | ❌ Not routed |
| `/settings/business` | BusinessSettingsPage | ❌ Not routed |
| `/settings/access` | AccessManagementPage | ❌ Not routed |
| `/settings/profile` | ProfilePage | ❌ Not routed |
| `/partners/:id` | PartnerProfilePage | ❌ Not routed |

Also missing: `/` (splash screen / auto-login check).

---

## 4. FEATURE TICKET GAPS (by Ticket)

### Sprint 1: Foundation (GM-017 to GM-025)
| Ticket | Title | Status |
|--------|-------|--------|
| GM-020 | Drift schema for local cache tables | ❌ Stub only (empty `AppDatabase`) |
| GM-023 | Core widgets: GreenCard, AmountText, StatusPill, PartnerChip | ✅ Implemented |
| GM-025 | connectivity_plus and offline sync queue logic | ❌ Stub only (`SyncRepository.processQueue()` is no-op) |

### Sprint 2: Auth & Partners (GM-028 to GM-041)
| Ticket | Title | Status |
|--------|-------|--------|
| GM-030 | Onboarding flow: create business | ✅ Implemented (basic) |
| GM-040 | Partner Profile screen | ❌ Not implemented |

### Sprint 3: Batch & Expenses (GM-042 to GM-065)
| Ticket | Title | Status |
|--------|-------|--------|
| GM-045 | Wizard Step 1: Product + Purchase | ❌ Simple form instead of wizard |
| GM-046 | Wizard Step 2: Purchasing partners | ❌ Not implemented |
| GM-047 | Wizard Step 3: Packing entry | ❌ Not implemented |
| GM-048 | Wizard Step 4: Purchaser expenses | ❌ Not implemented |
| GM-049 | Wizard Step 5: Review + confirm | ❌ Not implemented |
| GM-052 | Batch List (filter by status, product, city) | ⚠️ Basic list, no filters |
| GM-053 | Batch Detail with 5 tabs | ⚠️ 4 tabs only (Overview, P&L, Expenses, Sales) |
| GM-055 | Status action button logic | ⚠️ Simple "Advance Status" without visual timeline |
| GM-062 | Add Expense bottom sheet | ❌ No bottom sheet; expenses listed inline |
| GM-064 | Packing Tab | ❌ Missing from batch detail tabs |
| GM-065 | Transport toggle visual distinction | ❌ Not implemented |

### Sprint 4: Sales & Customers (GM-066 to GM-082)
| Ticket | Title | Status |
|--------|-------|--------|
| GM-069 | Quick Sale Entry | ✅ Implemented |
| GM-071 | Cash/Credit/Part-Credit payment mode | ✅ Implemented |
| GM-072 | All Sales screen (filterable) | ⚠️ Basic list, no date/product/customer filters |
| GM-078 | Customer List with outstanding balance | ⚠️ Shows balance but no soft-delete/swipe |

### Sprint 5: P&L & Reports (GM-083 to GM-101)
| Ticket | Title | Status |
|--------|-------|--------|
| GM-088 | Batch P&L screen (full breakdown) | ⚠️ Basic inline P&L, no cost breakdown details |
| GM-089 | Business P&L Report with bar chart | ❌ No fl_chart bar chart implemented |
| GM-090 | Partner P&L Report | ❌ Not implemented |
| GM-091 | fl_chart bar chart implementation | ❌ Not implemented |
| GM-095 | Reports Hub | ⚠️ Single hub page, no navigation to dedicated report pages |
| GM-097 | Date range picker (reusable) | ❌ Not implemented |
| GM-099 | Market Management screen | ✅ Implemented |

### Sprint 6: Transactions & Security (GM-102 to GM-116)
| Ticket | Title | Status |
|--------|-------|--------|
| GM-104 | Partner Settlement screen | ⚠️ Dialog-based, no dedicated page |
| GM-105 | Partner Balance screen | ⚠️ Bottom sheet, no dedicated page |
| GM-106 | Dashboard: Total Market Balance | ❌ Not implemented |

### Cross-Sprint Missing
| Feature | Priority | Notes |
|---------|----------|-------|
| Offline sync queue | P1 | Entirely missing |
| Local database (Drift) | P0 | Only a stub |
| Soft-delete UI (customers, batches, expenses) | P1 | Not implemented |
| Expense edit/delete swipe | P1 | Not implemented |
| Batch delete | P1 | Not implemented |
| Customer delete | P1 | Not implemented |
| Role-based UI restrictions | P1 | No viewer/editor/accountant guards in UI |
| Export PDF/CSV UI | P1 | Repository methods exist but no UI triggers |
| Share report | P1 | `share_plus` in pubspec but not wired up |
| Reusable date range picker | P1 | Not implemented |
| Responsive breakpoints | P2 | Not implemented |
| Urdu/RTL localization (l10n) | P3 | Not implemented |
| Fl_chart bar charts | P1 | Dependency exists but not used |

---

## 5. MISSING DEPENDENCIES (pubspec.yaml vs Plan)

| Dependency | In Plan | In pubspec | Notes |
|-----------|---------|------------|-------|
| `flutter_riverpod` | ✅ | ✅ | |
| `go_router` | ✅ | ✅ | |
| `drift` | ✅ | ❌ | Local SQLite cache |
| `sqlite3_flutter_libs` | ✅ | ❌ | SQLite native libs |
| `dio` | ✅ | ✅ | |
| `fl_chart` | ✅ | ✅ | Not used yet |
| `intl` | ✅ | ✅ | |
| `flutter_secure_storage` | ✅ | ✅ | |
| `path_provider` | ✅ | ✅ | |
| `share_plus` | ✅ | ✅ | Not wired to UI |
| `connectivity_plus` | ✅ | ✅ | |
| `cached_network_image` | ✅ | ❌ | Profile images |
| `flutter_dotenv` | ❌ (plan uses `.env` via other means) | ✅ | Extra |
| `google_fonts` | ❌ | ✅ | Extra |
| `shimmer` | ❌ | ✅ | Extra |
| `flutter_lints` | ✅ | ✅ | |

---

## 6. KEY QUALITY GAPS

1. **No local caching** — All data is fetched fresh from API on every page load
2. **No offline mode** — App breaks without internet connectivity
3. **No role-based UI restrictions** — Viewer/editor/accountant access levels not enforced in UI
4. **No rate-limit handling** — 429 responses not handled gracefully
5. **No responsive layout** — All pages assume mobile portrait
6. **Splash/auto-login screen** — No splash route; login page is initial route
7. **Partner Profile page missing** — No way to view partner details or financial summary

---

## 7. PRIORITIZED REMAINING WORK

### P0 — Must-Have (Core Functionality)
| Task | Tickets |
|------|---------|
| Build 5-step Batch Creation Wizard | GM-045 to GM-049 |
| Build Packing Tab in Batch Detail | GM-064 |
| Add expense/sale bottom sheets | GM-062 |
| Build Partner Profile page (`/partners/:id`) | GM-040 |
| Add local Drift database + schema | GM-020 |
| Implement offline sync queue | GM-025 |

### P1 — Important (Completeness)
| Task | Tickets |
|------|---------|
| Status timeline widget | GM-055 |
| Batch P&L dedicated screen with cost breakdown | GM-088 |
| Reports: dedicated pages for PL/Credit/Overdue | GM-095 |
| Business settings, profile, access management pages | GM-030, GM-041 |
| Role-based UI restrictions | Sprint 2 |
| Soft-delete UI (customers, batches, expenses) | GM-116 |
| P&L bar charts (fl_chart) | GM-091 |
| Date range picker component | GM-097 |
| Partner settlement + balance as full pages | GM-104, GM-105 |

### P2 — Enhancement
| Task | Tickets |
|------|---------|
| Market performance report | GM-101 |
| Export PDF/CSV with share_plus | GM-096 |
| Responseive layout (tablet/web) | — |
| Overdue banner widget | — |
| Rate-limiter handler | GM-112 |

### P3 — Future
| Task | Tickets |
|------|---------|
| Urdu/RTL localization | — |

---

## 8. COMPLETED FEATURES (ACKNOWLEDGED)

The following are **fully or substantially implemented** and match the plan:

- User authentication (email+password login/signup) ✅
- Onboarding / business creation ✅
- Dashboard with stat cards + recent activity ✅
- Batch list (basic) ✅
- Batch detail (4 tabs: Overview, P&L, Expenses, Sales) ⚠️
- Product list + creation ✅
- Quick sale entry with payment modes ✅
- Customer list, ledger, payment recording ✅
- Partner list + search + creation ✅
- Market list + creation ✅
- Reports hub (P&L summary + overdue alerts) ⚠️
- Transaction list (settlement dialog + partner ledger bottom sheet) ⚠️
- Settings (user profile + sign out) ✅
- Design system (theme, colors, typography, 16 reusable widgets) ✅
- Core networking (Dio, auth interceptor, error interceptor, connectivity) ✅
- All 11 remote datasources + 11 repositories ✅
- 12 Riverpod providers ✅
- Environment variable support via flutter_dotenv ✅
