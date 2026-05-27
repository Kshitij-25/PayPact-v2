part of 'group_settings_cubit.dart';

abstract class GroupSettingsState {}

class GroupSettingsInitial extends GroupSettingsState {}

class GroupSettingsLoading extends GroupSettingsState {}

class GroupSettingsLoaded extends GroupSettingsState {
  final GroupEntity group;
  GroupSettingsLoaded({required this.group});
}

class GroupSettingsSaving extends GroupSettingsState {
  final GroupEntity group;
  GroupSettingsSaving({required this.group});
}

class GroupSettingsSaved extends GroupSettingsState {
  final GroupEntity group;
  GroupSettingsSaved({required this.group});
}

class GroupSettingsDeleted extends GroupSettingsState {}

class GroupSettingsError extends GroupSettingsState {
  final String message;
  GroupSettingsError(this.message);
}
