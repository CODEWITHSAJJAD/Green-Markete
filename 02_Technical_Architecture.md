# 🏗️ Technical Architecture Document
## Green Market — Standalone Flutter + Supabase

**Version:** 2.1 (Operations Features) — Supersedes 2.0
**Date:** August 2026
**Stack:** Flutter 3.x · Supabase (PostgreSQL + Auth + Realtime + Storage)
**Architecture:** Standalone — no custom backend

> **Version 2.1 changes:** documents the **live schema** as probed from the running Supabase instance (columns/tables confirmed present vs planned), the frontend layering actually in use (`data/` models + repositories, `presentation/` providers + pages), the day-end synthesized-rows approach that keeps `get_batch_pl` authoritative, per-batch credit via `customer_payments.batch_id`, and the planned tables required by Phases 7–11 (see `OPERATIONS_FEATURES_PLAN.md`). Tables are tagged **[LIVE]** (confirmed present) or **[PLANNED]** (needed by the feature roadmap).

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Technology Stack](#2-technology-stack)
3. [Flutter App Architecture](#3-flutter-app-architecture)
4. [Navigation Architecture](#4-navigation-architecture)
5. [Database Schema](#5-database-schema)
6. [Supabase RPC Functions (P&L Engine)](#6-supabase-rpc-functions-pl-engine)
7. [State Management](#7-state-management)
8. [Realtime Subscriptions](#8-realtime-subscriptions)
9. [Offline Strategy](#9-offline-strategy)
10. [Deployment & Environment](#10-deployment--environment)

---

## 1. Architecture Overview

Green Market is a **standalone Flutter application** that communicates directly with Supabase. There is no custom backend server. All business logic runs either in:
- **Dart** (UI logic, validation, formatting), or
- **PostgreSQL functions** via Supabase RPC (P&L calculations, aggregations)

```
┌─────────────────────────────────────────────────────────────┐
│                  FLUTTER APP (Android / iOS)                  │
│                                                               │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │  UI Layer   │  │ Provider /   │  │  Repository Layer  │  │
│  │  (Widgets,  │◄►│ ChangeNotif  │◄►│  (Supabase calls,  │  │
│  │   Screens)  │  │  State Mgmt) │  │   RPC functions)   │  │
│  └─────────────┘  └──────────────┘  └────────────────────┘  │
│                                              │                │
│                              SharedPreferences (local cache)  │
└──────────────────────────────────────────────┼──────────────┘
                                               │ HTTPS
                               ┌───────────────▼───────────────┐
                               │          SUPABASE              │
                               │                                │
                               │  ┌──────────┐ ┌───────────┐   │
                               │  │PostgreSQL│ │  Auth     │   │
                               │  │   + RLS  │ │(Phone OTP)│   │
                               │  └──────────┘ └───────────┘   │
                               │  ┌──────────┐ ┌───────────┐   │
                               │  │ Realtime │ │  Storage  │   │
                               │  │(live sync)│ │(receipts) │   │
                               │  └──────────┘ └───────────┘   │
                               └───────────────────────────────┘
```

### Why No Custom Backend?
- Supabase PostgREST handles all CRUD via auto-generated REST endpoints
- Row Level Security (RLS) enforces authorization at the database layer
- PostgreSQL functions handle complex aggregations (P&L engine)
- Supabase Auth handles identity, JWT, and OTP flows
- Eliminates server maintenance, hosting costs, and deployment complexity

---

## 2. Technology Stack

| Component | Choice | Version |
|-----------|--------|---------|
| Frontend Framework | Flutter | 3.22+ |
| Language | Dart | 3.4+ |
| Database | Supabase (PostgreSQL 15) | Latest |
| Auth | Supabase Auth (Phone OTP + Email) | Latest |
| Realtime | Supabase Realtime | Latest |
| Storage | Supabase Storage | Latest |
| State Management | Provider + ChangeNotifier | 6.x |
| Navigation | Flutter Navigator 1.0 (push/pop) | Built-in |
| Local Cache | SharedPreferences | 2.x |
| PDF Export | printing + pdf packages | Latest |
| HTTP | supabase_flutter (built-in client) | 2.x |
| Charts | fl_chart | 0.68+ |

### Dart / Flutter Package List

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.5.0

  # State management
  provider: ^6.1.0

  # Local storage
  shared_preferences: ^2.3.0

  # PDF export
  pdf: ^3.11.0
  printing: ^5.13.0

  # Charts
  fl_chart: ^0.68.0

  # UI utilities
  intl: ^0.19.0               # date/currency formatting
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0             # loading skeletons
  flutter_slidable: ^3.1.0    # swipe actions on list tiles

  # Utilities
  uuid: ^4.4.0
  equatable: ^2.0.5
```

---

## 3. Flutter App Architecture

### 3.1 Folder Structure

> **V2.1:** this is the layout actually in use (`provider` 6.x `ChangeNotifier`, `Navigator.push` with an `AuthNavigator` host — no go_router). The earlier `models/ repositories/ providers/ screens/` layout in this document is superseded. Tree reflects the code as of August 2026; items tagged **(planned)** belong to Phases 7–11.

```
lib/
├── main.dart                      ← entry point: dotenv load, MultiProvider, MaterialApp + AuthNavigator
│
├── core/
│   ├── config/
│   │   ├── app_config.dart            ← app metadata
│   │   └── theme.dart                 ← ColorScheme, AppRadius.*, text themes
│   ├── supabase/
│   │   └── supabase_service.dart      ← shared SupabaseClient (Supabase.instance.client)
│   ├── error/                         ← app_exception.dart, error_handler.dart
│   ├── export/                        ← csv_export.dart, csv_writer.dart (CSV reports)
│   └── utils/
│       ├── currency_formatter.dart    ← PKR formatting
│       ├── date_formatter.dart        ← DD/MM/YYYY (intl)
│       ├── validators.dart  debouncer.dart  breakpoints.dart
│
├── data/
│   ├── models/                    ← Plain Dart classes (fromJson/toJson, snake_case + camelCase fallbacks)
│   │   ├── batch_model.dart  batch_partner_model.dart  batch_vehicle_model.dart
│   │   ├── customer_model.dart  partner_model.dart  payment_model.dart
│   │   ├── expense_model.dart  sale_model.dart  packing_record_model.dart  packing_return_model.dart
│   │   ├── transaction_model.dart  product_model.dart  market_model.dart  vehicle_model.dart
│   │   ├── user_model.dart  business_model.dart  audit_log_model.dart  report_model.dart
│   │   └── supplier_model.dart  packing_material_model.dart          (planned)
│   ├── datasources/
│   │   └── local/                ← app_database.dart (STUB — offline/local DB not implemented)
│   └── repositories/             ← repository per feature; direct Supabase calls, defensive error handling
│       ├── auth_repository.dart  business_repository.dart  partner_repository.dart
│       ├── product_repository.dart  market_repository.dart  batch_repository.dart
│       ├── expense_repository.dart  sale_repository.dart  customer_repository.dart
│       ├── vehicle_repository.dart  transaction_repository.dart  dashboard_repository.dart
│       ├── report_repository.dart  audit_repository.dart  sync_repository.dart (no-op)
│       └── supplier_repository.dart                          (planned)
│
└── presentation/
    ├── providers/                ← Provider 6.x ChangeNotifier + ChangeNotifierProvider (one per feature)
    │   ├── auth_provider.dart  business_provider.dart  batch_provider.dart
    │   ├── customer_provider.dart  dashboard_provider.dart  market_provider.dart
    │   ├── partner_provider.dart  product_provider.dart  report_provider.dart
    │   ├── transaction_provider.dart  vehicle_provider.dart  batch_wizard_provider.dart
    │   ├── capability.dart (role→capability map)  connectivity_provider.dart  async_notifier.dart
    │   └── supplier_provider.dart                        (planned)
    ├── widgets/                  ← shared: GreenCard, AmountText, StatusPill, PartnerChip,
    │                               EmptyState, ConfirmDialog, SaleEntrySheet, ExpenseEntrySheet,
    │                               PackingEntryForm, CreditIndicator, StatusTimeline…
    └── pages/
        ├── auth/      auth_navigator.dart (host), splash, login, signup, onboarding
        ├── main_shell.dart        ← 5-tab bottom nav (IndexedStack), sidebar_drawer on wide
        ├── dashboard/  dashboard_page.dart
        ├── batches/   list, detail (8 tabs), create_batch_wizard (6 steps), batch_pl_page
        ├── sales/     sales_list, quick_sale
        ├── customers/ list (+ shared filter), create, ledger, record_payment
        ├── partners/  list, create, profile
        ├── products/  list
        ├── markets/   list, create
        ├── vehicles/  list, create
        ├── transactions/  list, settlement, balance
        ├── reports/   reports_page, pl_report, credit_report, overdue_customers,
        │               market_performance, partner_report
        ├── settings/  settings, profile, business_settings, business_switcher,
        │               access_management, audit_log, notification_settings, help_center, about
        ├── suppliers/ list, payables                 (planned — Phase 9)
        └── packing/   materials_screen              (planned — Phase 10)
```

> **Data flow:** Page → Provider (ChangeNotifier) → Repository → `SupabaseClient` (PostgREST/RPC). Responses are raw rows (no `data` envelope wrapper); models read both `snake_case` and `camelCase` keys defensively, and every possibly-absent column/table is probed + caught (PostgrestException) before use.

---

## 4. Navigation Architecture

### 4.1 Principle: Navigator.push + AuthNavigator host (no go_router)

> **V2.1 correction:** the app does **not** use go_router. `main.dart` builds a `MaterialApp` whose `home` is an `AuthNavigator` widget (`presentation/pages/auth/auth_navigator.dart`) that switches on auth state: splash → login/signup → onboarding → `MainShell` (5-tab bottom nav, `IndexedStack`). All feature navigation is plain `Navigator.push(MaterialPageRoute(...))`; there is no `routes.dart`. The samples below are the actual pattern.

```dart
// Navigating to a screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => BatchDetailScreen(batchId: batch.id)),
);

// Going back
Navigator.pop(context);

// Replacing current screen (e.g., after login)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => MainShell()),
);

// Clearing entire stack (e.g., after logout)
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => LoginScreen()),
  (_) => false,
);
```

### 4.2 Auth Wrapper (entry point)

```dart
// app.dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return LoginScreen();

    // Check if onboarding complete
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isOnboarded) return OnboardingScreen();

    return MainShell();
  }
}
```

Supabase Auth state changes are listened to in `main.dart` and trigger `AuthWrapper` rebuild:

```dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  // AuthProvider notifies listeners → AuthWrapper rebuilds
  authProvider.handleAuthStateChange(data);
});
```

### 4.3 Main Shell — BottomNavigationBar

```dart
class MainShell extends StatefulWidget { ... }

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    DashboardScreen(),
    BatchListScreen(),
    SalesListScreen(),
    CustomerListScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(           // preserves tab scroll positions
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Batches'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
```

`IndexedStack` is used so each tab's scroll position is preserved when switching tabs.

### 4.4 Create Batch Wizard (PageView — no routing)

The batch creation wizard is a single screen with a `PageView` and a `PageController`. No router involved. Steps are managed locally within the screen:

```dart
class CreateBatchScreen extends StatefulWidget { ... }

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  void _nextStep() {
    if (_validateCurrentStep()) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    _pageController.previousPage(...);
    setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Batch — Step ${_currentStep + 1} of 5'),
        leading: _currentStep > 0 ? BackButton(onPressed: _prevStep) : CloseButton(),
      ),
      body: Column(
        children: [
          StepProgressIndicator(currentStep: _currentStep, totalSteps: 5),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(), // navigate via buttons only
              children: [
                Step1ProductPurchase(),
                Step2Partners(),
                Step3Packing(),
                Step4Expenses(),
                Step5ReviewConfirm(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.5 Batch Detail — TabBar (no routing)

```dart
class BatchDetailScreen extends StatelessWidget {
  final String batchId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Batch Detail'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Expenses'),
              Tab(text: 'Packing'),
              Tab(text: 'Sales'),
              Tab(text: 'P&L'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BatchOverviewTab(batchId: batchId),
            BatchExpensesTab(batchId: batchId),
            BatchPackingTab(batchId: batchId),
            BatchSalesTab(batchId: batchId),
            BatchPLTab(batchId: batchId),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Database Schema

All tables live in Supabase PostgreSQL. RLS is enabled on all tables. Full RLS policies are documented in the Security & Access document.

### 5.1 `user_profiles`
```sql
CREATE TABLE user_profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name   TEXT NOT NULL,
    phone       TEXT UNIQUE,
    cnic        TEXT,                    -- optional, encrypted
    city        TEXT,
    bank_name   TEXT,
    bank_account TEXT,                   -- masked: stored last 4 digits only
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.2 `businesses`
```sql
CREATE TABLE businesses (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name           TEXT NOT NULL,
    owner_id       UUID NOT NULL REFERENCES user_profiles(id),
    business_type  TEXT DEFAULT 'multi_partner' CHECK (business_type IN ('single', 'multi_partner')),
    credit_alert_threshold NUMERIC DEFAULT 50000,
    created_at     TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.3 `business_partners`
```sql
CREATE TABLE business_partners (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id    UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    user_id        UUID REFERENCES user_profiles(id),    -- NULL if unclaimed
    phone          TEXT,                                 -- used for claim matching
    full_name      TEXT NOT NULL,                        -- denormalized for unclaimed display
    role           TEXT NOT NULL CHECK (role IN ('purchaser','seller','both','accountant')),
    access_level   TEXT NOT NULL DEFAULT 'viewer' CHECK (access_level IN ('editor','viewer')),
    is_claimed     BOOLEAN DEFAULT FALSE,
    invited_by     UUID REFERENCES user_profiles(id),
    joined_at      TIMESTAMPTZ,
    created_at     TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.4 `markets`
```sql
CREATE TABLE markets (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID NOT NULL REFERENCES businesses(id),
    name         TEXT NOT NULL,
    city         TEXT NOT NULL,
    stall_number TEXT,
    market_type  TEXT DEFAULT 'both' CHECK (market_type IN ('wholesale','retail','both')),
    created_at   TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.5 `products`
```sql
CREATE TABLE products (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID NOT NULL REFERENCES businesses(id),
    name         TEXT NOT NULL,
    category     TEXT,
    base_unit    TEXT DEFAULT 'kg' CHECK (base_unit IN ('kg','bag','packet','custom')),
    created_at   TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.6 `product_batches`
```sql
CREATE TABLE product_batches (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id              UUID NOT NULL REFERENCES businesses(id),
    product_id               UUID NOT NULL REFERENCES products(id),
    batch_code               TEXT UNIQUE NOT NULL,   -- GM-2026-0001
    source_market_id         UUID REFERENCES markets(id),
    destination_market_id    UUID REFERENCES markets(id),
    purchase_date            DATE NOT NULL,
    total_quantity           NUMERIC NOT NULL CHECK (total_quantity > 0),
    quantity_unit            TEXT NOT NULL,           -- kg, bags, packets, etc.
    purchase_price_per_unit  NUMERIC NOT NULL CHECK (purchase_price_per_unit >= 0),
    transport_amount         NUMERIC DEFAULT 0,
    transport_paid_by        TEXT,                   -- 'purchaser' | 'seller'
    transport_mode           TEXT,                   -- truck, van, etc.
    status                   TEXT DEFAULT 'purchased' CHECK (
                               status IN ('purchased','packed','in_transit','delivered','selling','closed')
                             ),
    notes                    TEXT,
    created_by               UUID REFERENCES user_profiles(id),
    created_at               TIMESTAMPTZ DEFAULT NOW(),
    updated_at               TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-generate batch_code trigger
CREATE OR REPLACE FUNCTION generate_batch_code()
RETURNS TRIGGER AS $$
DECLARE
  year_part TEXT := TO_CHAR(NOW(), 'YYYY');
  seq_num   INT;
BEGIN
  SELECT COUNT(*) + 1 INTO seq_num
  FROM product_batches
  WHERE business_id = NEW.business_id
    AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW());
  NEW.batch_code := 'GM-' || year_part || '-' || LPAD(seq_num::TEXT, 4, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_batch_code
  BEFORE INSERT ON product_batches
  FOR EACH ROW EXECUTE FUNCTION generate_batch_code();
```

### 5.7 `batch_partners`
```sql
CREATE TABLE batch_partners (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id            UUID NOT NULL REFERENCES product_batches(id) ON DELETE CASCADE,
    partner_id          UUID NOT NULL REFERENCES business_partners(id),
    role                TEXT NOT NULL CHECK (role IN ('purchaser','seller','both')),
    daily_charge_rate   NUMERIC DEFAULT 0 CHECK (daily_charge_rate >= 0),
    days_involved       INTEGER DEFAULT 1 CHECK (days_involved >= 0),
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.8 `packing_records`
```sql
CREATE TABLE packing_records (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID NOT NULL REFERENCES product_batches(id) ON DELETE CASCADE,
    unit_type_label TEXT NOT NULL,      -- "5kg packet", "100kg bag", "25kg box"
    unit_count      INTEGER NOT NULL CHECK (unit_count > 0),
    cost_per_unit   NUMERIC NOT NULL CHECK (cost_per_unit >= 0),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Computed column via view
CREATE VIEW packing_records_with_total AS
SELECT *, (unit_count * cost_per_unit) AS total_packing_cost
FROM packing_records;
```

### 5.9 `expenses`
```sql
CREATE TABLE expenses (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id         UUID NOT NULL REFERENCES product_batches(id) ON DELETE CASCADE,
    business_id      UUID NOT NULL REFERENCES businesses(id),
    expense_side     TEXT NOT NULL CHECK (expense_side IN ('purchaser','transport','seller')),
    expense_type     TEXT NOT NULL CHECK (expense_type IN (
                       'daily_charge','labor','accountant','source_stall_fee',
                       'local_transport','destination_stall_fee','misc','transport'
                     )),
    amount           NUMERIC NOT NULL CHECK (amount >= 0),
    description      TEXT,
    paid_by          UUID REFERENCES business_partners(id),
    payment_mode     TEXT DEFAULT 'cash' CHECK (payment_mode IN ('cash','bank_transfer')),
    bank_reference   TEXT,
    expense_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    is_voided        BOOLEAN DEFAULT FALSE,
    voided_by        UUID REFERENCES user_profiles(id),
    voided_reason    TEXT,
    created_by       UUID REFERENCES user_profiles(id),
    created_at       TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.10 `customers`
```sql
CREATE TABLE customers (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id  UUID NOT NULL REFERENCES businesses(id),
    full_name    TEXT NOT NULL,
    phone        TEXT,
    city         TEXT,
    shop_name    TEXT,
    notes        TEXT,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.11 `sales`
```sql
CREATE TABLE sales (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id       UUID NOT NULL REFERENCES product_batches(id),
    business_id    UUID NOT NULL REFERENCES businesses(id),
    seller_id      UUID REFERENCES business_partners(id),
    customer_id    UUID REFERENCES customers(id),       -- NULL = walk-in
    sale_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    quantity_sold  NUMERIC NOT NULL CHECK (quantity_sold > 0),
    price_per_unit NUMERIC NOT NULL CHECK (price_per_unit >= 0),
    cash_received  NUMERIC NOT NULL DEFAULT 0 CHECK (cash_received >= 0),
    credit_amount  NUMERIC NOT NULL DEFAULT 0 CHECK (credit_amount >= 0),
    payment_mode   TEXT NOT NULL CHECK (payment_mode IN ('cash','credit','partial')),
    bank_reference TEXT,
    notes          TEXT,
    created_by     UUID REFERENCES user_profiles(id),
    created_at     TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure total_amount consistency
    CONSTRAINT chk_amounts CHECK (
      cash_received + credit_amount = quantity_sold * price_per_unit
    )
);
```
**[LIVE (V2.1):]** the running instance also accepts `payment_mode = 'bank_transfer'`. Day-end manual close stores **ordinary `sales` rows**: one aggregated `payment_mode='cash'` row for cash-in-hand and one `payment_mode='credit'` row per credit customer (notes reference the day). This keeps `get_batch_pl` authoritative with zero backend change.

### 5.12 `customer_payments`
```sql
CREATE TABLE customer_payments (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id    UUID NOT NULL REFERENCES customers(id),
    business_id    UUID NOT NULL REFERENCES businesses(id),
    amount         NUMERIC NOT NULL CHECK (amount > 0),
    payment_mode   TEXT NOT NULL CHECK (payment_mode IN ('cash','bank_transfer')),
    bank_reference TEXT,
    payment_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    received_by    UUID REFERENCES business_partners(id),
    notes          TEXT,
    created_at     TIMESTAMPTZ DEFAULT NOW()
);
```
**[LIVE (V2.1):]** the running instance **has a `batch_id` column** (confirmed by `select=customer_id,batch_id` probe) even though it is absent from the 2.0 DDL. Per-batch credit/collection (Phase 8) sets this column; whole-business credit leaves it NULL. The app probes the column defensively before sending it.

### 5.13 `partner_transactions`
```sql
CREATE TABLE partner_transactions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id       UUID NOT NULL REFERENCES businesses(id),
    from_partner_id   UUID NOT NULL REFERENCES business_partners(id),
    to_partner_id     UUID NOT NULL REFERENCES business_partners(id),
    amount            NUMERIC NOT NULL CHECK (amount > 0),
    transaction_type  TEXT CHECK (transaction_type IN (
                        'settlement','transport_debt','advance','expense_reimbursement'
                      )),
    payment_mode      TEXT CHECK (payment_mode IN ('cash','bank_transfer')),
    bank_reference    TEXT,
    batch_id          UUID REFERENCES product_batches(id),   -- if batch-linked
    transaction_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    notes             TEXT,
    created_at        TIMESTAMPTZ DEFAULT NOW()
);
```

### 5.14 `audit_logs`
```sql
CREATE TABLE audit_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name   TEXT NOT NULL,
    record_id    UUID NOT NULL,
    action       TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE','VOID')),
    performed_by UUID REFERENCES user_profiles(id),
    old_values   JSONB,
    new_values   JSONB,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);
-- Append-only: no UPDATE or DELETE allowed on this table (via RLS)
```

### 5.15 `supplier_payments` (V2.1 — daily-61)
```sql
CREATE TABLE supplier_payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id     UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    supplier_name   TEXT NOT NULL,
    amount          NUMERIC NOT NULL CHECK (amount > 0),
    payment_mode    TEXT NOT NULL CHECK (payment_mode IN ('cash','bank_transfer')),
    bank_reference  TEXT,
    payment_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    received_by     UUID REFERENCES business_partners(id),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX supplier_payments_business_name_idx
    ON supplier_payments (business_id, supplier_name);
CREATE INDEX supplier_payments_business_date_idx
    ON supplier_payments (business_id, payment_date DESC);
```
**[LIVE]** (pending migration 15 deployment). The customer-credit analog of `customer_payments` — stores payments made **after** a multi-supplier batch purchase to settle the running per-supplier balance. Per-supplier outstanding is computed from `batch_purchases` (Σ quantity × price_per_unit − amount_paid, grouped by `supplier_name` joined to `product_batches` for `business_id`); the wizard's purchase-time `amount_paid` is the initial payment against the purchase line, and `supplier_payments` rows are subsequent settlements. Mirrors `customer_payments` shape exactly (free-text `supplier_name` instead of `customer_id` because the `suppliers` registry is still Phase 9 — PLANNED). The Flutter app probes the table defensively (`_safeSelect` catches `PGRST205`/`42P01`/`42703`) and degrades to an empty settlements list when the table is absent. See `03_Security_Access.md` §3.15 for the RLS policies.

### 5.16 `batch_purchases` (V2.1 — daily-59/61)
```sql
CREATE TABLE batch_purchases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id        UUID NOT NULL REFERENCES product_batches(id) ON DELETE CASCADE,
    market_id       UUID REFERENCES markets(id),
    supplier_name   TEXT NOT NULL,
    unit_label      TEXT,
    unit_kg         NUMERIC NOT NULL,
    quantity        NUMERIC NOT NULL,
    price_per_unit  NUMERIC NOT NULL,
    payment_mode    TEXT,
    amount_paid     NUMERIC NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```
**[LIVE]** (table itself) but **RLS missing** — the daily-59 wizard inserts per-line purchase records but no RLS policy was published. The Supplier Settlements ledger (daily-61) reads this table joined to `product_batches` for `business_id`; until RLS is added, the row-level gateway is open. Migration 15 publishes the full policy set (see `03_Security_Access.md` §3.15). The Flutter app wraps each access in a defensive `_safeSelect` so the visible symptoms of missing RLS are: anon SELECT returns 0 rows (no settlement list), and INSERTs are silently dropped.

### 5.17 Live vs Planned Tables (V2.1)

| Table | Status | Notes |
|---|---|---|
| `user_profiles`, `businesses`, `business_partners`, `markets`, `products`, `product_batches`, `batch_partners`, `packing_records`, `expenses`, `customers`, `sales`, `customer_payments`, `partner_transactions`, `audit_logs` | **[LIVE]** | 2.0 baseline, with the live column drift noted above (`sales.bank_transfer`, `customer_payments.batch_id`). `product_batches` live columns also include `supplier_name`, `purchase_payment_mode` (`cash`/`debt`), `purchase_amount_paid` (used for supplier payables — Section 4.5 of the PRD). |
| `batch_purchases` | **[LIVE]** (RLS pending) | Per-line purchase records (daily-59 wizard). Backend gap: row-level policies missing — migration 15 adds them. The Supplier Settlements ledger (daily-61) reads from this table joined to `product_batches`. |
| `supplier_payments` | **[LIVE]** (pending migration 15) | Post-purchase payments to a supplier (daily-61). Customer-credit analog of `customer_payments`. Without this table, the Supplier Settlements UI shows an empty list and "Record Payment" returns a `PostgrestException` — the app degrades gracefully. |
| `suppliers` | **[PLANNED]** (Phase 9) | Supplier registry. Migration 15 ships the DDL + RLS as a forward-compatible placeholder so the defense can be reused later. The Frontend currently does NOT depend on it — it accepts free-text supplier names and groups by `supplier_name`. |
| `batch_vehicles` + `vehicle_loads` | **[LIVE]** | Vehicle registry and per-vehicle load splits (Phase 3). |
| `packing_returns` | **[LIVE]** | Empty-bag returns to purchaser parts (Phase 4). |
| `packing_materials` | **[PLANNED]** (Phase 10) | Reusable material inventory (name, cost, expected reuses) + per-batch usage. |
| `customer_shares` | **[PLANNED]** (Phase 11) | Cross-business customer sharing. The app already probes this table defensively (`listSharedCustomerIds`) and degrades to "no shared customers" when it 404s. |
| `vehicle_shares` | **[PLANNED]** (Phase 11) | Cross-business vehicle sharing. |
| `batch_day_summaries`, `batch_day_entries` | **NOT NEEDED** | Probed → 404, and deliberately **avoided**: day-end close synthesizes ordinary `sales`/`expenses` rows so the RPC P&L stays authoritative. |

> **Defensive pattern (all new features):** before writing/reading a planned table, the repository probes its shape (e.g. `select=batch_id` on `customer_payments`, `select=*` on `customer_shares`) and gracefully degrades on 4xx/42703. Never assume a column exists.

---

## 6. Supabase RPC Functions (P&L Engine)

Complex P&L calculations run as PostgreSQL functions called via `supabase.rpc()` from Flutter. This keeps calculations accurate and server-side.

### 6.1 `get_batch_pl(batch_id UUID) → JSONB`

> **V2.1 note:** this RPC remains the **single authoritative source of P&L**. Day-end close (Phase 7) writes ordinary `sales`/`expenses` rows precisely so this RPC keeps producing correct results. Per-batch credit (Phase 8) is derived client-side from `sales` (credit sold per batch) minus `customer_payments` (collected per batch) — no new RPC required.

```sql
CREATE OR REPLACE FUNCTION get_batch_pl(p_batch_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_purchase_cost     NUMERIC;
  v_purch_expenses    NUMERIC;
  v_transport_cost    NUMERIC;
  v_seller_expenses   NUMERIC;
  v_packing_cost      NUMERIC;
  v_total_cost        NUMERIC;
  v_total_revenue     NUMERIC;
  v_cash_received     NUMERIC;
  v_credit_outstanding NUMERIC;
  v_qty_sold          NUMERIC;
  v_total_qty         NUMERIC;
BEGIN
  -- Purchase base cost
  SELECT total_quantity * purchase_price_per_unit, total_quantity
  INTO v_purchase_cost, v_total_qty
  FROM product_batches WHERE id = p_batch_id;

  -- Purchaser-side expenses (non-voided)
  SELECT COALESCE(SUM(amount), 0) INTO v_purch_expenses
  FROM expenses WHERE batch_id = p_batch_id AND expense_side = 'purchaser' AND is_voided = FALSE;

  -- Transport
  SELECT COALESCE(SUM(amount), 0) INTO v_transport_cost
  FROM expenses WHERE batch_id = p_batch_id AND expense_side = 'transport' AND is_voided = FALSE;

  -- Seller-side expenses
  SELECT COALESCE(SUM(amount), 0) INTO v_seller_expenses
  FROM expenses WHERE batch_id = p_batch_id AND expense_side = 'seller' AND is_voided = FALSE;

  -- Packing cost
  SELECT COALESCE(SUM(unit_count * cost_per_unit), 0) INTO v_packing_cost
  FROM packing_records WHERE batch_id = p_batch_id;

  v_total_cost := v_purchase_cost + v_purch_expenses + v_transport_cost
                + v_seller_expenses + v_packing_cost;

  -- Sales
  SELECT COALESCE(SUM(quantity_sold), 0),
         COALESCE(SUM(quantity_sold * price_per_unit), 0),
         COALESCE(SUM(cash_received), 0),
         COALESCE(SUM(credit_amount), 0)
  INTO v_qty_sold, v_total_revenue, v_cash_received, v_credit_outstanding
  FROM sales WHERE batch_id = p_batch_id;

  RETURN jsonb_build_object(
    'purchase_cost',       v_purchase_cost,
    'purchaser_expenses',  v_purch_expenses,
    'transport_cost',      v_transport_cost,
    'seller_expenses',     v_seller_expenses,
    'packing_cost',        v_packing_cost,
    'total_cost',          v_total_cost,
    'total_revenue',       v_total_revenue,
    'cash_received',       v_cash_received,
    'credit_outstanding',  v_credit_outstanding,
    'profit_loss',         v_total_revenue - v_total_cost,
    'qty_total',           v_total_qty,
    'qty_sold',            v_qty_sold,
    'qty_remaining',       v_total_qty - v_qty_sold
  );
END;
$$;
```

**Flutter call:**
```dart
final response = await supabase.rpc('get_batch_pl', params: {'p_batch_id': batchId});
final pl = BatchPLSummary.fromJson(response as Map<String, dynamic>);
```

### 6.2 `get_business_pl_summary(business_id, from_date, to_date) → JSONB`

```sql
CREATE OR REPLACE FUNCTION get_business_pl_summary(
    p_business_id UUID,
    p_from        DATE,
    p_to          DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_batches',   COUNT(DISTINCT pb.id),
    'total_revenue',   COALESCE(SUM(s.quantity_sold * s.price_per_unit), 0),
    'cash_received',   COALESCE(SUM(s.cash_received), 0),
    'credit_pending',  COALESCE(SUM(s.credit_amount), 0),
    'total_expenses',  (
        SELECT COALESCE(SUM(e.amount), 0) FROM expenses e
        JOIN product_batches epb ON epb.id = e.batch_id
        WHERE epb.business_id = p_business_id
          AND epb.purchase_date BETWEEN p_from AND p_to
          AND e.is_voided = FALSE
    )
  ) INTO result
  FROM product_batches pb
  LEFT JOIN sales s ON s.batch_id = pb.id AND s.sale_date BETWEEN p_from AND p_to
  WHERE pb.business_id = p_business_id
    AND pb.purchase_date BETWEEN p_from AND p_to;

  RETURN result;
END;
$$;
```

### 6.3 `get_customer_balance(customer_id UUID) → NUMERIC`

```sql
CREATE OR REPLACE FUNCTION get_customer_balance(p_customer_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_credit  NUMERIC;
  total_paid    NUMERIC;
BEGIN
  SELECT COALESCE(SUM(credit_amount), 0) INTO total_credit
  FROM sales WHERE customer_id = p_customer_id;

  SELECT COALESCE(SUM(amount), 0) INTO total_paid
  FROM customer_payments WHERE customer_id = p_customer_id;

  RETURN total_credit - total_paid;
END;
$$;
```

---

## 7. State Management

### 7.1 Pattern: Provider + ChangeNotifier

Each major domain has a ChangeNotifier provider:

```dart
// Example: BatchProvider
class BatchProvider extends ChangeNotifier {
  final BatchRepository _repo;
  List<ProductBatch> _batches = [];
  bool _isLoading = false;
  String? _error;

  List<ProductBatch> get batches => _batches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BatchProvider(this._repo);

  Future<void> loadBatches({String? statusFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _batches = await _repo.getBatches(statusFilter: statusFilter);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBatch(CreateBatchRequest req) async { ... }
  Future<void> updateBatchStatus(String batchId, String newStatus) async { ... }
}
```

### 7.2 Provider Setup in `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider(BatchRepository())),
        ChangeNotifierProvider(create: (_) => CustomerProvider(CustomerRepository())),
        ChangeNotifierProvider(create: (_) => DashboardProvider(DashboardRepository())),
        ChangeNotifierProvider(create: (_) => PartnerProvider(PartnerRepository())),
      ],
      child: GreenMarketApp(),
    ),
  );
}
```

---

## 8. Realtime Subscriptions

Supabase Realtime is used for live updates — no manual refresh needed when a partner records a sale or expense.

```dart
// Subscribe to sales updates on a specific batch
class BatchSalesTab extends StatefulWidget { ... }

class _BatchSalesTabState extends State<BatchSalesTab> {
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadSales();

    _channel = Supabase.instance.client
      .channel('sales_batch_${widget.batchId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'sales',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'batch_id',
          value: widget.batchId,
        ),
        callback: (payload) => _loadSales(),  // reload on new sale
      )
      .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }
}
```

**Channels used:**
| Channel | Event | Used On |
|---------|-------|---------|
| `sales_batch_{id}` | INSERT | Batch sales tab |
| `expenses_batch_{id}` | INSERT, UPDATE | Batch expenses tab |
| `customer_payments_{customer_id}` | INSERT | Customer ledger |

---

## 9. Offline Strategy

### Approach: SharedPreferences cache + connectivity check

Since this is a financial app, write operations (record sale, add expense) **require connectivity** — no silent offline queue. However, recently loaded data is cached for viewing.

```dart
class DashboardRepository {
  static const _cacheKey = 'dashboard_cache';

  Future<DashboardData> getDashboardData() async {
    try {
      final data = await _fetchFromSupabase();
      // Cache on success
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(_cacheKey, jsonEncode(data.toJson()));
      return data;
    } catch (e) {
      // On failure, return cached data
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        return DashboardData.fromJson(jsonDecode(cached));
      }
      rethrow;
    }
  }
}
```

**Connectivity check before writes:**
```dart
Future<void> recordSale(SaleRequest req) async {
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity == ConnectivityResult.none) {
    throw Exception('No internet connection. Sale not recorded.');
  }
  await supabase.from('sales').insert(req.toJson());
}
```

---

## 10. Deployment & Environment

### 10.1 Environment Variables (compile-time)

```bash
# Build with env vars (no .env file in Flutter — use --dart-define)
flutter build apk \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx...
```

### 10.2 Supabase Setup Checklist

```
□ Create Supabase project
□ Enable Phone Auth provider (Twilio SMS or Supabase built-in)
□ Run all migration SQL files in order (01 through 14)
□ Enable RLS on all tables
□ Apply all RLS policies (see Security document)
□ Create PostgreSQL functions: get_batch_pl, get_business_pl_summary, get_customer_balance
□ Enable Realtime on tables: sales, expenses, customer_payments
□ Create Storage bucket: receipts (private, authenticated access only)
□ Set up Supabase Edge Function for batch_code generation (or use DB trigger)
```

### 10.3 Release Build

```bash
# Android
flutter build apk --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>

# iOS
flutter build ios --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>
```
