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

/// An action was refused for a reason the user can fix (unsettled balance,
/// last admin…). Carries the group so the screen keeps rendering.
class GroupSettingsNotice extends GroupSettingsState {
  final GroupEntity group;
  final String message;
  GroupSettingsNotice({required this.group, required this.message});
}

class GroupSettingsDeleted extends GroupSettingsState {}

/// The current user left the group (they can no longer read it).
class GroupSettingsLeft extends GroupSettingsState {}

class GroupSettingsError extends GroupSettingsState {
  final String message;

  /// The last good group, so the screen doesn't blank out on a failed action.
  final GroupEntity? group;
  GroupSettingsError(this.message, {this.group});
}
