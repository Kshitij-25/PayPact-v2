part of 'settings_bloc.dart';

abstract class SettingsEvent {}

class SettingsLoaded extends SettingsEvent {}

class SettingsThemeModeChanged extends SettingsEvent {
  SettingsThemeModeChanged(this.themeMode);
  final ThemeMode themeMode;
}

class SettingsCurrencyChanged extends SettingsEvent {
  SettingsCurrencyChanged(this.currency);
  final String currency;
}

class SettingsLanguageChanged extends SettingsEvent {
  SettingsLanguageChanged(this.languageCode);
  final String languageCode;
}

class SettingsNotifyExpenseAddedChanged extends SettingsEvent {
  SettingsNotifyExpenseAddedChanged(this.value);
  final bool value;
}

class SettingsNotifySettlementChanged extends SettingsEvent {
  SettingsNotifySettlementChanged(this.value);
  final bool value;
}

class SettingsNotifyGroupInviteChanged extends SettingsEvent {
  SettingsNotifyGroupInviteChanged(this.value);
  final bool value;
}

class SettingsNotifyWeeklyDigestChanged extends SettingsEvent {
  SettingsNotifyWeeklyDigestChanged(this.value);
  final bool value;
}
