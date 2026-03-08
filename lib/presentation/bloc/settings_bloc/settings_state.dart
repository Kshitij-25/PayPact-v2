part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.currency = 'USD',
    this.languageCode = 'en',
    this.notifyExpenseAdded = true,
    this.notifySettlement = true,
    this.notifyGroupInvite = true,
    this.notifyWeeklyDigest = false,
    this.isLoaded = false,
  });

  final ThemeMode themeMode;
  final String currency;
  final String languageCode;
  final bool notifyExpenseAdded;
  final bool notifySettlement;
  final bool notifyGroupInvite;
  final bool notifyWeeklyDigest;
  final bool isLoaded;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? currency,
    String? languageCode,
    bool? notifyExpenseAdded,
    bool? notifySettlement,
    bool? notifyGroupInvite,
    bool? notifyWeeklyDigest,
    bool? isLoaded,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        currency: currency ?? this.currency,
        languageCode: languageCode ?? this.languageCode,
        notifyExpenseAdded: notifyExpenseAdded ?? this.notifyExpenseAdded,
        notifySettlement: notifySettlement ?? this.notifySettlement,
        notifyGroupInvite: notifyGroupInvite ?? this.notifyGroupInvite,
        notifyWeeklyDigest: notifyWeeklyDigest ?? this.notifyWeeklyDigest,
        isLoaded: isLoaded ?? this.isLoaded,
      );

  @override
  List<Object?> get props => [
        themeMode,
        currency,
        languageCode,
        notifyExpenseAdded,
        notifySettlement,
        notifyGroupInvite,
        notifyWeeklyDigest,
        isLoaded,
      ];
}
