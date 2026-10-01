import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — changes will sync when you\'re back.'**
  String get offlineBanner;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'PayPact is locked'**
  String get lockTitle;

  /// No description provided for @lockBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock to see your groups and balances.'**
  String get lockBody;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @signInEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WELCOME BACK'**
  String get signInEyebrow;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello, friend.\nLet\'s get you in.'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email — we\'ll keep things calm.'**
  String get signInSubtitle;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get labelEmail;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get labelPassword;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get forgot;

  /// No description provided for @keepSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in on this device'**
  String get keepSignedIn;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in to PayPact'**
  String get signInButton;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @newToPaypact.
  ///
  /// In en, this message translates to:
  /// **'New to PayPact?'**
  String get newToPaypact;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @agreePrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing in you agree to our '**
  String get agreePrefix;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @searchHintAll.
  ///
  /// In en, this message translates to:
  /// **'Search groups, expenses, people'**
  String get searchHintAll;

  /// No description provided for @searchHintGroups.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get searchHintGroups;

  /// No description provided for @searchHintExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get searchHintExpenses;

  /// No description provided for @searchYourGroups.
  ///
  /// In en, this message translates to:
  /// **'YOUR GROUPS'**
  String get searchYourGroups;

  /// No description provided for @searchGroups.
  ///
  /// In en, this message translates to:
  /// **'GROUPS'**
  String get searchGroups;

  /// No description provided for @searchPeople.
  ///
  /// In en, this message translates to:
  /// **'PEOPLE'**
  String get searchPeople;

  /// No description provided for @searchExpenses.
  ///
  /// In en, this message translates to:
  /// **'EXPENSES'**
  String get searchExpenses;

  /// No description provided for @searchExpensesLoading.
  ///
  /// In en, this message translates to:
  /// **'EXPENSES · SEARCHING…'**
  String get searchExpensesLoading;

  /// No description provided for @searchTypeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search.'**
  String get searchTypeToSearch;

  /// No description provided for @searchNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\".'**
  String searchNothing(String query);

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageRow.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageRow;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'CURRENCY'**
  String get settingsCurrency;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get settingsNotifications;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY & DATA'**
  String get settingsPrivacy;

  /// No description provided for @notifSettlements.
  ///
  /// In en, this message translates to:
  /// **'Settlement requests'**
  String get notifSettlements;

  /// No description provided for @notifSettlementsSub.
  ///
  /// In en, this message translates to:
  /// **'Someone settles up with you'**
  String get notifSettlementsSub;

  /// No description provided for @notifNudges.
  ///
  /// In en, this message translates to:
  /// **'Smart nudges'**
  String get notifNudges;

  /// No description provided for @notifNudgesSub.
  ///
  /// In en, this message translates to:
  /// **'Gentle reminders about open balances'**
  String get notifNudgesSub;

  /// No description provided for @notifExpenses.
  ///
  /// In en, this message translates to:
  /// **'New expenses'**
  String get notifExpenses;

  /// No description provided for @notifExpensesSub.
  ///
  /// In en, this message translates to:
  /// **'When others add to your groups'**
  String get notifExpensesSub;

  /// No description provided for @notifDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get notifDigest;

  /// No description provided for @notifDigestSub.
  ///
  /// In en, this message translates to:
  /// **'Sundays · 8 PM'**
  String get notifDigestSub;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockSub.
  ///
  /// In en, this message translates to:
  /// **'Ask for Face ID / fingerprint / passcode on return'**
  String get appLockSub;

  /// No description provided for @appLockNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'App Lock wasn\'t turned on.'**
  String get appLockNotEnabled;

  /// No description provided for @crashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get crashReports;

  /// No description provided for @crashReportsSub.
  ///
  /// In en, this message translates to:
  /// **'Send anonymous crash details so we can fix problems'**
  String get crashReportsSub;

  /// No description provided for @usageData.
  ///
  /// In en, this message translates to:
  /// **'Anonymous usage data'**
  String get usageData;

  /// No description provided for @usageDataSub.
  ///
  /// In en, this message translates to:
  /// **'Help improve PayPact. Never includes your groups or amounts'**
  String get usageDataSub;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export all data'**
  String get exportData;

  /// No description provided for @exportDataSub.
  ///
  /// In en, this message translates to:
  /// **'A copy of your profile, groups, expenses and payments'**
  String get exportDataSub;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and data'**
  String get deleteAccountSub;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @signInShort.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
