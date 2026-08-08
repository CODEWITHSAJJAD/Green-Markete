// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'گرین مارکیٹ';

  @override
  String get appSubtitle => 'سبزیوں کی درآمد / برآمد اور ہول سیل مینجمنٹ';

  @override
  String get navHome => 'ہوم';

  @override
  String get navBatches => 'بیچز';

  @override
  String get navSales => 'سیلز';

  @override
  String get navCustomers => 'گاہک';

  @override
  String get menuProfile => 'میرا پروفائل';

  @override
  String get menuBusinessInfo => 'کاروباری معلومات';

  @override
  String get menuSwitchBusiness => 'کاروبار تبدیل / شامل کریں';

  @override
  String get menuAccessManagement => 'رسائی کا انتظام';

  @override
  String get menuNotifications => 'اطلاعات';

  @override
  String get menuHelpCenter => 'مدد';

  @override
  String get menuAbout => 'متعلق';

  @override
  String get menuLogout => 'لاگ آؤٹ';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonCancel => 'منسوخ';

  @override
  String get commonRetry => 'دوبارہ کوشش';

  @override
  String get commonRequired => 'ضروری';

  @override
  String get signIn => 'سائن ان';

  @override
  String get signUp => 'سائن اپ';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get welcomeBack => 'واپسی پر خوش آمدید';

  @override
  String get authRequired => 'جاری رکھنے کے لیے سائن ان کریں';

  @override
  String get dashboardGreetingFallback => 'آپ کو دیکھ کر خوشی ہوئی';

  @override
  String dashboardGreeting(Object name) {
    return 'آپ کو دیکھ کر خوشی ہوئی، $name';
  }

  @override
  String get dashboardRevenueTitle => 'آج کی آمدنی';

  @override
  String get dashboardRevenueSubtitle => 'آج تمام بیچز پر ریکارڈ کی گئی مجموعی فروخت';

  @override
  String get dashboardCredit => 'بقایا کریڈٹ';

  @override
  String get dashboardCustomers => 'گاہک';

  @override
  String get dashboardBatches => 'کل بیچز';

  @override
  String get dashboardProducts => 'مصنوعات';

  @override
  String get dashboardQuickActions => 'فوری اقدامات';

  @override
  String get dashboardQuickNewBatch => 'نیا بیچ';

  @override
  String get dashboardQuickNewSale => 'نئی فروخت';

  @override
  String get dashboardQuickRecordPayment => 'ادائیگی ریکارڈ کریں';

  @override
  String get dashboardQuickReports => 'رپورٹس';

  @override
  String get dashboardCreditAlerts => 'کریڈٹ الرٹس';

  @override
  String get dashboardRecentBatches => 'حالیہ بیچز';

  @override
  String get dashboardNoOverdue => 'کوئی اوور ڈیو گاہک نہیں۔';

  @override
  String get emptyCustomersTitle => 'ابھی تک کوئی گاہک نہیں';

  @override
  String get emptyCustomersSubtitle => 'پہلا گاہک شامل کریں اور کریڈٹ سیلز ریکارڈ کریں۔';

  @override
  String get emptyBatchesTitle => 'ابھی تک کوئی بیچ نہیں';

  @override
  String get emptyBatchesSubtitle => 'خریداری سے فروخت تک ٹریکنگ شروع کرنے کے لیے پہلا بیچ بنائیں۔';

  @override
  String get emptySalesTitle => 'ابھی فروخت کے لیے کوئی بیچ نہیں';

  @override
  String get emptySalesSubtitle => 'بیچ کو \'فروخت\' اسٹیٹس پر منتقل کریں تاکہ آمدنی ریکارڈ ہو۔';

  @override
  String get emptyPartnersTitle => 'ابھی تک کوئی پارٹنر نہیں';

  @override
  String get emptyPartnersSubtitle => 'بیلنس اور ادائیگیاں ٹریک کرنے کے لیے پارٹنرز شامل کریں۔';

  @override
  String get batchesScreenTitle => 'بیچز';

  @override
  String get batchesSearchHint => 'بیچ کوڈ یا مصنوع سے تلاش کریں';

  @override
  String get batchesCreateCta => 'نیا بیچ';

  @override
  String get batchesCreateTitle => 'بیچ لائف سائیکل';

  @override
  String get batchesCreateSubtitle => 'خریداری سے فروخت تک پیداوار کو فالو کریں، ٹرانسپورٹ، پیکنگ اور P&L ایک ٹائم لائن میں۔';

  @override
  String batchesStepLabel(Object current, Object total) {
    return 'مرحلہ $current از $total';
  }

  @override
  String get batchesStep1Title => 'مصنوع اور خریداری';

  @override
  String get batchesStep2Title => 'خریداری کے پارٹنرز';

  @override
  String get batchesStep3Title => 'پیکنگ';

  @override
  String get batchesStep4Title => 'خریدار کے اخراجات';

  @override
  String get batchesStep5Title => 'جائزہ اور تصدیق';

  @override
  String get batchesSummary => 'خلاصہ';

  @override
  String get batchesSave => 'تصدیق اور بنائیں';

  @override
  String get batchesNext => 'اگلا';

  @override
  String get batchesBack => 'پچھلا';

  @override
  String get batchesAdvanceStatus => 'اسٹیٹس آگے بڑھائیں';

  @override
  String get batchesClosedPill => 'بند — صرف پڑھنے کے لیے۔ ترمیم، پیکنگ، اخراجات اور فروخت بند ہیں۔';

  @override
  String get batchesMarkAsClosed => 'بند کے طور پر مارک کریں';

  @override
  String get batchesSoldRemaining => 'بیچا گیا بمقابلہ بقایا';

  @override
  String get batchesSold => 'بیچا گیا';

  @override
  String get batchesRemaining => 'بقایا';

  @override
  String batchesTotalSuffix(Object unit, Object value) {
    return 'کل $value $unit';
  }

  @override
  String get batchStatusPurchased => 'خریدا ہوا';

  @override
  String get batchStatusPacked => 'پیک شدہ';

  @override
  String get batchStatusInTransit => 'ٹرانزٹ میں';

  @override
  String get batchStatusDelivered => 'ڈیلیور ہوا';

  @override
  String get batchStatusSelling => 'فروخت کے لیے';

  @override
  String get batchStatusClosed => 'بند';

  @override
  String get salesScreenTitle => 'سیلز';

  @override
  String get salesRecordCta => 'فروخت ریکارڈ کریں';

  @override
  String get salesRecordNewTitle => 'آمدنی کا ریکارڈ';

  @override
  String get salesRecordNewSubtitle => 'فروخت فعال بیچز سے منسلک ہوتی ہے تاکہ آمدنی اور کریڈٹ P&L کے ساتھ ہم آہنگ رہیں۔';

  @override
  String get saleEntryTitle => 'فروخت ریکارڈ کریں';

  @override
  String saleEntryQuantityLabel(Object unit) {
    return 'مقدار ($unit)';
  }

  @override
  String saleEntryRemainingHelper(Object remaining, Object total, Object unit) {
    return 'صرف $remaining $unit باقی (کل $total میں سے)';
  }

  @override
  String get saleEntryQuantityError => 'بقایا مقدار سے زیادہ';

  @override
  String get saleEntryPriceLabel => 'فی یونٹ قیمت';

  @override
  String get saleEntryPaymentLabel => 'ادائیگی کا طریقہ';

  @override
  String get saleEntryCustomerLabel => 'گاہک';

  @override
  String get saleEntrySave => 'فروخت محفوظ کریں';

  @override
  String get saleRecordedSnack => 'فروخت ریکارڈ ہوئی';

  @override
  String get paymentCash => 'نقد';

  @override
  String get paymentCredit => 'کریڈٹ';

  @override
  String get paymentPartialCredit => 'جزوی کریڈٹ';

  @override
  String get paymentBankTransfer => 'بینک ٹرانسفر';

  @override
  String get customersScreenTitle => 'گاہک';

  @override
  String get customersSearchHint => 'نام، فون، یا دکان سے تلاش کریں';

  @override
  String get customersCreateCta => 'نیا گاہک';

  @override
  String get customersAddTitle => 'بقایا رقم';

  @override
  String get customersNoBalance => 'کوئی بقایا نہیں';

  @override
  String get customersRecordPayment => 'ادائیگی ریکارڈ کریں';

  @override
  String get customerFullName => 'پورا نام';

  @override
  String get customerPhone => 'فون';

  @override
  String get customerCity => 'شہر';

  @override
  String get customerShop => 'دکان / اسٹال';

  @override
  String get customerOptionalPhone => 'اختیاری';

  @override
  String get recordPaymentAmount => 'رقم';

  @override
  String get recordPaymentMode => 'ادائیگی کا طریقہ';

  @override
  String get recordPaymentBankRef => 'بینک حوالہ';

  @override
  String get recordPaymentNotes => 'نوٹس';

  @override
  String get recordPaymentSave => 'ادائیگی محفوظ کریں';

  @override
  String get recordPaymentRecorded => 'ادائیگی کامیابی سے ریکارڈ ہوئی';

  @override
  String recordPaymentExceeds(Object balance) {
    return 'رقم بقایا $balance سے زیادہ ہے';
  }

  @override
  String get archive => 'آرکائیو';

  @override
  String get archived => 'آرکائیو شدہ';

  @override
  String archiveUndone(Object name) {
    return '$name آرکائیو ہوئی';
  }

  @override
  String get archiveUndo => 'کالعدم کریں';

  @override
  String get restored => 'بحال ہوئی';

  @override
  String get archiveRestoreFailed => 'بحال ناکام';

  @override
  String archivePromptTitle(Object name) {
    return '$name کو آرکائیو کریں؟';
  }

  @override
  String get archivePromptMessage => 'آرکائیو شدہ گاہک فہرست سے چھپائے جاتے ہیں اور رپورٹس سے باہر رکھے جاتے ہیں۔ بعد میں بحال کیا جا سکتا ہے۔';

  @override
  String get archiveFailed => 'آرکائیو ناکام';

  @override
  String get settingsScreenTitle => 'ترتیبات';

  @override
  String get settingsAccount => 'اکاؤنٹ';

  @override
  String get settingsSupport => 'مدد';

  @override
  String get editProfile => 'پروفائل میں ترمیم';

  @override
  String get settingsThemeMode => 'تھیم';

  @override
  String get settingsThemeLight => 'روشن';

  @override
  String get settingsThemeDark => 'گہرا';

  @override
  String get settingsThemeSystem => 'سسٹم';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get settingsLanguageEnglish => 'انگریزی';

  @override
  String get settingsLanguageUrdu => 'اردو';

  @override
  String get settingsCurrency => 'کرنسی';

  @override
  String get notificationsTitle => 'اطلاعات';

  @override
  String get notificationsAlertsSection => 'الرٹس';

  @override
  String get notificationsCreditAlerts => 'کریڈٹ الرٹس';

  @override
  String get notificationsCreditAlertsDesc => 'جب کوئی گاہک کریڈٹ حد سے تجاوز کرے تو مطلع کریں۔';

  @override
  String get notificationsBatchUpdates => 'بیچ اپ ڈیٹس';

  @override
  String get notificationsBatchUpdatesDesc => 'بیچ اسٹیٹس تبدیلیاں اور نئی بیچ سرگرمی۔';

  @override
  String get notificationsExpenseApprovals => 'اخراجات کی منظوری';

  @override
  String get notificationsExpenseApprovalsDesc => 'جب کسی پارٹنر یا اخراجات کو توجہ کی ضرورت ہو۔';

  @override
  String get notificationsDailySummary => 'روزانہ خلاصہ';

  @override
  String get notificationsDailySummaryDesc => 'فروخت، کریڈٹ اور P&L کا روزانہ خلاصہ۔';

  @override
  String get notificationsSave => 'ترجیحات محفوظ کریں';

  @override
  String get notificationsSaved => 'اطلاع کی ترجیحات محفوظ ہوئیں';

  @override
  String get helpCenterTitle => 'مدد';

  @override
  String get helpCenterStillNeed => 'ابھی بھی مدد چاہیے؟';

  @override
  String get helpCenterContact => 'ہم سے رابطہ کریں اور ہم 24 گھنٹے کے اندر جواب دیں گے۔';

  @override
  String get aboutTitle => 'متعلق';

  @override
  String get aboutPublisher => 'ناشر';

  @override
  String get aboutVersion => 'ورژن';

  @override
  String get aboutPurpose => 'مقصد';

  @override
  String get aboutPrivacy => 'رازداری';

  @override
  String aboutCopyright(Object year) {
    return '© $year گرین مارکیٹ۔ جملہ حقوق محفوظ ہیں۔';
  }

  @override
  String get aboutTracking => 'سبزیوں کے ہول سیل تاجروں کے لیے بیچز، سیلز، اخراجات اور پارٹنر P&L ٹریک کریں۔';

  @override
  String get aboutDataStorage => 'آپ کا ڈیٹا محفوظ طریقے سے کلاؤڈ میں محفوظ ہے اور اس ڈیوائس کے ساتھ sync ہوتا ہے۔';

  @override
  String get aboutOffline => 'آف لائن موڈ جلد آ رہا ہے۔ فی الحال فعال کنکشن ضروری ہے۔';

  @override
  String get roleOwner => 'مالک';

  @override
  String get roleEditor => 'ایڈیٹر';

  @override
  String get roleViewer => 'ناظر';

  @override
  String get roleAccountant => 'اکاؤنٹنٹ';

  @override
  String get roleMember => 'رکن';

  @override
  String get offlineBanner => 'آپ آف لائن ہیں۔ جہاں ممکن ہو cached ڈیٹا دکھایا جا رہا ہے۔';
}
