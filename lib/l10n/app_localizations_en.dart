// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MandiRoznamcha';

  @override
  String get appSubtitle => 'Wholesale Management Platform';

  @override
  String get navHome => 'Home';

  @override
  String get navBatches => 'Batches';

  @override
  String get navSales => 'Sales';

  @override
  String get navCustomers => 'Customers';

  @override
  String get menuProfile => 'My Profile';

  @override
  String get menuBusinessInfo => 'Business Info';

  @override
  String get menuSwitchBusiness => 'Switch / Add Business';

  @override
  String get menuAccessManagement => 'Access Management';

  @override
  String get menuNotifications => 'Notifications';

  @override
  String get menuHelpCenter => 'Help Center';

  @override
  String get menuAbout => 'About';

  @override
  String get menuLogout => 'Log out';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRequired => 'Required';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logout => 'Log out';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get authRequired => 'Please sign in to continue';

  @override
  String get dashboardGreetingFallback => 'Good to see you';

  @override
  String dashboardGreeting(Object name) {
    return 'Good to see you, $name';
  }

  @override
  String get dashboardRevenueTitle => 'Today\'s Revenue';

  @override
  String get dashboardRevenueSubtitle => 'Gross sales recorded today across all batches';

  @override
  String get dashboardCredit => 'Outstanding Credit';

  @override
  String get dashboardCustomers => 'Customers';

  @override
  String get dashboardBatches => 'Total Batches';

  @override
  String get dashboardProducts => 'Products';

  @override
  String get dashboardQuickActions => 'Quick operations';

  @override
  String get dashboardQuickNewBatch => 'New Batch';

  @override
  String get dashboardQuickNewSale => 'Quick Sale';

  @override
  String get dashboardQuickRecordPayment => 'Record Payment';

  @override
  String get dashboardQuickReports => 'Reports';

  @override
  String get dashboardCreditAlerts => 'Credit alerts';

  @override
  String get dashboardRecentBatches => 'Recent batches';

  @override
  String get dashboardNoOverdue => 'No overdue customers.';

  @override
  String get emptyCustomersTitle => 'No customers yet';

  @override
  String get emptyCustomersSubtitle => 'Add your first customer to start recording credit sales.';

  @override
  String get emptyBatchesTitle => 'No batches yet';

  @override
  String get emptyBatchesSubtitle => 'Create your first batch to start tracking produce from purchase to sale.';

  @override
  String get emptySalesTitle => 'No batches on sale yet';

  @override
  String get emptySalesSubtitle => 'Move a batch to \'selling\' status to start recording revenue against it.';

  @override
  String get emptyPartnersTitle => 'No partners yet';

  @override
  String get emptyPartnersSubtitle => 'Add partners to track balances and settlements.';

  @override
  String get batchesScreenTitle => 'Batches';

  @override
  String get batchesSearchHint => 'Search by batch code or product';

  @override
  String get batchesCreateCta => 'New Batch';

  @override
  String get batchesCreateTitle => 'Batch lifecycle';

  @override
  String get batchesCreateSubtitle => 'Follow produce from purchase to selling, with transport, packing, and P&L in one timeline.';

  @override
  String batchesStepLabel(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get batchesStep1Title => 'Product & Purchase';

  @override
  String get batchesStep2Title => 'Purchasing Partners';

  @override
  String get batchesStep3Title => 'Packing';

  @override
  String get batchesStep4Title => 'Purchaser Expenses';

  @override
  String get batchesStep5Title => 'Review & Confirm';

  @override
  String get batchesSummary => 'Summary';

  @override
  String get batchesSave => 'Confirm & Create';

  @override
  String get batchesNext => 'Next';

  @override
  String get batchesBack => 'Back';

  @override
  String get batchesAdvanceStatus => 'Advance Status';

  @override
  String get batchesClosedPill => 'Closed — read only. Edits, packing, expenses and sales are locked.';

  @override
  String get batchesMarkAsClosed => 'Mark as closed';

  @override
  String get batchesSoldRemaining => 'Sold vs Remaining';

  @override
  String get batchesSold => 'Sold';

  @override
  String get batchesRemaining => 'Remaining';

  @override
  String batchesTotalSuffix(Object unit, Object value) {
    return 'Total $value $unit';
  }

  @override
  String get batchStatusPurchased => 'Purchased';

  @override
  String get batchStatusPacked => 'Packed';

  @override
  String get batchStatusInTransit => 'In transit';

  @override
  String get batchStatusDelivered => 'Delivered';

  @override
  String get batchStatusSelling => 'Selling';

  @override
  String get batchStatusClosed => 'Closed';

  @override
  String get salesScreenTitle => 'Sales';

  @override
  String get salesRecordCta => 'Record Sale';

  @override
  String get salesRecordNewTitle => 'Revenue capture';

  @override
  String get salesRecordNewSubtitle => 'Sales are tied to active selling batches so revenue and credit stay aligned with P&L.';

  @override
  String get saleEntryTitle => 'Record Sale';

  @override
  String saleEntryQuantityLabel(Object unit) {
    return 'Quantity ($unit)';
  }

  @override
  String saleEntryRemainingHelper(Object remaining, Object total, Object unit) {
    return 'Only $remaining $unit remaining (of $total)';
  }

  @override
  String get saleEntryQuantityError => 'Exceeds remaining quantity';

  @override
  String get saleEntryPriceLabel => 'Price per unit';

  @override
  String get saleEntryPaymentLabel => 'Payment mode';

  @override
  String get saleEntryCustomerLabel => 'Customer';

  @override
  String get saleEntrySave => 'Save Sale';

  @override
  String get saleRecordedSnack => 'Sale recorded';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCredit => 'Credit';

  @override
  String get paymentPartialCredit => 'Partial Credit';

  @override
  String get paymentBankTransfer => 'Bank Transfer';

  @override
  String get customersScreenTitle => 'Customers';

  @override
  String get customersSearchHint => 'Search by name, phone, or shop';

  @override
  String get customersCreateCta => 'New Customer';

  @override
  String get customersAddTitle => 'Outstanding balance';

  @override
  String get customersNoBalance => 'No balance owed';

  @override
  String get customersRecordPayment => 'Record Payment';

  @override
  String get customerFullName => 'Full name';

  @override
  String get customerPhone => 'Phone';

  @override
  String get customerCity => 'City';

  @override
  String get customerShop => 'Shop / stall';

  @override
  String get customerOptionalPhone => 'Optional';

  @override
  String get recordPaymentAmount => 'Amount';

  @override
  String get recordPaymentMode => 'Payment mode';

  @override
  String get recordPaymentBankRef => 'Bank reference';

  @override
  String get recordPaymentNotes => 'Notes';

  @override
  String get recordPaymentSave => 'Save Payment';

  @override
  String get recordPaymentRecorded => 'Payment recorded successfully';

  @override
  String recordPaymentExceeds(Object balance) {
    return 'Amount exceeds outstanding balance of $balance';
  }

  @override
  String get archive => 'Archive';

  @override
  String get archived => 'Archived';

  @override
  String archiveUndone(Object name) {
    return '$name archived';
  }

  @override
  String get archiveUndo => 'Undo';

  @override
  String get restored => 'Restored';

  @override
  String get archiveRestoreFailed => 'Failed to restore';

  @override
  String archivePromptTitle(Object name) {
    return 'Archive $name?';
  }

  @override
  String get archivePromptMessage => 'Archived customers are hidden from the list and excluded from reports. You can restore them later.';

  @override
  String get archiveFailed => 'Failed to archive';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSupport => 'Support';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageUrdu => 'Urdu';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsAlertsSection => 'Alerts';

  @override
  String get notificationsCreditAlerts => 'Credit alerts';

  @override
  String get notificationsCreditAlertsDesc => 'Get notified when a customer crosses the credit threshold.';

  @override
  String get notificationsBatchUpdates => 'Batch updates';

  @override
  String get notificationsBatchUpdatesDesc => 'Batch status changes and new batch activity.';

  @override
  String get notificationsExpenseApprovals => 'Expense approvals';

  @override
  String get notificationsExpenseApprovalsDesc => 'When a partner or expense needs attention.';

  @override
  String get notificationsDailySummary => 'Daily summary';

  @override
  String get notificationsDailySummaryDesc => 'A daily digest of sales, credit and P&L.';

  @override
  String get notificationsSave => 'Save Preferences';

  @override
  String get notificationsSaved => 'Notification preferences saved';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterStillNeed => 'Still need help?';

  @override
  String get helpCenterContact => 'Contact support and we\'ll get back to you within 24 hours.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutPublisher => 'Publisher';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPurpose => 'Purpose';

  @override
  String get aboutPrivacy => 'Privacy';

  @override
  String aboutCopyright(Object year) {
    return '© $year MandiRoznamcha. All rights reserved.';
  }

  @override
  String get aboutTracking => 'Track batches, sales, expenses and partner P&L for wholesale traders.';

  @override
  String get aboutDataStorage => 'Your data is stored securely in the cloud and synced to this device.';

  @override
  String get aboutOffline => 'Offline mode is planned. Currently an active connection is required.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get roleAccountant => 'Accountant';

  @override
  String get roleMember => 'Member';

  @override
  String get offlineBanner => 'You are offline. Showing cached data where possible.';
}
