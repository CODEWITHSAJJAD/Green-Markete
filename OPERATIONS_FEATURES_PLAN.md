# Green Market — Operations Features: Requirements Map & Implementation Plan

**Repo:** `C:\Users\SUQOON\OneDrive\Desktop\GreenMarket\frontend\green_market\`
**Scope:** Frontend only (`green_market/`). Backend (FastAPI/Supabase) is a separate repo — any schema work needed is listed as a **backend prerequisite** for that repo only.
**Guardrails:** The app must never stop working. Every access to a possibly-absent table is defensive (probe → graceful degradation), matching the pattern proven in Phases 3–6. `flutter analyze` must stay clean and `flutter test` green after every phase. Commit per phase with a `project_state.md` update.

---

## 1. The business flow (as understood)

1. **Purchaser** buys product from a **supplier** at a source market — on **cash or debt** (supplier payable).
2. Product moves to the **seller**; transport is by shared **vehicles** that can carry loads for one or more products (packing counts can be split across vehicles). Transport cost is either **per packing unit** or **per whole vehicle**.
3. The seller **packs** the product. Packing materials (bags/crates) are sometimes **reusable** — bought once, used on many batches; empty bags are **returned to the purchaser parts**, often by the **same vehicle**.
4. Once received, the seller pays **extra expenses** (labor, local transport, commission per packed unit, stall rent, etc.).
5. The seller sells:
   - **POS mode (Sales tab):** individual sale entry per customer (cash / credit / partial / bank), or
   - **Day-end manual mode:** enter total units/packages sold → remaining auto-calculated → enter expenses paid out of the sale → enter cash in hand after expenses → enter credit sold → the app computes P&L.
6. P&L is recomputed at any point, and again when the batch is fully sold.
7. **Credit** is tracked **per batch** (which customers owe for which batch) and **across the whole business** (total receivables), with full customer credit history.
8. A person may own **multiple businesses** and share **customers** (and vehicles) between them, avoiding duplicate customer creation.

---

## 2. Requirement → status map (verified against the code)

| # | Requirement | Status | Where / Notes |
|---|-------------|--------|---------------|
| R1 | Purchaser buys from supplier on cash or debt | **Partial** | `BatchModel` has `supplierName` (free text), `purchasePaymentMode`, `purchaseAmountPaid` (`batch_model.dart`). No supplier registry, no supplier-debt ledger, no supplier payments. |
| R2 | Seller-side packing | **Done** | `packing_records`; wizard step 3; Packing tab + FAB. |
| R3 | Reusable packing materials (bought once, reused) | **Missing** | No packing-material inventory/reuse concept. Live probe: `packing_materials` 404. |
| R4 | Empty bags returned to purchaser parts with the same vehicle | **Partial** | `packing_returns` done (Phase 4) but no vehicle link and no return-to-partner on the return row. |
| R5 | Vehicle involved in purchaser→seller delivery | **Done** | `batch_vehicles` (Phase 3): Transport tab + wizard step; join to `vehicles(plate_number, driver_name)`. |
| R6 | Vehicles shared / loads split across vehicles | **Partial** | Split one product's packing across vehicles = done (per-batch). Cross-batch sharing in one trip = missing (vehicle loads are per-batch only). |
| R7 | Transport cost per-packing or whole-vehicle | **Done** | `cost_type` ∈ `per_packing`/`per_vehicle` on `batch_vehicles` (`totalCost` getter). |
| R8 | Supplier debt/cash + payments to supplier | **Missing** | Computable client-side from existing batch fields; no registry/ledger. Probe: `suppliers` 404. |
| R9 | Seller extra expenses (labor, local transport, commission, stall rent) | **Done** | `expenses.expense_side` (purchaser/seller/transport); `ExpenseEntrySheet`; seller expenses already feed P&L and Phase 5 settlements. Expense types are free-text (structured presets can be added). |
| R10 | Day-end manual mode (totals → remaining → expenses → cash in hand → credit → P&L) | **Missing** | No day-end summary anywhere. Probes: `batch_day_summaries` / `batch_day_entries` 404. |
| R11 | POS direct sale entry | **Done** | `sale_entry_sheet.dart`: cash/credit/partial-credit/bank; qty ≤ remaining validated; per-customer credit. |
| R12 | Remaining auto-calculated after sales | **Done** | Overview "Sold X / Remaining Y" + progress bar; `soldQuantity` folded from `SaleProvider.sales`. |
| R13 | P&L recomputed anytime + when fully sold | **Done** | `get_batch_pl` RPC → P&L tab + `BatchPLDetailModel` (purchase, daily charges, packing, transport, seller expenses, cash vs credit revenue). |
| R14 | Credit tracked per batch | **Missing** | `sales.credit_amount` exists, but no per-batch credit view / collection tracking. **Live probe: `customer_payments.batch_id` column EXISTS** — payments can be attributed per batch. |
| R15 | Credit tracked whole business | **Done** | `credit_report_page.dart` (aggregate outstanding), dashboard outstanding-credit card, overdue report. |
| R16 | Customer credit history | **Done** | `customer_ledger_page.dart` running balance from sales + payments. |
| R17 | Shared customers across businesses (avoid duplicates) | **Partial (defensive)** | Phase 6: `listSharedCustomerIds` probes `customer_shares`, degrades to no-op. Real sharing needs a backend table. |
| R18 | Shared vehicles across businesses | **Missing** | Vehicles are per-business. Probe: `vehicle_shares` 404. |

**Net:** R2, R5, R7, R9, R11, R12, R13, R15, R16 are done. R1/R4/R6/R17 are partial. **R3, R8, R10, R14, R18 are the real gaps** — R10 (day-end) and R14 (per-batch credit) are the highest-value.

---

## 3. Live-schema probe facts (2026-08-09)

- `batch_vehicles` (id, batch_id, vehicle_id, packing_record_id, unit_count, cost_type, transport_cost, load_date, notes) — exists.
- `packing_returns` (id, batch_id, packing_record_id, quantity, count, return_date, notes) + join `packing_records(unit_type_label, cost_per_unit)` — exists (no `unit_label`, no `vehicle_id`).
- `customer_payments` — **has `batch_id`** (select probe 200, empty) → per-batch credit/collection is natively supported.
- `batch_day_summaries`, `batch_day_entries`, `suppliers`, `packing_materials`, `vehicle_shares` — **all 404**. Day-end, suppliers, reusable packing, and cross-business sharing therefore have NO live table yet → every new-phase access must be defensive.
- `partner_transactions` has no `batch_id`; settlements are matched by `notes`/`reference` containing the batch code (Phase 5 pattern — reuse for any cross-table matching).

---

## 4. Phased implementation plan (frontend-first, app never breaks)

Each phase: new files → repo/provider/page wiring → `flutter analyze` + `flutter test` → `project_state.md` update + commit. Any feature whose live table is absent ships as a **hidden/disabled UI** (probe at runtime, degrade silently) exactly like Phase 6.

### Phase 7 — Day-End "Cash & Credit Close" (R10, R12) — highest value
**Goal:** a "Day End" entry on the Sales tab letting the seller close the day manually: enter units/packages sold → remaining auto-calculated → record expenses paid out of the sale → cash in hand after expenses → credit sold → P&L shown.

**Mechanism (no new table needed):** the day-end sheet submits ordinary, existing rows so the backend P&L keeps working untouched:
- 1 aggregated `sales` row for the day (`quantity_sold` = total units, `payment_mode='cash'`, `cash_received` = cash in hand, note "Day-end summary {date}"), plus
- 1 `sales` row (`payment_mode='credit'`) per credit customer (or one walk-in credit total if not split), plus
- N `expenses` rows (`expense_side='seller'`) for expenses paid from the sale (labor, local transport, commission, stall rent), plus
- a client-side preview: `gross = cash in hand + credit + expenses paid from sale`, `remaining = totalQuantity − Σ quantity_sold`, live P&L vs the last `get_batch_pl`.
- `_remaining` guard: refuse to save if units sold > remaining.

**Files:** `lib/presentation/widgets/day_end_entry_sheet.dart` (new), `sale_repository.dart`/`expense_repository.dart` (reuse existing create), `batch_detail_page.dart` `_salesTab` gets a "Day End" button + a date-grouped summary card listing day summaries derived from sales+expenses.

**Backend prerequisite (optional, future):** a real `batch_day_summaries` table so day-end records are first-class instead of synthesized rows. Until then the synthesized approach is the source of truth and is fully functional.

### Phase 8 — Per-batch credit & collection (R14) — highest value
**Goal:** owner can see, per batch, which customers owe credit and how much is still collectable, and record collections against that batch; plus a whole-business "credit by batch" report.

**Mechanism (live-schema supported):**
- Per-batch outstanding = `Σ sales.credit_amount (batch_id)` − `Σ customer_payments.amount (batch_id)` — both columns exist.
- New **Credit** section on the batch detail (list of credit customers + outstanding) and a "Collect Credit" action that records a `customer_payments` row **with `batch_id` set** (falls back to notes-matching the batch code if a column probe fails).
- Reports hub gains a **Credit by Batch** card (each batch's outstanding receivables, sortable, with "go to batch" navigation).

**Files:** `data/repositories/sale_repository.dart` + `customer_repository.dart` (credit aggregation queries), `batch_detail_page.dart` (Credit section/tab), `reports/credit_by_batch_page.dart` (new), report provider wiring.

**Backend prerequisite:** none — confirmed live columns.

### Phase 9 — Suppliers & supplier debt (R1, R8)
**Mechanism (frontend-computable first):**
- Batch wizard purchase step exposes the **already-modeled** `purchase_payment_mode` (cash/debt) + `purchase_amount_paid` fields (today they exist in the model but have no wizard UI).
- New "Supplier payables" view derived from batches: per supplier name, `payable = Σ(total_purchase_cost − purchase_amount_paid)` where mode is debt — pure client-side aggregation, no new table.
- **Defensive registry:** probe `suppliers`; if the table is added later, a supplier list/create page activates automatically (mirrors Phase 6 pattern). Until then, free-text supplier names on batches remain.

**Files:** `create_batch_wizard.dart` (payment-mode step), new supplier-payables report, `supplier_provider.dart` + `suppliers/supplier_list_page.dart` + `create_supplier_page.dart` (built behind the defensive probe).

### Phase 10 — Reusable packing & return-vehicle link (R3, R4)
- `packing_returns` gains an optional `vehicle_id` (which vehicle brought empties back) + display of the vehicle plate on the Returns tab (probe column; degrade silently if absent).
- **Defensive packing-materials inventory:** probe `packing_materials`; if present, a "Packing Materials" page (name, unit, cost, qty owned, reusable flag) + link a `material_id` on packing records. Until the table exists the feature is hidden; the current per-batch packing cost model is unchanged.

**Files:** `packing_return_model.dart`/`batch_repository.dart` (vehicle_id), `packing_material_model.dart` + `packing_materials/` pages (behind probe).

### Phase 11 — Cross-business sharing (R6, R17, R18) — backend-gated
- **Customers:** Phase 6 indicator is in. When a `customer_shares` table appears, add a "Share with business" dialog on the customer page (pick another business you own) that inserts into the table. Until then: hidden.
- **Vehicles:** same pattern (`vehicle_shares`), plus a "loads from multiple batches in one trip" entry on Transport if the backend adds a trip concept.
- These are documented backend prerequisites; frontend work only begins after the tables exist (or the defensive probes are kept and the UI stays hidden).

---

## 5. Guardrails (keeps the app working while features land)

1. Every new/uncertain table access wraps in `try/catch (PostgrestException)` and degrades to a non-breaking default (empty list, hidden button, "not available" state) — never a crash, never a full-screen error. (Proven: Phase 6, `listSharedCustomerIds`.)
2. Backend P&L stays authoritative; day-end synthesizes standard `sales`/`expenses` rows so `get_batch_pl` keeps working with zero backend change.
3. New pages navigate via `Navigator.push(MaterialPageRoute(...))` (no go_router/routes.dart in this app) and new providers register in `main.dart`'s `MultiProvider` (or are reused — Phase 5 reused `TransactionProvider`/`PartnerProvider`).
4. No codegen, no freezed/json_serializable; models stay hand-written with snake_case + camelCase fallbacks.
5. `flutter analyze` must stay clean and `flutter test` green after each phase; each phase commits separately with a `project_state.md` entry.
6. Client-side matching across tables uses the proven Phase 5 pattern (match `notes`/`reference` to the batch code) only when a real FK column is absent.

---

## 6. Decision points

1. **Day-end credit split:** record credit as one total, or require per-customer credit lines in the day-end sheet? (Per-customer is needed for R14 credit-by-customer; recommend per-customer optional, walk-in total fallback.)
2. **Supplier registry now vs later:** build the defensive supplier registry UI immediately (hidden until table exists) or only the client-side payables report? (Recommend report now, registry later — less dead code.)
3. **Reusable packing accounting:** should reusable material cost be amortized per reuse (e.g., cost ÷ expected reuses) or just tracked as inventory purchases? (Recommend inventory-tracking only in V1; amortization is complex.)
4. **Phase order:** recommend 7 → 8 → 9 → 10 → 11. Confirm before execution.
