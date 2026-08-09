# Green Market — Flutter Frontend

Vegetable import/export & wholesale management app. **Purchaser** buys from **suppliers** at source markets (cash/debt), ships to a **seller** via shared **vehicles** (packing loads split across vehicles, transport cost per-packing or per-vehicle), the seller **packs** (often with reusable bags that return with the vehicle), pays **expenses** (labor, local transport, commission, stall rent), then **sells** — either POS-style per customer or a **day-end manual summary** — and tracks **credit per batch and per business** with full customer credit history and live batch P&L.

> **Agents: start by reading `../../frontend/project_state.md`** (session log, feature status, environment quirks) and `../../frontend/AGENTS.md` (hard rules). This README is the project map; `OPERATIONS_FEATURES_PLAN.md` is the requirements map + roadmap.

## Repo layout

```
frontend/                 ← git repo root
├── project_state.md      ← REQUIRED first read: session log + live status (the source of truth)
├── AGENTS.md             ← hard rules (scope, commit discipline, conventions)
└── green_market/         ← the Flutter app
    ├── README.md         ← this file
    ├── OPERATIONS_FEATURES_PLAN.md  ← requirements map + phased roadmap
    ├── gap_analysis.md   ← older gap inventory (partly stale)
    └── lib/
        ├── core/         ← config, supabase service, utils, error, export
        ├── data/         ← models (hand-written), repositories, datasources
        ├── domain/       ← entities + usecases (thin)
        └── presentation/ ← pages, providers (Provider 6.x ChangeNotifier), widgets
```

## Commands (run from `green_market/`)

- `flutter analyze` — must stay clean (0 errors; a few info-level lints acceptable)
- `flutter test` — only `test/widget_test.dart` exists
- `flutter run` — uses `.env`; live backend is Supabase (`hvtgzyucgymuixfbdece`), not the local FastAPI
- `flutter pub get` — after dependency changes

## Architecture & conventions

- **Clean architecture**, one folder per layer under `lib/`. Data flow: Page → provider (ChangeNotifier) → Repository → `SupabaseClient`.
- **State:** `provider` 6.x `ChangeNotifier` + `ChangeNotifierProvider`; one provider per feature in `lib/presentation/providers/`. `supabase_flutter` handles auth/session.
- **No codegen.** Models are hand-written plain classes; JSON is **snake_case** (`business_id`) with defensive camelCase fallbacks. Never introduce freezed/json_serializable/build_runner.
- **Supabase envelope:** responses are raw rows (no `data` wrapper). Read with defensive casts (`as num?)?.toDouble()`); never assume a column exists.
- **Defensive live-schema pattern (IMPORTANT):** the live DB is ahead of the docs and may lack columns/tables the original spec assumed (e.g., `customers.is_archived`, `customer_shares`, day-end tables). Every access to a possibly-absent column/table is wrapped: probe → `catch (PostgrestException)` → degrade to a non-breaking default (empty list, hidden button). See `CustomerRepository.list` (42703 fallback) and `listSharedCustomerIds`.
- **Cross-table matching:** where a real FK column is absent (e.g., `partner_transactions.batch_id`), match rows by `notes`/`reference` containing the `batch_code` (Phase 5 pattern).
- **Backend P&L is authoritative:** `get_batch_pl` RPC. Day-end entries must be synthesized as ordinary `sales`/`expenses` rows so P&L keeps working.
- **Currency/dates:** `core/utils/currency_formatter.dart` (`CurrencyFormatter.currentCode`, multi-currency), `date_formatter.dart`. Reuse shared widgets in `presentation/widgets/` (GreenCard, AmountText, StatusPill, EmptyState, ConfirmDialog, SaleEntrySheet, ExpenseEntrySheet…).
- **Routing:** plain `Navigator.push` behind an `AuthNavigator` host (`pages/auth/auth_navigator.dart`); 5-tab bottom nav in `main_shell.dart`. No go_router, no `routes.dart`.
- **Backend is OUT OF SCOPE:** never read/edit the FastAPI/backend repo. Schema needs are documented as "backend prerequisites" in the plan.

## Feature status

| Area | Status |
|------|--------|
| Auth (email signup/login, multi-business, onboarding) | Done |
| Dashboard, batch list/wizard/detail (Overview·Packing·Expenses·Transport·Sales·Returns·Settlements·P&L = 8 tabs) | Done |
| Vehicles CRUD + transport loads (split across vehicles, per-packing/per-vehicle cost) | Done |
| Packing records + packing returns | Done |
| Partners, products, markets, customers (list/create/ledger/payments) | Done |
| Reports (P&L, credit, overdue, market perf, partner P&L) + CSV export | Done |
| Settlements (Phase 5) + shared-customers indicator (Phase 6) | Done |
| **Day-end manual summary, per-batch credit, suppliers, reusable packing** | **Planned — see `OPERATIONS_FEATURES_PLAN.md` Phase 7–11** |

## Docs index

- `../../frontend/project_state.md` — session log + live status (read first)
- `../../frontend/AGENTS.md` — hard rules
- `OPERATIONS_FEATURES_PLAN.md` — requirements map (R1–R18) + phased roadmap
- `gap_analysis.md` — older inventory (partially stale; trust `project_state.md` + code)
- `01_PRD.md` / `02_Technical_Architecture.md` — original spec (live DB is ahead)
