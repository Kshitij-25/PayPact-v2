// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navGroups => 'Groups';

  @override
  String get navActivity => 'Activity';

  @override
  String get navYou => 'You';

  @override
  String get navInsights => 'Insights';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get offlineBanner =>
      'You\'re offline — changes will sync when you\'re back.';

  @override
  String get lockTitle => 'PayPact is locked';

  @override
  String get lockBody => 'Unlock to see your groups and balances.';

  @override
  String get unlock => 'Unlock';

  @override
  String get signInEyebrow => 'WELCOME BACK';

  @override
  String get signInTitle => 'Hello, friend.\nLet\'s get you in.';

  @override
  String get signInSubtitle =>
      'Sign in with your email — we\'ll keep things calm.';

  @override
  String get labelEmail => 'EMAIL';

  @override
  String get labelPassword => 'PASSWORD';

  @override
  String get forgot => 'Forgot?';

  @override
  String get keepSignedIn => 'Keep me signed in on this device';

  @override
  String get signInButton => 'Sign in to PayPact';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get orDivider => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get newToPaypact => 'New to PayPact?';

  @override
  String get createAccount => 'Create account';

  @override
  String get agreePrefix => 'By signing in you agree to our ';

  @override
  String get terms => 'Terms';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get and => ' and ';

  @override
  String get searchHintAll => 'Search groups, expenses, people';

  @override
  String get searchHintGroups => 'Search groups';

  @override
  String get searchHintExpenses => 'Search expenses';

  @override
  String get searchYourGroups => 'YOUR GROUPS';

  @override
  String get searchGroups => 'GROUPS';

  @override
  String get searchPeople => 'PEOPLE';

  @override
  String get searchExpenses => 'EXPENSES';

  @override
  String get searchExpensesLoading => 'EXPENSES · SEARCHING…';

  @override
  String get searchTypeToSearch => 'Type to search.';

  @override
  String searchNothing(String query) {
    return 'Nothing matches \"$query\".';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'APPEARANCE';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageRow => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get settingsCurrency => 'CURRENCY';

  @override
  String get settingsNotifications => 'NOTIFICATIONS';

  @override
  String get settingsPrivacy => 'PRIVACY & DATA';

  @override
  String get notifSettlements => 'Settlement requests';

  @override
  String get notifSettlementsSub => 'Someone settles up with you';

  @override
  String get notifNudges => 'Smart nudges';

  @override
  String get notifNudgesSub => 'Gentle reminders about open balances';

  @override
  String get notifExpenses => 'New expenses';

  @override
  String get notifExpensesSub => 'When others add to your groups';

  @override
  String get notifDigest => 'Weekly digest';

  @override
  String get notifDigestSub => 'Sundays · 8 PM';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockSub => 'Ask for Face ID / fingerprint / passcode on return';

  @override
  String get appLockNotEnabled => 'App Lock wasn\'t turned on.';

  @override
  String get crashReports => 'Crash reports';

  @override
  String get crashReportsSub =>
      'Send anonymous crash details so we can fix problems';

  @override
  String get usageData => 'Anonymous usage data';

  @override
  String get usageDataSub =>
      'Help improve PayPact. Never includes your groups or amounts';

  @override
  String get exportData => 'Export all data';

  @override
  String get exportDataSub =>
      'A copy of your profile, groups, expenses and payments';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSub => 'Permanently remove your account and data';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get signInShort => 'Sign in';
}
