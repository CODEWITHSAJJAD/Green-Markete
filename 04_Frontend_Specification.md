# 📱 Frontend Specification Document
## Green Market — Flutter UI/UX Design

**Version:** 2.0
**Date:** August 2026
**Framework:** Flutter 3.x | Navigation: Navigator.push (no go_router) | State: Provider

---

## Table of Contents

1. [Design System](#1-design-system)
2. [Navigation Map](#2-navigation-map)
3. [Auth Screens](#3-auth-screens)
4. [Main Shell & Bottom Nav](#4-main-shell--bottom-nav)
5. [Dashboard Screen](#5-dashboard-screen)
6. [Batch Screens](#6-batch-screens)
7. [Sales Screens](#7-sales-screens)
8. [Customer Screens](#8-customer-screens)
9. [More Menu & Sub-screens](#9-more-menu--sub-screens)
10. [Shared Components](#10-shared-components)
11. [UX Flows (Step by Step)](#11-ux-flows-step-by-step)
12. [Offline & Error States](#12-offline--error-states)

---

## 1. Design System

### 1.1 Color Palette

```dart
class AppColors {
  // Primary — Deep Green (brand)
  static const primary        = Color(0xFF1B5E20);
  static const primaryLight   = Color(0xFF4CAF50);
  static const primarySurface = Color(0xFFE8F5E9);  // light green bg for cards

  // Accent
  static const amber          = Color(0xFFFF8F00);   // warnings, pending
  static const amberSurface   = Color(0xFFFFF8E1);

  // Semantic
  static const profit         = Color(0xFF2E7D32);   // dark green
  static const loss           = Color(0xFFC62828);   // dark red
  static const pending        = Color(0xFFE65100);   // orange
  static const creditLow      = Color(0xFF2E7D32);   // green: small balance
  static const creditMid      = Color(0xFFF57F17);   // amber: moderate
  static const creditHigh     = Color(0xFFC62828);   // red: high balance

  // Neutrals
  static const background     = Color(0xFFF5F7F5);
  static const surface        = Color(0xFFFFFFFF);
  static const divider        = Color(0xFFE0E0E0);
  static const textPrimary    = Color(0xFF1A1A1A);
  static const textSecondary  = Color(0xFF757575);
  static const textHint       = Color(0xFFBDBDBD);
}
```

### 1.2 Typography

```dart
class AppTextStyles {
  // Display — page titles
  static const display = TextStyle(
    fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );

  // Headline — card titles, section headers
  static const headline = TextStyle(
    fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Subtitle — item names, labels
  static const subtitle = TextStyle(
    fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Body — descriptions, metadata
  static const body = TextStyle(
    fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Amount — PKR values (mono for alignment)
  static const amount = TextStyle(
    fontFamily: 'RobotoMono', fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // AmountLarge — dashboard totals
  static const amountLarge = TextStyle(
    fontFamily: 'RobotoMono', fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // Caption — timestamps, small meta
  static const caption = TextStyle(
    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Code — batch codes, references
  static const code = TextStyle(
    fontFamily: 'RobotoMono', fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.primary, letterSpacing: 0.5,
  );
}
```

### 1.3 Spacing & Layout

```dart
class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;

  static const cardPadding    = EdgeInsets.all(16.0);
  static const screenPadding  = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const listItemPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
}
```

### 1.4 Component Specs

**GreenCard**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
  ),
  padding: AppSpacing.cardPadding,
  child: content,
)
```

**StatusPill** — color-coded batch status badge:
```
purchased   → grey bg     #9E9E9E
packed      → blue bg     #1565C0
in_transit  → orange bg   #E65100
delivered   → teal bg     #00695C
selling     → green bg    #2E7D32
closed      → dark grey   #424242
```

**AmountText** — PKR-formatted:
```dart
Text(
  'PKR ${NumberFormat('#,##,###').format(amount)}',
  style: AppTextStyles.amount,
)
```

**BatchCodeText**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: AppColors.primarySurface,
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text('GM-2026-0042', style: AppTextStyles.code),
)
```

**PartnerChip**
```dart
Chip(
  avatar: CircleAvatar(child: Text(initials, style: TextStyle(fontSize: 12))),
  label: Text(partnerName),
  backgroundColor: AppColors.primarySurface,
)
```

**ProfitLossText** — green for profit, red for loss:
```dart
Text(
  '${pl >= 0 ? '+' : ''}PKR ${NumberFormat('#,##,###').format(pl)}',
  style: AppTextStyles.amount.copyWith(
    color: pl >= 0 ? AppColors.profit : AppColors.loss,
    fontWeight: FontWeight.w700,
  ),
)
```

### 1.5 Theme

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.amber,
    background: AppColors.background,
    surface: AppColors.surface,
  ),
  fontFamily: 'Inter',
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    backgroundColor: Colors.white,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),
)
```

---

## 2. Navigation Map

```
SplashScreen
    │
    ├── [no session] → LoginScreen
    │       └── OTPVerifyScreen
    │               └── [first time] → OnboardingScreen → MainShell
    │               └── [returning]  → MainShell
    │
    └── [has session] → MainShell
            │
            ├── Tab 0: DashboardScreen
            │       └── Navigator.push → BatchDetailScreen
            │       └── Navigator.push → SaleEntryScreen
            │       └── Navigator.push → CustomerDetailScreen
            │
            ├── Tab 1: BatchListScreen
            │       └── Navigator.push → CreateBatchScreen (PageView wizard)
            │       └── Navigator.push → BatchDetailScreen
            │               ├── BatchOverviewTab
            │               ├── BatchExpensesTab → Navigator.push → AddExpenseScreen
            │               ├── BatchPackingTab  → Navigator.push → AddPackingScreen
            │               ├── BatchSalesTab    → Navigator.push → SaleEntryScreen
            │               └── BatchPLTab
            │
            ├── Tab 2: SalesListScreen
            │       └── Navigator.push → SaleEntryScreen
            │       └── Navigator.push → BatchDetailScreen (via batch link)
            │
            ├── Tab 3: CustomerListScreen
            │       └── Navigator.push → CreateCustomerScreen
            │       └── Navigator.push → CustomerDetailScreen
            │               └── Navigator.push → CustomerPaymentScreen
            │
            └── Tab 4: MoreScreen
                    ├── Navigator.push → PartnerListScreen
                    │       └── Navigator.push → CreatePartnerScreen
                    │       └── Navigator.push → PartnerDetailScreen
                    │
                    ├── Navigator.push → MarketManageScreen
                    ├── Navigator.push → ReportsScreen
                    ├── Navigator.push → SettingsScreen
                    └── Navigator.push → ProfileScreen
```

---

## 3. Auth Screens

### 3.1 SplashScreen

```
┌─────────────────────────────┐
│                             │
│         🌿                  │
│    GREEN MARKET             │
│                             │
│   Vegetable Trading &       │
│   Partner Management        │
│                             │
│   [CircularProgressIndicator│
│    while checking auth]     │
│                             │
└─────────────────────────────┘
```

- Shows for max 2 seconds while Supabase checks session
- No user interaction needed

### 3.2 LoginScreen

```
┌─────────────────────────────┐
│  ←                          │
│                             │
│       🌿 Green Market       │
│                             │
│  Welcome Back               │
│  Enter your phone to login  │
│                             │
│  ┌──────────────────────┐   │
│  │ 🇵🇰 +92  03xx-xxxxxxx│   │
│  └──────────────────────┘   │
│                             │
│  [Send OTP Code]            │
│                             │
│  ─────── or ───────         │
│                             │
│  [Use Email Instead]        │
│                             │
└─────────────────────────────┘
```

- Phone field: formatted input with +92 prefix auto-applied
- "Send OTP Code" → calls `supabase.auth.signInWithOtp(phone: ...)`
- "Use Email Instead" → shows email/password fields instead

### 3.3 OTPVerifyScreen

```
┌─────────────────────────────┐
│  ←                          │
│                             │
│  Verify your number         │
│  Code sent to 03xx-xxx-xxxx │
│                             │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐│
│  │  │ │  │ │  │ │  │ │  │ │  ││
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘│
│                             │
│  Resend code in 00:42       │
│                             │
│  [Verify & Continue]        │
│                             │
└─────────────────────────────┘
```

- 6 auto-advancing digit boxes
- Countdown timer for resend (60 seconds)
- Auto-submits when all 6 digits entered
- Error snackbar on wrong OTP

### 3.4 OnboardingScreen

```
┌─────────────────────────────┐
│  Set Up Your Business       │
│                             │
│  Business Name              │
│  ┌──────────────────────┐   │
│  │ e.g. Ahmed Traders   │   │
│  └──────────────────────┘   │
│                             │
│  Your Name                  │
│  ┌──────────────────────┐   │
│  └──────────────────────┘   │
│                             │
│  Your Role                  │
│  ● Both (Buy & Sell)        │
│  ○ Purchaser Only           │
│  ○ Seller Only              │
│                             │
│  Your City                  │
│  ┌──────────────────────┐   │
│  └──────────────────────┘   │
│                             │
│  [Create Business]          │
└─────────────────────────────┘
```

---

## 4. Main Shell & Bottom Nav

```
┌─────────────────────────────┐
│  [Tab Content Area]         │
│                             │
│                             │
│                             │
│                             │
│                             │
├─────────────────────────────┤
│  🏠     📦    💰    👥   ⋯  │
│ Home  Batches Sales Cust More│
└─────────────────────────────┘
```

- `IndexedStack` preserves scroll position on each tab
- Active tab: `AppColors.primary`; inactive: `AppColors.textSecondary`
- Bottom nav elevation: 8dp with subtle shadow

---

## 5. Dashboard Screen

```
┌─────────────────────────────────┐
│  Green Market  🌿    [🔔]        │
│  Welcome, Ahmed                 │
├─────────────────────────────────┤
│                                 │
│  ┌────────┐  ┌────────┐         │
│  │Today's │  │Active  │         │
│  │Sales   │  │Batches │         │
│  │PKR     │  │ 7      │         │
│  │45,000  │  │        │         │
│  └────────┘  └────────┘         │
│  ┌────────┐  ┌────────┐         │
│  │Credit  │  │P&L     │         │
│  │Pending │  │This Mo.│         │
│  │PKR 1.2L│  │+23,400 │         │
│  └────────┘  └────────┘         │
│                                 │
│  ── Quick Actions ─────────     │
│  [+ New Batch] [+ New Sale]     │
│  [Record Payment]  [Reports]    │
│                                 │
│  ── Active Batches ────────     │
│  ┌─────────────────────────┐   │
│  │ GM-2026-0042 • Onions   │   │
│  │ Lahore → Islamabad      │   │
│  │ [selling] PKR 85,000    │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ GM-2026-0041 • Tomatoes │   │
│  │ Faisalabad → Rawalpindi │   │
│  │ [in_transit] PKR 32,000 │   │
│  └─────────────────────────┘   │
│  [View All Batches →]          │
│                                 │
│  ── Credit Alerts ─────────     │
│  ┌─────────────────────────┐   │
│  │ 🔴 Malik Traders        │   │
│  │ Outstanding: PKR 1,45,000│   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

**Components:**
- Summary cards: 2×2 grid, `GreenCard` with colored icon + amount
- Quick actions: 2×2 `OutlinedButton` grid with icons
- Active batches: `GreenCard` list tiles, tap → `BatchDetailScreen`
- Credit alerts: red-bordered cards for high balance customers

---

## 6. Batch Screens

### 6.1 BatchListScreen

```
┌─────────────────────────────────┐
│  ← Batches              [+ Add] │
├─────────────────────────────────┤
│  [Filter: All ▼] [Status ▼]     │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ [selling] GM-2026-0042  │   │
│  │ 🌿 Onions  |  50 bags   │   │
│  │ Lahore → Islamabad      │   │
│  │ Tariq ──→ Ahmed         │   │
│  │ Cost: 1,05,000  ▸       │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ [in_transit] GM-2026-0041│  │
│  │ 🍅 Tomatoes  |  200 kg  │   │
│  │ Faisalabad → Rawalpindi │   │
│  │ Total Cost: 32,000  ▸   │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

- Status filter dropdown: All / Purchased / Packed / In Transit / Delivered / Selling / Closed
- Each card taps to `BatchDetailScreen`
- FAB / AppBar `[+ Add]` → `CreateBatchScreen`

### 6.2 CreateBatchScreen (5-Step PageView Wizard)

**Progress Bar at top** — 5 segments, filled as steps complete.

**Step 1 — Product & Purchase**
```
┌─────────────────────────────────┐
│  ← New Batch  Step 1 of 5      │
│  ████░░░░░░░░░░░░░░░░░░░░░░░░  │
│  Product & Purchase Details     │
├─────────────────────────────────┤
│                                 │
│  Product *                      │
│  ┌──────────────────────────┐   │
│  │ Search products...       │   │
│  └──────────────────────────┘   │
│  [+ Create New Product]         │
│                                 │
│  Source Market *                │
│  ┌──────────────────────────┐   │
│  │ City ▼          Market ▼ │   │
│  └──────────────────────────┘   │
│                                 │
│  Destination Market *           │
│  ┌──────────────────────────┐   │
│  │ City ▼          Market ▼ │   │
│  └──────────────────────────┘   │
│                                 │
│  Purchase Date *   Total Qty *  │
│  [DD/MM/YYYY]      [____] kg    │
│                                 │
│  Price per Unit (PKR) *         │
│  [__________]                   │
│                                 │
│  Total Purchase Cost (auto)     │
│  PKR 1,25,000                   │
│                                 │
│              [Next Step →]      │
└─────────────────────────────────┘
```

**Step 2 — Partners**
```
┌─────────────────────────────────┐
│  ← New Batch  Step 2 of 5      │
│  ████████░░░░░░░░░░░░░░░░░░░░  │
│  Purchase & Sale Partners       │
├─────────────────────────────────┤
│  Purchasing Partner(s) *        │
│                                 │
│  ┌──────────────────────────┐   │
│  │ [PartnerChip: Tariq]  ✕ │   │
│  └──────────────────────────┘   │
│  [+ Add Purchasing Partner]     │
│                                 │
│  For Tariq:                     │
│  Daily Rate PKR  Days Involved  │
│  [1,500]         [3]            │
│  Subtotal: PKR 4,500 (auto)     │
│                                 │
│  ─────────────────────────      │
│  Selling Partner *              │
│  ┌──────────────────────────┐   │
│  │ [PartnerChip: Ahmed]  ✕  │   │
│  └──────────────────────────┘   │
│                                 │
│  Transport Amount (PKR)         │
│  [5,000]                        │
│  Paid by:  ● Purchaser          │
│            ○ Seller             │
│                                 │
│  [← Back]        [Next Step →]  │
└─────────────────────────────────┘
```

**Step 3 — Packing**
```
┌─────────────────────────────────┐
│  New Batch  Step 3 of 5         │
│  ████████████░░░░░░░░░░░░░░░░  │
│  Packing Details                │
├─────────────────────────────────┤
│  Packing Entry 1                │
│  Unit Type     Count  Per Unit  │
│  [5kg Packet] [60]   [PKR 15]   │
│  Total: PKR 900 (auto)          │
│                                 │
│  [+ Add Another Unit Type]      │
│                                 │
│  ─────────────────────          │
│  Total Packing Cost: PKR 900    │
│                                 │
│  (No packing yet? You can skip  │
│  and add packing later.)        │
│                                 │
│  [← Back]        [Next Step →]  │
└─────────────────────────────────┘
```

**Step 4 — Purchaser Expenses**
```
┌─────────────────────────────────┐
│  New Batch  Step 4 of 5         │
│  ████████████████░░░░░░░░░░░░  │
│  Purchaser Expenses             │
├─────────────────────────────────┤
│  (You can also add these later) │
│                                 │
│  ┌──────────────────────────┐   │
│  │ Labor Cost               │   │
│  │ [PKR 2,000]              │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌──────────────────────────┐   │
│  │ Accountant Fee           │   │
│  │ [PKR 500]                │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌──────────────────────────┐   │
│  │ Source Stall Fee         │   │
│  │ [PKR 800]                │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌──────────────────────────┐   │
│  │ Misc Expenses + note     │   │
│  │ [PKR 300]  [Description] │   │
│  └──────────────────────────┘   │
│                                 │
│  [← Back]        [Next Step →]  │
└─────────────────────────────────┘
```

**Step 5 — Review & Confirm**
```
┌─────────────────────────────────┐
│  New Batch  Step 5 of 5         │
│  ████████████████████████████  │
│  Review & Confirm               │
├─────────────────────────────────┤
│  📦 Onions — 50 bags            │
│  Lahore → Islamabad             │
│  Date: 05/08/2026               │
│                                 │
│  COST SUMMARY                   │
│  Purchase Cost      1,25,000    │
│  Tariq Daily Charges  4,500    │
│  Labor                2,000    │
│  Accountant Fee         500    │
│  Source Stall Fee       800    │
│  Packing (60×5kg pkt)   900    │
│  Transport             5,000    │
│  Misc                   300    │
│  ─────────────────────────      │
│  Total Cost so far  1,39,000    │
│                                 │
│  Cost per Bag (50 bags) 2,780   │
│                                 │
│  [← Back]  [✅ Create Batch]    │
└─────────────────────────────────┘
```

### 6.3 BatchDetailScreen (TabBar)

```
┌─────────────────────────────────┐
│  ← GM-2026-0042  [selling]      │
│  Overview | Expenses | Packing | Sales | P&L │
├─────────────────────────────────┤
│  [Tab content below]            │
└─────────────────────────────────┘
```

**Overview Tab:**
```
🌿 Onions
Lahore → Islamabad    05/08/2026

Purchasers: [Tariq Chip]
Seller:     [Ahmed Chip]

Qty Total: 50 bags
Qty Sold:  35 bags  (70%)
Remaining: 15 bags  ← colored amber

[████████████████░░░░░]  Sold progress bar

[Mark as Closed]  (visible only when batch eligible)
```

**Expenses Tab:**
```
PURCHASER SIDE          PKR 33,100
  Daily Charges  4,500
  Labor          2,000
  Accountant       500
  Stall Fee        800
  Misc             300
  Packing        25,000  ← from packing records

TRANSPORT               PKR 5,000
  (paid by: Purchaser)

SELLER SIDE             PKR 8,200
  Daily Charges  3,000
  Labor          1,500
  Local Trans.     800
  Stall Fee      1,200
  Misc             700

[+ Add Expense]  ← FAB (only if batch != closed)
```

Each expense row is swipeable (flutter_slidable) to show **Void** option (owner only).

**Packing Tab:**
```
PACKING RECORDS
  5kg Packets    60 × PKR 15  = PKR 900
  100kg Bags     0 entries

Total Packing Cost: PKR 900

[+ Add Packing Entry]
```

**Sales Tab:**
```
SALES RECORD
Total Sold: 35 bags  |  Revenue: PKR 87,500
Cash: PKR 57,500  |  Credit: PKR 30,000

  06/08   10 bags × 2500 = 25,000  [Cash]    Malik Traders
  07/08   15 bags × 2500 = 37,500  [Part]    Raza General
  08/08   10 bags × 2500 = 25,000  [Credit]  Walk-in

[+ Record Sale]  ← FAB (only seller role or owner)
```

**P&L Tab:**
```
P&L — GM-2026-0042
(Batch in progress — 15 bags remaining)

TOTAL COST         1,46,300
  Purchase Cost    1,25,000
  Purch. Expenses   33,100
  Transport          5,000
  Seller Expenses    8,200 ← not all logged yet

REVENUE             87,500
  Cash Received     57,500
  Credit Pending    30,000

CURRENT P&L        -58,800  🔴
(Expected on full sale: +18,200 estimated)

[Export PDF]
```

---

## 7. Sales Screens

### 7.1 SalesListScreen

```
┌─────────────────────────────────┐
│  ← Sales                [+]    │
│  [Filter: All ▼] [Date ▼]      │
├─────────────────────────────────┤
│  08/08  Malik Traders           │
│         10 bags Onions  25,000  │
│         [Cash]    GM-2026-0042  │
│                                 │
│  07/08  Raza General            │
│         15 bags Onions  37,500  │
│         [Partial] GM-2026-0042  │
│         Credit: 12,500          │
└─────────────────────────────────┘
```

### 7.2 SaleEntryScreen (Quick Sale)

```
┌─────────────────────────────────┐
│  ← Record Sale                  │
├─────────────────────────────────┤
│  Select Batch *                 │
│  ┌──────────────────────────┐   │
│  │ GM-2026-0042 Onions (15 │   │
│  │ bags remaining) ▼        │   │
│  └──────────────────────────┘   │
│  (only 'selling' status batches)│
│                                 │
│  Customer                       │
│  ┌──────────────────────────┐   │
│  │ Search customer...       │   │
│  └──────────────────────────┘   │
│  [Walk-in (no record)]          │
│                                 │
│  Quantity Sold *   Price/Unit * │
│  [10]  bags        [PKR 2,500]  │
│                                 │
│  Total: PKR 25,000  (auto)      │
│                                 │
│  Payment Mode:                  │
│  ● Full Cash                    │
│  ○ Full Credit                  │
│  ○ Partial (Cash + Credit)      │
│                                 │
│  [if Partial]:                  │
│  Cash Received: [PKR 12,500]    │
│  Credit Amount: PKR 12,500 (auto)│
│                                 │
│  Sale Date: [08/08/2026]        │
│  Notes: [optional]              │
│                                 │
│  [Save Sale]                    │
└─────────────────────────────────┘
```

---

## 8. Customer Screens

### 8.1 CustomerListScreen

```
┌─────────────────────────────────┐
│  ← Customers            [+]    │
│  [Search by name or phone...]   │
├─────────────────────────────────┤
│  Malik Traders                  │
│  Islamabad • 03xx-xxxxxxx       │
│  🔴 Outstanding: PKR 1,45,000   │
│                                 │
│  Raza General Store             │
│  Rawalpindi                     │
│  🟡 Outstanding: PKR 32,000     │
│                                 │
│  Ahmed Sabzi Mandi              │
│  Lahore                         │
│  🟢 Outstanding: PKR 0          │
└─────────────────────────────────┘
```

Color legend: 🟢 = 0, 🟡 = 1–49,999, 🔴 = 50,000+

### 8.2 CustomerDetailScreen

```
┌─────────────────────────────────┐
│  ← Malik Traders                │
├─────────────────────────────────┤
│  📞 03xx-xxxxxxx  📍 Islamabad  │
│  Shop: Malik Sabzi Corner       │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║  Outstanding Balance      ║  │
│  ║  PKR 1,45,000        🔴  ║  │
│  ║  [████████████░░░░░░░░░]  ║  │
│  ║  Paid: 80,000  Total: 225K║  │
│  ╚═══════════════════════════╝  │
│                                 │
│  LEDGER                         │
│  06/08  Sale (Onions 10 bags)   │
│         +25,000  Balance: 1,45K │
│  05/08  Payment received        │
│         -30,000  Balance: 1,20K │
│  04/08  Sale (Tomatoes 50kg)    │
│         +15,000  Balance: 1,50K │
│  ...                            │
│                                 │
│  [+ Record Payment]    ← FAB    │
└─────────────────────────────────┘
```

### 8.3 CustomerPaymentScreen

```
┌─────────────────────────────────┐
│  ← Record Payment               │
│  Malik Traders                  │
│  Current Balance: PKR 1,45,000  │
├─────────────────────────────────┤
│  Payment Amount *               │
│  [PKR ________________]         │
│                                 │
│  Payment Mode:                  │
│  ● Cash                         │
│  ○ Bank Transfer                │
│                                 │
│  [if Bank Transfer]:            │
│  Reference No.: [_________]     │
│                                 │
│  Date: [08/08/2026]             │
│  Notes: [optional]              │
│                                 │
│  Received by: Ahmed (auto)      │
│                                 │
│  New Balance after payment:     │
│  PKR 1,20,000  (auto preview)   │
│                                 │
│  [Record Payment]               │
└─────────────────────────────────┘
```

---

## 9. More Menu & Sub-screens

### 9.1 MoreScreen

```
┌─────────────────────────────────┐
│  More                           │
├─────────────────────────────────┤
│  👤  My Profile                  │
│  👥  Partners                    │
│  🏪  Markets & Cities            │
│  📊  Reports                     │
│  ⚙️  Settings                    │
│                                  │
│  ─────────────────────────       │
│  [Sign Out]                      │
└──────────────────────────────────┘
```

### 9.2 PartnerListScreen

```
┌─────────────────────────────────┐
│  ← Partners            [+]      │
├─────────────────────────────────┤
│  Tariq Ahmad                    │
│  Purchaser • Lahore  [editor]   │
│  ✅ Claimed                     │
│                                 │
│  Zafar Hussain                  │
│  Seller • Rawalpindi  [viewer]  │
│  ⏳ Not yet claimed             │
│  [Resend Invitation]            │
└─────────────────────────────────┘
```

### 9.3 PartnerDetailScreen

```
┌─────────────────────────────────┐
│  ← Tariq Ahmad                  │
├─────────────────────────────────┤
│  Role: Purchaser  Access: Editor│
│  City: Lahore • 03xx-xxxxxxx    │
│  Bank: HBL ****1234             │
│                                 │
│  [Change Access Level]  (owner) │
│                                 │
│  ASSOCIATED BATCHES             │
│  GM-2026-0042  Onions  selling  │
│  GM-2026-0039  Potatoes closed  │
│                                 │
│  BALANCE WITH ME                │
│  Tariq owes you: PKR 5,000      │
│  (Transport he should pay)      │
│  [Record Settlement]            │
└─────────────────────────────────┘
```

### 9.4 MarketManageScreen

```
┌─────────────────────────────────┐
│  ← Markets              [+]     │
├─────────────────────────────────┤
│  ISLAMABAD                      │
│    F-10 Sabzi Mandi  [wholesale]│
│    G-11 Retail Stall [retail]   │
│                                 │
│  LAHORE                         │
│    Badami Bagh Mandi [wholesale]│
│                                 │
│  RAWALPINDI                     │
│    Sabzi Mandi Raja Bazar       │
└─────────────────────────────────┘
```

### 9.5 ReportsScreen

```
┌─────────────────────────────────┐
│  ← Reports                      │
├─────────────────────────────────┤
│  Date Range:                    │
│  [01/08/2026] to [08/08/2026]   │
│  [Apply]                        │
├─────────────────────────────────┤
│  BUSINESS SUMMARY               │
│  Total Batches:  12             │
│  Total Revenue:  PKR 8,45,000   │
│  Cash Received:  PKR 6,20,000   │
│  Credit Pending: PKR 2,25,000   │
│  Net P&L:        PKR +1,23,000  │
│                                 │
│  [Bar chart: Revenue vs Cost    │
│   by week/month]                │
│                                 │
│  CUSTOMER CREDIT OUTSTANDING    │
│  Malik Traders      1,45,000 🔴 │
│  Raza General          32,000 🟡│
│                                 │
│  [Export Full Report PDF]       │
└─────────────────────────────────┘
```

---

## 10. Shared Components

### 10.1 AddExpenseScreen (Bottom Sheet or Full Screen)

```
┌─────────────────────────────────┐
│  ← Add Expense                  │
│  Batch GM-2026-0042             │
├─────────────────────────────────┤
│  Expense Side:                  │
│  [Purchaser] [Transport] [Seller]│
│   ──────────                    │
│                                 │
│  Expense Type: (chips)          │
│  [Labor] [Daily Charge]         │
│  [Stall Fee] [Misc]             │
│  (changes based on side)        │
│                                 │
│  Amount (PKR) *                 │
│  [__________]                   │
│                                 │
│  Description                    │
│  [optional]                     │
│                                 │
│  Paid By                        │
│  [Partner dropdown]             │
│                                 │
│  Payment Mode:                  │
│  ● Cash  ○ Bank Transfer        │
│                                 │
│  Date: [08/08/2026]             │
│                                 │
│  [Save Expense]                 │
└─────────────────────────────────┘
```

### 10.2 LoadingOverlay

```dart
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black38,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
```

### 10.3 EmptyState

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;
  ...
}
```

### 10.4 ConfirmDialog

Used before voiding expenses, closing batches, recording large payments:

```dart
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  Color confirmColor = AppColors.loss,
}) async { ... }
```

---

## 11. UX Flows (Step by Step)

### Flow 1 — Record a Sale (Quick, ~8 taps, target < 60 seconds)
1. Tap **Sales** tab
2. Tap **[+]** or dashboard Quick Action "New Sale"
3. Select batch from dropdown (only `selling` batches, with remaining qty shown)
4. Search/select customer OR tap "Walk-in"
5. Enter quantity and price per unit — total auto-calculates
6. Select payment mode: Full Cash / Full Credit / Partial
7. If Partial: enter cash received — credit auto-fills
8. Tap **[Save Sale]** → Snackbar: "Sale saved ✅" → screen pops

### Flow 2 — Create Full Batch (5-step wizard)
1. Tap **Batches** tab → tap **[+]**
2. Step 1: Select product, source/destination market, date, qty, price
3. Step 2: Add purchasing partner(s) with daily rate + days; select seller; set transport
4. Step 3: Add packing entries (unit type, count, cost) — can skip
5. Step 4: Enter initial purchaser expenses — can skip (add later)
6. Step 5: Review full cost summary → tap **[Create Batch]** → redirected to `BatchDetailScreen`

### Flow 3 — Check Profit on a Batch
1. From batch list or dashboard, tap batch card
2. On `BatchDetailScreen` → tap **P&L** tab
3. See full cost breakdown + revenue + current profit/loss
4. If batch is closed: final P&L shown with green/red hero number
5. Tap **[Export PDF]** → system share sheet opens

### Flow 4 — Customer Pays Back Credit
1. Tap **Customers** tab
2. Tap customer card
3. See outstanding balance highlighted
4. Tap **[+ Record Payment]** FAB
5. Enter amount, mode (cash/bank), date
6. See live preview of new balance below amount field
7. Tap **[Record Payment]** → balance updates → ledger entry appears

### Flow 5 — Create Unclaimed Partner Profile (owner creates for partner who isn't on the app yet)
1. Tap **More** → **Partners** → **[+]**
2. Enter partner name, phone, city, role
3. **Do not** invite — just save
4. Partner shows as "⏳ Not yet claimed" in list
5. When that partner installs app and signs up with same phone → auto-claimed
6. Owner sees "✅ Claimed" on partner card

---

## 12. Offline & Error States

### Offline Banner
```dart
// Shown at top of screen when connectivity lost
Container(
  width: double.infinity,
  color: Colors.orange,
  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
  child: Row(
    children: [
      Icon(Icons.wifi_off, color: Colors.white, size: 16),
      SizedBox(width: 8),
      Text('No internet — showing cached data', style: TextStyle(color: Colors.white)),
    ],
  ),
)
```

### Write Operation Error (no internet)
```
SnackBar(
  content: Text('❌ No internet connection. Sale not saved.'),
  backgroundColor: AppColors.loss,
  action: SnackBarAction(label: 'Retry', onPressed: retryFn),
)
```

### Empty States

| Screen | Empty State Message |
|--------|-------------------|
| Batch list | "No batches yet. Tap + to create your first batch." |
| Sales tab | "No sales recorded yet. Tap + to record a sale." |
| Customer list | "No customers yet. Tap + to add your first customer." |
| Expenses tab | "No expenses logged yet. Tap + to add an expense." |
| Partner list | "No partners added. Tap + to add a partner." |

### Loading State
Every list screen shows `Shimmer` skeleton tiles while loading from Supabase. Avoids jarring blank-then-filled transitions.

```dart
// Shimmer placeholder
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: Container(height: 80, decoration: BoxDecoration(
    color: Colors.white, borderRadius: BorderRadius.circular(12),
  )),
)
```
