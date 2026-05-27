import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'group_settings_state.dart';

class GroupSettingsCubit extends Cubit<GroupSettingsState> {
  final GroupRepository _repo;
  final String _groupId;

  GroupSettingsCubit(this._repo, this._groupId) : super(GroupSettingsInitial());

  Future<void> load() async {
    emit(GroupSettingsLoading());
    try {
      final group = await _repo.getGroup(_groupId);
      if (group == null) {
        emit(GroupSettingsError('Group not found'));
        return;
      }
      emit(GroupSettingsLoaded(group: group));
    } catch (e) {
      emit(GroupSettingsError(e.toString()));
    }
  }

  Future<void> save(
      {required String name,
      required String emoji,
      required String category}) async {
    final current = state;
    if (current is! GroupSettingsLoaded) return;
    emit(GroupSettingsSaving(group: current.group));
    try {
      await _repo.updateGroup(_groupId,
          name: name, emoji: emoji, category: category);
      final updated = await _repo.getGroup(_groupId);
      emit(GroupSettingsSaved(group: updated ?? current.group));
    } catch (e) {
      emit(GroupSettingsError(e.toString()));
    }
  }

  Future<void> removeMember(String userId) async {
    final current = state;
    if (current is! GroupSettingsLoaded) return;
    try {
      await _repo.removeMember(_groupId, userId);
      final updated = await _repo.getGroup(_groupId);
      if (updated != null) emit(GroupSettingsLoaded(group: updated));
    } catch (e) {
      emit(GroupSettingsError(e.toString()));
    }
  }

  Future<void> deleteGroup() async {
    final current = state;
    if (current is! GroupSettingsLoaded) return;
    emit(GroupSettingsSaving(group: current.group));
    try {
      await _repo.deleteGroup(_groupId);
      emit(GroupSettingsDeleted());
    } catch (e) {
      emit(GroupSettingsError(e.toString()));
    }
  }
}
