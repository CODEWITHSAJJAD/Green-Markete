import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MandiRoznamcha'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pakistan\'s Digital Mandi & Wholesale OS'**
  String get appSubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBatches.
  ///
  /// In en, this message translates to:
  /// **'Batches'**
  String get navBatches;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get menuProfile;

  /// No description provided for @menuBusinessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get menuBusinessInfo;

  /// No description provided for @menuSwitchBusiness.
  ///
  /// In en, this message translates to:
  /// **'Switch / Add Business'**
  String get menuSwitchBusiness;

  /// No description provided for @menuAccessManagement.
  ///
  /// In en, this message translates to:
  /// **'Access Management'**
  String get menuAccessManagement;

  /// No description provided for @menuNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get menuNotifications;

  /// No description provided for @menuHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get menuHelpCenter;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAbout;

  /// No description provided for @menuLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get menuLogout;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue'**
  String get authRequired;

  /// No description provided for @dashboardGreetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Good to see you'**
  String get dashboardGreetingFallback;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good to see you, {name}'**
  String dashboardGreeting(Object name);

  /// No description provided for @dashboardRevenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get dashboardRevenueTitle;

  /// No description provided for @dashboardRevenueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gross sales recorded today across all batches'**
  String get dashboardRevenueSubtitle;

  /// No description provided for @dashboardCredit.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Credit'**
  String get dashboardCredit;

  /// No description provided for @dashboardCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get dashboardCustomers;

  /// No description provided for @dashboardBatches.
  ///
  /// In en, this message translates to:
  /// **'Total Batches'**
  String get dashboardBatches;

  /// No description provided for @dashboardProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get dashboardProducts;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardQuickNewBatch.
  ///
  /// In en, this message translates to:
  /// **'New Batch'**
  String get dashboardQuickNewBatch;

  /// No description provided for @dashboardQuickNewSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get dashboardQuickNewSale;

  /// No description provided for @dashboardQuickRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get dashboardQuickRecordPayment;

  /// No description provided for @dashboardQuickReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dashboardQuickReports;

  /// No description provided for @dashboardCreditAlerts.
  ///
  /// In en, this message translates to:
  /// **'Credit alerts'**
  String get dashboardCreditAlerts;

  /// No description provided for @dashboardRecentBatches.
  ///
  /// In en, this message translates to:
  /// **'Recent batches'**
  String get dashboardRecentBatches;

  /// No description provided for @dashboardNoOverdue.
  ///
  /// In en, this message translates to:
  /// **'No overdue customers.'**
  String get dashboardNoOverdue;

  /// No description provided for @emptyCustomersTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get emptyCustomersTitle;

  /// No description provided for @emptyCustomersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first customer to start recording credit sales.'**
  String get emptyCustomersSubtitle;

  /// No description provided for @emptyBatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No batches yet'**
  String get emptyBatchesTitle;

  /// No description provided for @emptyBatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first batch to start tracking produce from purchase to sale.'**
  String get emptyBatchesSubtitle;

  /// No description provided for @emptySalesTitle.
  ///
  /// In en, this message translates to:
  /// **'No batches on sale yet'**
  String get emptySalesTitle;

  /// No description provided for @emptySalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move a batch to \'selling\' status to start recording revenue against it.'**
  String get emptySalesSubtitle;

  /// No description provided for @emptyPartnersTitle.
  ///
  /// In en, this message translates to:
  /// **'No partners yet'**
  String get emptyPartnersTitle;

  /// No description provided for @emptyPartnersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add partners to track balances and settlements.'**
  String get emptyPartnersSubtitle;

  /// No description provided for @batchesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Batches'**
  String get batchesScreenTitle;

  /// No description provided for @batchesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by batch code or product'**
  String get batchesSearchHint;

  /// No description provided for @batchesCreateCta.
  ///
  /// In en, this message translates to:
  /// **'New Batch'**
  String get batchesCreateCta;

  /// No description provided for @batchesCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch lifecycle'**
  String get batchesCreateTitle;

  /// No description provided for @batchesCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow produce from purchase to selling, with transport, packing, and P&L in one timeline.'**
  String get batchesCreateSubtitle;

  /// No description provided for @batchesStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String batchesStepLabel(Object current, Object total);

  /// No description provided for @batchesStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Product & Purchase'**
  String get batchesStep1Title;

  /// No description provided for @batchesStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Purchasing Partners'**
  String get batchesStep2Title;

  /// No description provided for @batchesStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get batchesStep3Title;

  /// No description provided for @batchesStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Purchaser Expenses'**
  String get batchesStep4Title;

  /// No description provided for @batchesStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Review & Confirm'**
  String get batchesStep5Title;

  /// No description provided for @batchesSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get batchesSummary;

  /// No description provided for @batchesSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Create'**
  String get batchesSave;

  /// No description provided for @batchesNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get batchesNext;

  /// No description provided for @batchesBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get batchesBack;

  /// No description provided for @batchesAdvanceStatus.
  ///
  /// In en, this message translates to:
  /// **'Advance Status'**
  String get batchesAdvanceStatus;

  /// No description provided for @batchesClosedPill.
  ///
  /// In en, this message translates to:
  /// **'Closed — read only. Edits, packing, expenses and sales are locked.'**
  String get batchesClosedPill;

  /// No description provided for @batchesMarkAsClosed.
  ///
  /// In en, this message translates to:
  /// **'Mark as closed'**
  String get batchesMarkAsClosed;

  /// No description provided for @batchesSoldRemaining.
  ///
  /// In en, this message translates to:
  /// **'Sold vs Remaining'**
  String get batchesSoldRemaining;

  /// No description provided for @batchesSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get batchesSold;

  /// No description provided for @batchesRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get batchesRemaining;

  /// No description provided for @batchesTotalSuffix.
  ///
  /// In en, this message translates to:
  /// **'Total {value} {unit}'**
  String batchesTotalSuffix(Object unit, Object value);

  /// No description provided for @batchStatusPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get batchStatusPurchased;

  /// No description provided for @batchStatusPacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get batchStatusPacked;

  /// No description provided for @batchStatusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get batchStatusInTransit;

  /// No description provided for @batchStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get batchStatusDelivered;

  /// No description provided for @batchStatusSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get batchStatusSelling;

  /// No description provided for @batchStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get batchStatusClosed;

  /// No description provided for @salesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesScreenTitle;

  /// No description provided for @salesRecordCta.
  ///
  /// In en, this message translates to:
  /// **'Record Sale'**
  String get salesRecordCta;

  /// No description provided for @salesRecordNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue capture'**
  String get salesRecordNewTitle;

  /// No description provided for @salesRecordNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales are tied to active selling batches so revenue and credit stay aligned with P&L.'**
  String get salesRecordNewSubtitle;

  /// No description provided for @saleEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Sale'**
  String get saleEntryTitle;

  /// No description provided for @saleEntryQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String saleEntryQuantityLabel(Object unit);

  /// No description provided for @saleEntryRemainingHelper.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} {unit} remaining (of {total})'**
  String saleEntryRemainingHelper(Object remaining, Object total, Object unit);

  /// No description provided for @saleEntryQuantityError.
  ///
  /// In en, this message translates to:
  /// **'Exceeds remaining quantity'**
  String get saleEntryQuantityError;

  /// No description provided for @saleEntryPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get saleEntryPriceLabel;

  /// No description provided for @saleEntryPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment mode'**
  String get saleEntryPaymentLabel;

  /// No description provided for @saleEntryCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get saleEntryCustomerLabel;

  /// No description provided for @saleEntrySave.
  ///
  /// In en, this message translates to:
  /// **'Save Sale'**
  String get saleEntrySave;

  /// No description provided for @saleRecordedSnack.
  ///
  /// In en, this message translates to:
  /// **'Sale recorded'**
  String get saleRecordedSnack;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get paymentCredit;

  /// No description provided for @paymentPartialCredit.
  ///
  /// In en, this message translates to:
  /// **'Partial Credit'**
  String get paymentPartialCredit;

  /// No description provided for @paymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentBankTransfer;

  /// No description provided for @customersScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersScreenTitle;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, or shop'**
  String get customersSearchHint;

  /// No description provided for @customersCreateCta.
  ///
  /// In en, this message translates to:
  /// **'New Customer'**
  String get customersCreateCta;

  /// No description provided for @customersAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get customersAddTitle;

  /// No description provided for @customersNoBalance.
  ///
  /// In en, this message translates to:
  /// **'No balance owed'**
  String get customersNoBalance;

  /// No description provided for @customersRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get customersRecordPayment;

  /// No description provided for @customerFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get customerFullName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customerPhone;

  /// No description provided for @customerCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get customerCity;

  /// No description provided for @customerShop.
  ///
  /// In en, this message translates to:
  /// **'Shop / stall'**
  String get customerShop;

  /// No description provided for @customerOptionalPhone.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get customerOptionalPhone;

  /// No description provided for @recordPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recordPaymentAmount;

  /// No description provided for @recordPaymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment mode'**
  String get recordPaymentMode;

  /// No description provided for @recordPaymentBankRef.
  ///
  /// In en, this message translates to:
  /// **'Bank reference'**
  String get recordPaymentBankRef;

  /// No description provided for @recordPaymentNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get recordPaymentNotes;

  /// No description provided for @recordPaymentSave.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get recordPaymentSave;

  /// No description provided for @recordPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get recordPaymentRecorded;

  /// No description provided for @recordPaymentExceeds.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds outstanding balance of {balance}'**
  String recordPaymentExceeds(Object balance);

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @archiveUndone.
  ///
  /// In en, this message translates to:
  /// **'{name} archived'**
  String archiveUndone(Object name);

  /// No description provided for @archiveUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get archiveUndo;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restored;

  /// No description provided for @archiveRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore'**
  String get archiveRestoreFailed;

  /// No description provided for @archivePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String archivePromptTitle(Object name);

  /// No description provided for @archivePromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Archived customers are hidden from the list and excluded from reports. You can restore them later.'**
  String get archivePromptMessage;

  /// No description provided for @archiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to archive'**
  String get archiveFailed;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get settingsLanguageUrdu;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsAlertsSection.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get notificationsAlertsSection;

  /// No description provided for @notificationsCreditAlerts.
  ///
  /// In en, this message translates to:
  /// **'Credit alerts'**
  String get notificationsCreditAlerts;

  /// No description provided for @notificationsCreditAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a customer crosses the credit threshold.'**
  String get notificationsCreditAlertsDesc;

  /// No description provided for @notificationsBatchUpdates.
  ///
  /// In en, this message translates to:
  /// **'Batch updates'**
  String get notificationsBatchUpdates;

  /// No description provided for @notificationsBatchUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Batch status changes and new batch activity.'**
  String get notificationsBatchUpdatesDesc;

  /// No description provided for @notificationsExpenseApprovals.
  ///
  /// In en, this message translates to:
  /// **'Expense approvals'**
  String get notificationsExpenseApprovals;

  /// No description provided for @notificationsExpenseApprovalsDesc.
  ///
  /// In en, this message translates to:
  /// **'When a partner or expense needs attention.'**
  String get notificationsExpenseApprovalsDesc;

  /// No description provided for @notificationsDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily summary'**
  String get notificationsDailySummary;

  /// No description provided for @notificationsDailySummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'A daily digest of sales, credit and P&L.'**
  String get notificationsDailySummaryDesc;

  /// No description provided for @notificationsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get notificationsSave;

  /// No description provided for @notificationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences saved'**
  String get notificationsSaved;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterStillNeed.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get helpCenterStillNeed;

  /// No description provided for @helpCenterContact.
  ///
  /// In en, this message translates to:
  /// **'Contact support and we\'ll get back to you within 24 hours.'**
  String get helpCenterContact;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get aboutPublisher;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get aboutPurpose;

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aboutPrivacy;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} MandiRoznamcha. All rights reserved.'**
  String aboutCopyright(Object year);

  /// No description provided for @aboutTracking.
  ///
  /// In en, this message translates to:
  /// **'Manage Mandi arrivals, Boli auctions, Bikri Parchis, Zamindar Safaya bills, and Khareedar Khata.'**
  String get aboutTracking;

  /// No description provided for @aboutDataStorage.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored securely in the cloud and synced to this device.'**
  String get aboutDataStorage;

  /// No description provided for @aboutOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline mode is planned. Currently an active connection is required.'**
  String get aboutOffline;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get roleEditor;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing cached data where possible.'**
  String get offlineBanner;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ur': return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
