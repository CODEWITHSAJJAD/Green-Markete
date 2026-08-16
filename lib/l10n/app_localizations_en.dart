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
  String get appSubtitle => 'Pakistan\'s Digital Mandi & Wholesale OS';

  @override
  String get navHome => 'Home';

  @override
  String get navBatches => 'Aamad Maal / Lots';

  @override
  String get navSales => 'Bikri & Boli';

  @override
  String get navCustomers => 'Khareedar Khata';

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
  String get dashboardRevenueTitle => 'Today\'s Bikri';

  @override
  String get dashboardRevenueSubtitle => 'Gross sales recorded today across all Mandi lots';

  @override
  String get dashboardCredit => 'Market Baqayaat (Khata Dues)';

  @override
  String get dashboardCustomers => 'Khareedar Directory';

  @override
  String get dashboardBatches => 'Live Mandi Lots';

  @override
  String get dashboardProducts => 'Produce Lines';

  @override
  String get dashboardQuickActions => 'Quick Operations';

  @override
  String get dashboardQuickNewBatch => 'New Aamad Maal';

  @override
  String get dashboardQuickNewSale => 'Quick Bikri';

  @override
  String get dashboardQuickRecordPayment => 'Collect Wasooli';

  @override
  String get dashboardQuickReports => 'P&L Reports';

  @override
  String get dashboardCreditAlerts => 'Baqaya Dues Monitor';

  @override
  String get dashboardRecentBatches => 'Recent Mandi Lots';

  @override
  String get dashboardNoOverdue => 'All buyer accounts settled.';

  @override
  String get emptyCustomersTitle => 'No Khareedar records yet';

  @override
  String get emptyCustomersSubtitle => 'Add your first buyer to start recording credit sales.';

  @override
  String get emptyBatchesTitle => 'No Mandi lots recorded yet';

  @override
  String get emptyBatchesSubtitle => 'Log your first produce arrival to start tracking lots from Zamindar to Boli sale.';

  @override
  String get emptySalesTitle => 'No lots currently on Boli sale';

  @override
  String get emptySalesSubtitle => 'Advance an arrival lot to \'selling\' status to start recording Bikri against it.';

  @override
  String get emptyPartnersTitle => 'No partners or Munshi added yet';

  @override
  String get emptyPartnersSubtitle => 'Add business partners or accountants to track balances and Safaya.';

  @override
  String get batchesScreenTitle => 'Aamad Maal / Lots';

  @override
  String get batchesSearchHint => 'Search by lot code, produce or Zamindar';

  @override
  String get batchesCreateCta => 'New Lot Arrival';

  @override
  String get batchesCreateTitle => 'Mandi Lot Lifecycle';

  @override
  String get batchesCreateSubtitle => 'Follow produce from Mandi arrival to Boli selling, with transport, packing, and Safaya in one timeline.';

  @override
  String batchesStepLabel(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get batchesStep1Title => 'Produce & Zamindar / Purchase';

  @override
  String get batchesStep2Title => 'Partners & Arhat';

  @override
  String get batchesStep3Title => 'Packing & Bardana';

  @override
  String get batchesStep4Title => 'Palledari & Mandi Expenses';

  @override
  String get batchesStep5Title => 'Review & Confirm';

  @override
  String get batchesSummary => 'Lot Summary';

  @override
  String get batchesSave => 'Confirm & Log Arrival';

  @override
  String get batchesNext => 'Next Step';

  @override
  String get batchesBack => 'Back';

  @override
  String get batchesAdvanceStatus => 'Advance Lot Status';

  @override
  String get batchesClosedPill => 'Safaya Done — read only. Edits, packing, expenses and sales are locked.';

  @override
  String get batchesMarkAsClosed => 'Mark as Safaya Done (Close Lot)';

  @override
  String get batchesSoldRemaining => 'Sold vs Remaining Stock';

  @override
  String get batchesSold => 'Bikri (Sold)';

  @override
  String get batchesRemaining => 'Baqaya Stock';

  @override
  String batchesTotalSuffix(Object unit, Object value) {
    return 'Total $value $unit';
  }

  @override
  String get batchStatusPurchased => 'Aamad / Purchased';

  @override
  String get batchStatusPacked => 'Packed / Bardana';

  @override
  String get batchStatusInTransit => 'In Transit / Gaari';

  @override
  String get batchStatusDelivered => 'Delivered / Mandi Arrived';

  @override
  String get batchStatusSelling => 'Boli & Selling';

  @override
  String get batchStatusClosed => 'Safaya Done (Closed)';

  @override
  String get salesScreenTitle => 'Bikri & Boli';

  @override
  String get salesRecordCta => 'Record Bikri / Boli';

  @override
  String get salesRecordNewTitle => 'Bikri & Boli Entry';

  @override
  String get salesRecordNewSubtitle => 'Bikri is tied to active selling lots so revenue and credit stay aligned with Safaya and Khata.';

  @override
  String get saleEntryTitle => 'Record Bikri (Sale Parchi)';

  @override
  String saleEntryQuantityLabel(Object unit) {
    return 'Quantity ($unit)';
  }

  @override
  String saleEntryRemainingHelper(Object remaining, Object total, Object unit) {
    return 'Only $remaining $unit remaining in lot (of $total)';
  }

  @override
  String get saleEntryQuantityError => 'Exceeds remaining lot quantity';

  @override
  String get saleEntryPriceLabel => 'Boli Rate / Price per unit';

  @override
  String get saleEntryPaymentLabel => 'Payment mode';

  @override
  String get saleEntryCustomerLabel => 'Khareedar / Buyer';

  @override
  String get saleEntrySave => 'Save Bikri Parchi';

  @override
  String get saleRecordedSnack => 'Bikri recorded & Parchi generated';

  @override
  String get paymentCash => 'Naqd (Cash)';

  @override
  String get paymentCredit => 'Udhar (Credit Khata)';

  @override
  String get paymentPartialCredit => 'Partial Credit';

  @override
  String get paymentBankTransfer => 'Bank Transfer';

  @override
  String get customersScreenTitle => 'Khareedar Khata';

  @override
  String get customersSearchHint => 'Search by buyer name, phone, or shop';

  @override
  String get customersCreateCta => 'New Khareedar';

  @override
  String get customersAddTitle => 'Khata & Baqaya Wasooli';

  @override
  String get customersNoBalance => 'No outstanding balance';

  @override
  String get customersRecordPayment => 'Collect Wasooli';

  @override
  String get customerFullName => 'Buyer Full Name';

  @override
  String get customerPhone => 'WhatsApp / Phone';

  @override
  String get customerCity => 'City / Mandi';

  @override
  String get customerShop => 'Shop / Phari Name';

  @override
  String get customerOptionalPhone => 'Optional';

  @override
  String get recordPaymentAmount => 'Wasooli Amount (Rs.)';

  @override
  String get recordPaymentMode => 'Payment mode';

  @override
  String get recordPaymentBankRef => 'Bank reference / Cheque';

  @override
  String get recordPaymentNotes => 'Khata Notes';

  @override
  String get recordPaymentSave => 'Save Wasooli';

  @override
  String get recordPaymentRecorded => 'Wasooli recorded successfully';

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
  String get archivePromptMessage => 'Archived buyers are hidden from the list and excluded from reports. You can restore them later.';

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
  String get notificationsCreditAlerts => 'Khata Credit Alerts';

  @override
  String get notificationsCreditAlertsDesc => 'Get notified when a buyer crosses the credit limit threshold.';

  @override
  String get notificationsBatchUpdates => 'Aamad Maal Updates';

  @override
  String get notificationsBatchUpdatesDesc => 'Lot status changes and vehicle arrivals.';

  @override
  String get notificationsExpenseApprovals => 'Expense Approvals';

  @override
  String get notificationsExpenseApprovalsDesc => 'When Palledari or Mandi expenses need approval.';

  @override
  String get notificationsDailySummary => 'Daily Roznamcha Summary';

  @override
  String get notificationsDailySummaryDesc => 'Daily digest of Bikri, Wasooli, and net balance.';

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
  String get aboutTracking => 'Manage Mandi arrivals, Boli auctions, Bikri Parchis, Zamindar Safaya bills, and Khareedar Khata.';

  @override
  String get aboutDataStorage => 'Your data is stored securely in the cloud and synced to this device.';

  @override
  String get aboutOffline => 'Offline mode is planned. Currently an active connection is required.';

  @override
  String get roleOwner => 'Arthi / Owner';

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get roleAccountant => 'Munshi / Accountant';

  @override
  String get roleMember => 'Hissedar / Partner';

  @override
  String get offlineBanner => 'You are offline. Showing cached data where possible.';
}
