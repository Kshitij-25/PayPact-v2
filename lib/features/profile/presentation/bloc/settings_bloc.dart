import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SettingsLoaded>(_onLoaded);
    on<SettingsThemeModeChanged>(_onThemeMode);
    on<SettingsCurrencyChanged>(_onCurrency);
    on<SettingsLanguageChanged>(_onLanguage);
    on<SettingsNotifyExpenseAddedChanged>(_onNotifyExpense);
    on<SettingsNotifySettlementChanged>(_onNotifySettlement);
    on<SettingsNotifyGroupInviteChanged>(_onNotifyGroupInvite);
    on<SettingsNotifyWeeklyDigestChanged>(_onNotifyWeekly);
  }

  static const _kTheme = 'pref_theme';
  static const _kCurrency = 'pref_currency';
  static const _kLanguage = 'pref_language';
  static const _kNotifyExpense = 'pref_notify_expense';
  static const _kNotifySettlement = 'pref_notify_settlement';
  static const _kNotifyInvite = 'pref_notify_invite';
  static const _kNotifyDigest = 'pref_notify_digest';

  Future<void> _onLoaded(
      SettingsLoaded event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_kTheme) ?? ThemeMode.system.index;
    emit(state.copyWith(
      themeMode:
          ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      currency: prefs.getString(_kCurrency) ?? 'USD',
      languageCode: prefs.getString(_kLanguage) ?? 'en',
      notifyExpenseAdded: prefs.getBool(_kNotifyExpense) ?? true,
      notifySettlement: prefs.getBool(_kNotifySettlement) ?? true,
      notifyGroupInvite: prefs.getBool(_kNotifyInvite) ?? true,
      notifyWeeklyDigest: prefs.getBool(_kNotifyDigest) ?? false,
      isLoaded: true,
    ));
  }

  Future<void> _onThemeMode(
      SettingsThemeModeChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(themeMode: event.themeMode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTheme, event.themeMode.index);
  }

  Future<void> _onCurrency(
      SettingsCurrencyChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(currency: event.currency));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, event.currency);
  }

  Future<void> _onLanguage(
      SettingsLanguageChanged event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(languageCode: event.languageCode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, event.languageCode);
  }

  Future<void> _onNotifyExpense(SettingsNotifyExpenseAddedChanged event,
      Emitter<SettingsState> emit) async {
    emit(state.copyWith(notifyExpenseAdded: event.value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyExpense, event.value);
  }

  Future<void> _onNotifySettlement(SettingsNotifySettlementChanged event,
      Emitter<SettingsState> emit) async {
    emit(state.copyWith(notifySettlement: event.value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifySettlement, event.value);
  }

  Future<void> _onNotifyGroupInvite(SettingsNotifyGroupInviteChanged event,
      Emitter<SettingsState> emit) async {
    emit(state.copyWith(notifyGroupInvite: event.value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyInvite, event.value);
  }

  Future<void> _onNotifyWeekly(SettingsNotifyWeeklyDigestChanged event,
      Emitter<SettingsState> emit) async {
    emit(state.copyWith(notifyWeeklyDigest: event.value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyDigest, event.value);
  }
}
