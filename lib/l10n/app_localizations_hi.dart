// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get navHome => 'होम';

  @override
  String get navGroups => 'ग्रुप';

  @override
  String get navActivity => 'गतिविधि';

  @override
  String get navYou => 'आप';

  @override
  String get navInsights => 'इनसाइट्स';

  @override
  String get navNotifications => 'सूचनाएँ';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get offlineBanner =>
      'आप ऑफ़लाइन हैं — ऑनलाइन होते ही बदलाव सिंक हो जाएँगे।';

  @override
  String get lockTitle => 'PayPact लॉक है';

  @override
  String get lockBody => 'अपने ग्रुप और बैलेंस देखने के लिए अनलॉक करें।';

  @override
  String get unlock => 'अनलॉक करें';

  @override
  String get signInEyebrow => 'फिर से स्वागत है';

  @override
  String get signInTitle => 'नमस्ते दोस्त।\nचलिए आपको अंदर ले चलें।';

  @override
  String get signInSubtitle =>
      'अपने ईमेल से साइन इन करें — हम सब कुछ शांत रखेंगे।';

  @override
  String get labelEmail => 'ईमेल';

  @override
  String get labelPassword => 'पासवर्ड';

  @override
  String get forgot => 'भूल गए?';

  @override
  String get keepSignedIn => 'इस डिवाइस पर साइन इन रखें';

  @override
  String get signInButton => 'PayPact में साइन इन करें';

  @override
  String get signingIn => 'साइन इन हो रहा है…';

  @override
  String get orDivider => 'या';

  @override
  String get continueWithGoogle => 'Google से जारी रखें';

  @override
  String get newToPaypact => 'PayPact में नए हैं?';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get agreePrefix => 'साइन इन करके आप हमारी ';

  @override
  String get terms => 'शर्तें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get and => ' और ';

  @override
  String get searchHintAll => 'ग्रुप, खर्चे, लोग खोजें';

  @override
  String get searchHintGroups => 'ग्रुप खोजें';

  @override
  String get searchHintExpenses => 'खर्चे खोजें';

  @override
  String get searchYourGroups => 'आपके ग्रुप';

  @override
  String get searchGroups => 'ग्रुप';

  @override
  String get searchPeople => 'लोग';

  @override
  String get searchExpenses => 'खर्चे';

  @override
  String get searchExpensesLoading => 'खर्चे · खोज जारी…';

  @override
  String get searchTypeToSearch => 'खोजने के लिए टाइप करें।';

  @override
  String searchNothing(String query) {
    return '\"$query\" से कुछ नहीं मिला।';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य',
      one: '1 सदस्य',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsAppearance => 'रूप-रंग';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsLanguageRow => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get settingsCurrency => 'मुद्रा';

  @override
  String get settingsNotifications => 'सूचनाएँ';

  @override
  String get settingsPrivacy => 'गोपनीयता और डेटा';

  @override
  String get notifSettlements => 'भुगतान अनुरोध';

  @override
  String get notifSettlementsSub => 'कोई आपके साथ हिसाब चुकता करे';

  @override
  String get notifNudges => 'स्मार्ट रिमाइंडर';

  @override
  String get notifNudgesSub => 'बकाया बैलेंस के बारे में हल्के रिमाइंडर';

  @override
  String get notifExpenses => 'नए खर्चे';

  @override
  String get notifExpensesSub => 'जब दूसरे आपके ग्रुप में खर्चा जोड़ें';

  @override
  String get notifDigest => 'साप्ताहिक सारांश';

  @override
  String get notifDigestSub => 'रविवार · रात 8 बजे';

  @override
  String get appLock => 'ऐप लॉक';

  @override
  String get appLockSub => 'वापस आने पर Face ID / फ़िंगरप्रिंट / पासकोड माँगें';

  @override
  String get appLockNotEnabled => 'ऐप लॉक चालू नहीं हुआ।';

  @override
  String get crashReports => 'क्रैश रिपोर्ट';

  @override
  String get crashReportsSub =>
      'समस्याएँ ठीक करने के लिए अनाम क्रैश जानकारी भेजें';

  @override
  String get usageData => 'अनाम उपयोग डेटा';

  @override
  String get usageDataSub =>
      'PayPact को बेहतर बनाने में मदद करें। इसमें आपके ग्रुप या रकम कभी शामिल नहीं होते';

  @override
  String get exportData => 'सारा डेटा एक्सपोर्ट करें';

  @override
  String get exportDataSub =>
      'आपकी प्रोफ़ाइल, ग्रुप, खर्चों और भुगतानों की एक कॉपी';

  @override
  String get deleteAccount => 'खाता हटाएँ';

  @override
  String get deleteAccountSub => 'अपना खाता और डेटा हमेशा के लिए हटाएँ';

  @override
  String get createAnAccount => 'खाता बनाएँ';

  @override
  String get signInShort => 'साइन इन';
}
