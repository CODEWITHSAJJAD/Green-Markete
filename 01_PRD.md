# 📋 Product Requirements Document (PRD)
## Green Market — Vegetable Trading & Partner Management Platform

**Version:** 2.1 (Operations Features) — Supersedes 2.0
**Date:** August 2026
**Status:** Final Draft

> **Version 2.1 — Operations features added:** supplier purchases on cash/debt + supplier payables, reusable packing materials, empty-bag returns to the purchaser parts with the same vehicle, vehicle & transport management (shared vehicles, loads split across vehicles, per-packing vs per-vehicle cost), seller **day-end manual sale close** (POS **or** totals-based entry with remaining auto-calculated), per-batch credit + whole-business credit-by-batch, commission / stall-rent expense types, and shared customers/vehicles across businesses owned by one person. Frontend requirements map + roadmap: `OPERATIONS_FEATURES_PLAN.md` (R1–R18, Phases 7–11). Live-schema drift from this 2.0 baseline is tracked in `project_state.md`.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Business Model Deep-Dive](#2-business-model-deep-dive)
3. [User Roles & Access](#3-user-roles--access)
4. [The Cost Chain](#4-the-cost-chain)
5. [Feature Requirements](#5-feature-requirements)
6. [Business Rules & Edge Cases](#6-business-rules--edge-cases)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [Out of Scope — V1](#8-out-of-scope--v1)

---

## 1. Executive Summary

Green Market is a **standalone Flutter mobile application** backed directly by **Supabase** (PostgreSQL + Auth + Realtime). It serves vegetable traders operating an import/export chain where multiple partners collaborate across cities — one or more partners buy product, accumulate costs, pack, and ship to a destination where another partner (or the same person) sells and tracks revenue.

The app handles the complete financial lifecycle of every product batch: purchase cost, layered expenses on both the buyer and seller side, packing, transport, sale proceeds, customer credit, and partner settlements — all leading to a clear **profit/loss** figure per batch and across the business.

---

## 2. Business Model Deep-Dive

### 2.1 The Trading Chain

```
SOURCE MARKET (City A)
        │
        ▼
[PURCHASER(S)] — buy vegetables from SUPPLIER
        │          (cash OR on debt — supplier payable)
        ├── Add: daily charges (per partner, per day)
        ├── Add: labor cost
        ├── Add: accountant/admin charges
        ├── Add: source stall fee
        ├── Add: miscellaneous expenses
        └── Pack into units (5kg packets / 100kg bags / custom)
              │           using REUSABLE packing materials
              │           (bags/packets tracked as assets,
              │            empty bags RETURNED to the purchaser
              │            parts by the same vehicle)
              │
              └── Add: packing cost per unit type
                        │
                        ▼
              [TRANSPORT] ← paid by purchaser OR seller (one side)
              shared vehicle / loads split across vehicles /
              per-vehicle cost_type (fuel/driver/toll/commission)
                        │
                        ▼
        DESTINATION MARKET (City A or B)
                        │
                        ▼
[SELLER] — receives packed product
        │
        ├── Add: daily charges
        ├── Add: labor cost (unloading, stall setup)
        ├── Add: local vehicle transport (vehicle to stall)
        ├── Add: destination stall fee
        ├── Add: seller commission (per packed unit)
        └── Add: miscellaneous expenses
                        │
                        ▼
        SELL to customers — TWO MODES
        ├── MODE A (live POS): cash / credit / mixed per sale
        ├── MODE B (day-end manual): enter total cash received +
        │   per-credit-customer amounts; remaining = REMAINING
        │   AMOUNT (auto-calculated)
        └── Credit sales tracked per batch AND per customer
                        │
                        ▼
        NET REVENUE vs TOTAL COST = PROFIT / LOSS
        (recalculated whenever any sale/expense/payment is edited)
```

### 2.2 Who Runs the Business?

| Scenario | How It Works |
|----------|-------------|
| **Single Owner** | One person handles both purchase AND sale. They have editor access on all sides of every batch. |
| **Two-Partner** | Partner A buys (purchaser). Partner B sells (seller). Each manages their own side. Both can view everything. |
| **Multi-Purchaser** | Two or more partners buy the same batch together. Each adds their own daily charges and costs. |
| **Seller in Multiple Cities** | One seller receives product from multiple purchasers across multiple cities simultaneously. Each batch is tracked separately. |
| **Unclaimed Profile** | Partner A creates Partner B's profile. Partner B hasn't signed up yet. Partner A manages both sides until Partner B claims the profile with the same phone number. |

### 2.3 Market Structure

A **Market** is a physical location where product is bought or sold. Each market belongs to a **City**. A business can have markets in many cities. Each product batch has:
- One **source market** (where it was purchased)
- One **destination market** (where it will be sold)

These can be the same market (same city, different stalls) or entirely different cities.

---

## 3. User Roles & Access

### 3.1 Roles

| Role | Who | What They Can Do |
|------|-----|-----------------|
| `owner` | Business creator / single operator | Full read + write on everything in their business |
| `editor_partner` | Active partner who has claimed their profile | Read + write on batches they are assigned to |
| `viewer_partner` | Partner with view-only access | Read-only on their assigned batches and financials |
| `accountant` | Books person | Read-only on all financials; can add expense entries only |

### 3.2 The Claimed vs Unclaimed Profile Rule

- **Unclaimed profile**: Created by another partner. No one has logged in with this phone yet. The creating partner has **editor access over both sides** of any batch that involves this profile.
- **Claimed profile**: The partner signs up with the same phone number → the system links to the existing profile → partner gains their own login → the creator retains **viewer access** to shared batch data.
- **Result**: After claiming, both partners see the same batch from their own perspective. Neither can edit the other's profile.

### 3.3 What Each Role Sees

| Data | Owner | Editor Partner | Viewer Partner | Accountant |
|------|:-----:|:--------------:|:--------------:|:----------:|
| Own profile | ✅ edit | ✅ edit | ✅ edit | ✅ edit |
| All batches in business | ✅ | ❌ (own only) | ❌ (own only) | ✅ read |
| Create batch | ✅ | ✅ | ❌ | ❌ |
| Add expenses | ✅ | ✅ (own batches) | ❌ | ✅ |
| Record sale | ✅ | ✅ (seller role) | ❌ | ❌ |
| Record customer payment | ✅ | ✅ | ❌ | ❌ |
| View P&L | ✅ | ✅ (own batches) | ✅ (own batches) | ✅ |
| Manage markets | ✅ | ❌ | ❌ | ❌ |
| Manage partners | ✅ | ❌ | ❌ | ❌ |
| Export reports | ✅ | ✅ | ✅ | ✅ |

---

## 4. The Cost Chain

This is the formula that drives the entire application. Every feature exists to populate or display this chain.

### 4.1 Total Cost Calculation

```
TOTAL COST =
    Purchase Price (qty × price per unit)
  + Purchaser Daily Charges (Σ per co-purchaser: rate × days)
  + Purchaser Labor Cost
  + Accountant/Admin Cost
  + Source Stall Fee
  + Purchaser Miscellaneous
  + Packing Cost (Σ per unit type: count × cost per unit)
  + Transport Cost          ← always included in total cost
  + Seller Daily Charges (rate × days)
  + Seller Labor Cost
  + Local Transport Cost (vehicle to stall)
  + Destination Stall Fee
  + Seller Miscellaneous
```

### 4.2 Revenue & Profit

```
TOTAL REVENUE   = Σ (quantity sold × price per unit) across all sales
CASH RECEIVED   = Σ cash_received from all sales
CREDIT PENDING  = Σ credit_amount from all sales (customer owes this)

PROFIT / LOSS   = TOTAL REVENUE − TOTAL COST
```

### 4.3 Transport Attribution Rule

Transport is physically paid by one side (purchaser or seller). This is recorded per batch. The transport cost is **always included in total cost** regardless of who paid it. It also creates an **inter-partner debt** if the paying side is different from the attributed side (e.g., purchaser paid but it's seller's responsibility → seller owes purchaser).

### 4.4 Packing Cost Detail

A batch may be packed into multiple unit types simultaneously:
- 40 × 5kg packets @ PKR 15 each = PKR 600
- 10 × 100kg bags @ PKR 80 each = PKR 800
- Total packing cost = PKR 1,400

All packing costs roll into the purchaser side of total cost.

### 4.5 Supplier Payable (Purchase on Debt)

A batch purchase can be paid **cash** or **on debt**. When on debt, the app records a **supplier payable** for the unpaid portion. The payable is a liability (not part of the batch P&L), tracked per supplier and per batch, reduced by subsequent supplier payments. Supplier balances are computed client-side from `batches.purchase_amount_paid` (in `purchase_payment_mode='debt'`) — the app never exposes a cash balance stored in the DB.

### 4.6 Reusable Packing Materials

Packing materials (bags, packets, boxes) are **reusable assets**, tracked as a business-level inventory (`packing_materials` + per-batch usage records). At the destination, **empty bags are returned to the purchaser parts by the same vehicle that carried the load** — the return is recorded with a quantity, the purchaser partner, and the vehicle. Material cost is amortized per use (cost per use = material cost ÷ expected reuses). This keeps the batch P&L accurate without treating the full bag purchase as one batch's cost.

---

## 5. Feature Requirements

### 5.1 Authentication & Onboarding

**FR-AUTH-01** — Phone number + SMS OTP login (primary method).
**FR-AUTH-02** — Email + password as alternate login method.
**FR-AUTH-03** — On first login, show onboarding to create or join a business (enter business name, city, personal role).
**FR-AUTH-04** — Auto-link: if user signs up with phone that matches an existing unclaimed profile → profile is claimed, access granted.
**FR-AUTH-05** — Persist session with Supabase auto-refresh; user stays logged in across app restarts.
**FR-AUTH-06** — Secure logout clears all local state.

### 5.2 Partner & Profile Management

**FR-P-01** — Create partner profile: full name, phone, city, CNIC (optional), bank account (optional), role (purchaser / seller / both / accountant).
**FR-P-02** — Search partners by name or phone before creating (avoid duplicates).
**FR-P-03** — Mark profile as "unclaimed" if created by another user — show a badge in the UI.
**FR-P-04** — Owner can change any partner's access level (editor / viewer) at any time.
**FR-P-05** — Owner can view all partners in their business on a partner directory screen.
**FR-P-06** — Partner can view their own profile and edit personal details.
**FR-P-07** — Inter-partner balance: show how much one partner owes another (calculated from settlements and transport attributions).

### 5.3 Market & City Management

**FR-M-01** — Create a city entry (name).
**FR-M-02** — Create a market under a city (name, stall number, market type: wholesale / retail / both).
**FR-M-03** — List all markets by city.
**FR-M-04** — Markets are shared across all partners in the business.
**FR-M-05** — Owner manages markets; partners can only view.

### 5.4 Product Management

**FR-PR-01** — Create a product (name, category: tomato/onion/potato/other, base unit: kg/bag/packet/custom).
**FR-PR-02** — Products are shared across all batches in the business.
**FR-PR-03** — List products with search.

### 5.5 Product Batch — Core Flow

**FR-B-01** — Create a batch with: product, source market, destination market, purchase date, total quantity, quantity unit, purchase price per unit.
**FR-B-02** — Auto-generate batch code: `GM-YYYY-NNNN` (e.g., GM-2026-0042).
**FR-B-03** — Assign one or more purchasing partners to the batch, each with a daily charge rate (PKR/day) and number of days involved.
**FR-B-04** — Assign one selling partner to the batch (can be same person as purchaser in single-owner mode).
**FR-B-05** — Set transport: amount, paid by (purchaser / seller), transport mode (truck/van/other), origin city, destination city.
**FR-B-06** — Track batch status with a simple status stepper: `Purchased → Packed → In Transit → Delivered → Selling → Closed`.
**FR-B-07** — Status can only move forward. A closed batch is read-only — no more expenses or sales.
**FR-B-08** — Show "remaining quantity" on batch: total_quantity − quantity_already_sold.
**FR-B-09** — Filter batch list by: status, product, source city, destination city, purchaser, seller.
**FR-B-10** — Optional supplier purchase details on a batch: supplier name, purchase payment mode (`cash` / `debt`), amount paid (when on debt, the unpaid portion becomes a supplier payable — Section 4.5).
**FR-B-11** — Batch-level credit snapshot: total credit sold for the batch, cash collected on that credit, and outstanding per batch (aggregated from `customer_payments` by `batch_id`).
**FR-B-12** — Day-end manual close: a seller can enter "cash received total" + per-credit-customer amounts for the day; the **remaining amount is auto-calculated** and ordinary sales/expense rows are created from those totals (POS sales still supported — Section 5.8).

### 5.6 Packing

**FR-PK-01** — Add packing entries to a batch: unit type label (e.g., "5kg packet", "100kg bag", "25kg box"), count, cost per unit.
**FR-PK-02** — Multiple packing entry types allowed per batch.
**FR-PK-03** — Total packing cost = Σ (count × cost_per_unit) across all packing entries.
**FR-PK-04** — Packing entries can be added/edited until batch is closed.
**FR-PK-05** — Reusable packing materials (Section 4.6): a business-level material inventory (name, cost, expected reuses), selected when packing a batch instead of a free-text cost.
**FR-PK-06** — Empty-bag return: record the quantity of empty bags returned to the purchaser parts, the purchaser partner, and the **vehicle** that carried them back (reuses the vehicle/transport module, Section 5.14).

### 5.7 Expense Tracking

**FR-E-01** — Add expense to a batch with: expense side (purchaser / transport / seller), expense type, amount, description, who paid it, payment mode (cash / bank transfer), date.
**FR-E-02** — Purchaser expense types: `daily_charge`, `labor`, `accountant`, `source_stall_fee`, `misc`.
**FR-E-03** — Transport expense: amount, paid_by (purchaser_partner_id or seller_partner_id), mode.
**FR-E-04** — Seller expense types: `daily_charge`, `labor`, `local_transport`, `destination_stall_fee`, `commission_per_packed_unit`, `misc`.
**FR-E-05** — Daily charges auto-suggested: when adding a `daily_charge` expense, prefill `rate × days` from batch partner data.
**FR-E-06** — Expenses can be edited or soft-deleted (owner only) with an audit entry created on change.
**FR-E-07** — Expense list grouped by side: Purchaser | Transport | Seller — shown with subtotals per group.
**FR-E-08** — Day-end seller expense: a seller can add a one-line expense (e.g., stall rent paid at close) directly from the day-end close flow, stored as a normal seller-side expense.

### 5.8 Sales

**FR-S-01** — Record a sale on a batch: quantity sold, price per unit, date, customer (optional — walk-in if blank).
**FR-S-02** — Payment modes: Full Cash, Full Credit, Partial (enter cash received → credit = total − cash).
**FR-S-03** — Validate: quantity sold ≤ remaining quantity on batch.
**FR-S-04** — Multiple sales per batch (sold in installments over time).
**FR-S-05** — On credit sale: automatically create/update customer credit record.
**FR-S-06** — Show running totals on batch: total sold qty, total revenue, cash received, credit outstanding.
**FR-S-07** — Only seller partner (or owner) can record sales on a batch.
**FR-S-08** — Dual sale mode: **Mode A** — live POS sales (existing per-sale entry); **Mode B** — day-end manual: seller enters `cash received` total and per-credit-customer amounts, app creates one aggregated cash sale + one credit sale per customer.
**FR-S-09** — Remaining amount auto-calc: after day-end totals are entered, `remaining = total revenue − cash received − Σ credit per customer`, displayed live and validated ≥ 0 before save.
**FR-S-10** — Any day-end or POS edit re-runs the batch P&L automatically (via `get_batch_pl`).

### 5.9 Customer & Credit Management

**FR-C-01** — Create customer profile: name, phone, city, shop/stall name.
**FR-C-02** — Search customers by name or phone before creating.
**FR-C-03** — Customer ledger: chronological list of all purchases and payments with running credit balance.
**FR-C-04** — Record customer payment: amount, payment mode, date, notes — reduces outstanding balance.
**FR-C-05** — Dashboard alert: customers with credit balance above a set threshold (default PKR 50,000 — configurable in settings).
**FR-C-06** — Customer total outstanding shown on customer list (color-coded: green = zero, amber = moderate, red = high).
**FR-C-07** — Per-batch credit view: for each batch, show the credit sold to a customer and how much of it is still unpaid (from `customer_payments.batch_id`).
**FR-C-08** — Shared customers: a business owner with multiple businesses can see, in each business, customers shared with their other businesses (defensive probe of a `customer_shares` table; falls back to "no shared customers" when the backend table does not exist — Phase 11).

### 5.10 Profit & Loss

**FR-PL-01** — Per-batch P&L screen showing the full cost chain (as specified in Section 4.1) with each line item.
**FR-PL-02** — P&L computed via Supabase RPC function `get_batch_pl(batch_id)` — not client-side calculation.
**FR-PL-03** — Business-level P&L: aggregate across all batches in a date range.
**FR-PL-04** — Partner-level contribution view: for a batch, show each co-purchaser's individual expenses (daily charges + portion of shared costs).
**FR-PL-05** — Partial batch P&L: clearly labeled as "in progress" when batch is not fully sold.
**FR-PL-06** — Export batch P&L as PDF using Flutter's `printing` package (device share sheet).

### 5.11 Partner Transactions & Settlements

**FR-T-01** — Record an inter-partner settlement: from partner, to partner, amount, payment mode (cash/bank), date, notes.
**FR-T-02** — Partner balance screen: for each partner pair, show net balance (who owes whom).
**FR-T-03** — Transport-derived debt: if purchaser paid transport but seller is responsible, auto-create a "transport debt" record from seller to purchaser.
**FR-T-04** — All transactions listed chronologically per partner pair.

### 5.12 Dashboard

**FR-D-01** — Summary cards: Today's Sales (PKR), Active Batches (count), Outstanding Customer Credit (PKR), Net P&L This Month.
**FR-D-02** — Active batches list (top 5, sorted by most recent activity).
**FR-D-03** — Credit alert list: customers with balance > threshold.
**FR-D-04** — Quick actions: + New Batch, + New Sale, + Record Payment.
**FR-D-05** — Figures are scoped to what the logged-in partner is associated with (owner sees all; partner sees their batches only).

### 5.13 Supplier Management

**FR-SUP-01** — Supplier registry: name, phone, market/city, notes. Supplier registry is a **Phase 9** item; until the backend table exists, supplier details are captured as free-text fields on the batch (FR-B-10).
**FR-SUP-02** — Supplier payable list: for each supplier, outstanding = Σ (purchase price − `purchase_amount_paid`) across open `debt` purchases. Computed client-side from batch rows (no stored balance).
**FR-SUP-03** — Record supplier payment: amount, payment mode, date; reduces that batch's supplier payable.
**FR-SUP-04** — Payables are visible to owner/editor; not part of batch P&L.

### 5.14 Vehicles, Transport & Cross-Business Sharing

**FR-V-01** — Vehicle registry: plate/name, capacity (bags/units), type. Vehicles are business-level resources.
**FR-V-02** — Assign a vehicle to a batch transport; record loads as **split across vehicles** (each vehicle carries a subset of the batch with its own cost and `cost_type`: fuel / driver / toll / commission).
**FR-V-03** — Empty-bag returns reuse the vehicle that carried the load (FR-PK-06).
**FR-V-04** — **Shared vehicles**: a business owner with multiple businesses can reuse one vehicle across businesses (Phase 11, backend-gated like customers).
**FR-V-05** — Transport remains attributed by `paid_by` (purchaser/seller) per Section 4.3; the per-vehicle breakdown is informational and rolls into total transport cost.

---

## 6. Business Rules & Edge Cases

### Rule 1 — Batch Closure
A batch in `Closed` status is fully read-only. No expenses, sales, or packing entries can be added. Only viewing is allowed.

### Rule 2 — Transport as Shared Cost
Transport is always counted in the total batch cost regardless of who physically paid it. The "paid by" field determines inter-partner debt only, not whether it's included in P&L.

### Rule 3 — Unclaimed Profile Access
Until a profile is claimed, the creator has full editor access over that profile's side of any shared batch. After claiming, the creator retains viewer access to shared batches only.

### Rule 4 — Partial P&L
If a batch has expenses but no sales yet: P&L = 0 − Total Cost (shows as a loss in progress). If partially sold: shows current state with "batch not closed" label.

### Rule 5 — Credit in Revenue
Credit sales count as revenue in P&L. Dashboard separately shows "Cash in Hand" vs "Total Revenue including credit" so the user always knows real cash position.

### Rule 6 — Multi-Purchaser Cost Attribution
When two people co-purchase a batch, their daily charges are each tracked separately. Their "shared" expenses (like a joint labor payment) can be attributed to one person's name — the system doesn't split expenses, it attributes each to one partner.

### Rule 7 — Soft Delete Only
No hard deletes in the system. Expenses can be "voided" (soft deleted) with a reason. Customers, partners, batches are never deleted — they are archived or closed.

### Rule 8 — Day-End Close
A batch is closed for the day when the seller either records POS sales or saves the day-end manual close. Day-end totals **must** reconcile: `remaining ≥ 0`. If the user enters totals inconsistent with previously-recorded POS sales, the app shows the discrepancy and refuses to save until resolved. Day-end entries are stored as ordinary `sales`/`expenses` rows so the RPC-based P&L remains authoritative.

### Rule 9 — Per-Batch Credit
Credit outstanding is tracked **per batch** (`customer_payments.batch_id`) AND per customer. A customer payment can be applied to a specific batch or left unassigned (whole-business credit, Rule 5). Applying a payment to a batch reduces that batch's outstanding; unassigned payments reduce the customer total only.

### Rule 10 — Reusable Packing Amortization
A reusable material's cost enters batch P&L as `cost ÷ expected reuses` per use. If the material is returned (empty bags), the return does not create a cost entry — it only records inventory movement. Unreturned material is expensed in full to the batch that last used it.

### Rule 11 — Supplier Payable Exclusion
Supplier payables are liabilities and never enter the batch P&L. Only `purchase_price` (paid portion) and actual cash outflows affect P&L. Payables are tracked to tell the owner what they still owe, not to distort profit.

---

## 7. Non-Functional Requirements

| Category | Requirement |
|----------|------------|
| **Platform** | Android (primary), iOS (secondary), Flutter Web (bonus) |
| **Performance** | Dashboard load < 2 seconds on 4G. Batch list scrolls at 60fps. |
| **Offline** | Last-loaded dashboard data persists via SharedPreferences for viewing when offline. Write operations require connectivity — show clear error. |
| **Connectivity** | Supabase Realtime: batch updates and new sales push to all connected partners without manual refresh. |
| **Scalability** | Handles 50 partners, 10,000 batches, 500,000 transactions without schema changes. |
| **Language** | English UI. Urdu localization in V2 (RTL structure in place). |
| **Date Format** | DD/MM/YYYY throughout. PKR currency with comma formatting (1,23,456). |
| **Data Retention** | All financial records retained for 7 years minimum. Soft deletes only. |
| **Accessibility** | Minimum 48px tap targets. High contrast text (4.5:1 ratio). |

---

## 8. Out of Scope — V1

- Custom backend / Python API (pure Supabase standalone)
- Barcode scanning for inventory
- Automated banking API integration
- Real-time market price feeds
- In-app chat / messaging between partners
- GST / FBR tax compliance reporting
- Urdu language UI (structure ready, translation deferred)
- Web portal (Flutter Web is a nice-to-have, not required)
- Push notifications (Realtime subscriptions used instead)
