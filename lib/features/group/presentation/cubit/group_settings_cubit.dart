import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

part 'group_settings_state.dart';

class GroupSettingsCubit extends Cubit<GroupSettingsState> {
  final GroupRepository _repo;
  final NotificationsRepository _notifRepo;
  final String _groupId;

  GroupSettingsCubit(this._repo, this._notifRepo, this._groupId)
      : super(GroupSettingsInitial());

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

  Future<void> save({
    required String name,
    required String emoji,
    required String category,
    required String actorId,
    required String actorName,
  }) async {
    final current = state;
    if (current is! GroupSettingsLoaded) return;
    emit(GroupSettingsSaving(group: current.group));
    try {
      await _repo.updateGroup(_groupId,
          name: name, emoji: emoji, category: category);
      final updated = await _repo.getGroup(_groupId);
      final saved = updated ?? current.group;
      emit(GroupSettingsSaved(group: saved));

      final others = saved.memberIds.where((id) => id != actorId).toList();
      await Future.wait(others.map((id) => _notifRepo.push(
            targetUserId: id,
            type: 'group_updated',
            title: '$actorName updated the group',
            body: 'Group name is now "${saved.name}"',
            groupId: _groupId,
            groupName: saved.name,
            actorId: actorId,
            actorName: actorName,
          )));
    } catch (e) {
      emit(GroupSettingsError(e.toString()));
    }
  }

  Future<void> removeMember(
    String userId, {
    required String actorId,
    required String actorName,
  }) async {
    final current = state;
    if (current is! GroupSettingsLoaded) return;
    final group = current.group;
    try {
      await _repo.removeMember(_groupId, userId);
      final updated = await _repo.getGroup(_groupId);
      if (updated != null) emit(GroupSettingsLoaded(group: updated));

      // Notify the removed member
      if (userId != actorId) {
        await _notifRepo.push(
          targetUserId: userId,
          type: 'member_removed',
          title: 'You were removed from "${group.name}"',
          body: '$actorName removed you from the group.',
          groupId: _groupId,
          groupName: group.name,
          actorId: actorId,
          actorName: actorName,
        );
      }

      // Notify remaining members (excluding actor and removed user)
      final remaining =
          group.memberIds.where((id) => id != actorId && id != userId).toList();
      final removedName = group.memberNames[userId] ?? 'A member';
      await Future.wait(remaining.map((id) => _notifRepo.push(
            targetUserId: id,
            type: 'member_removed',
            title: '$removedName left "${group.name}"',
            body: '$actorName removed $removedName from the group.',
            groupId: _groupId,
            groupName: group.name,
            actorId: actorId,
            actorName: actorName,
          )));
    } catch (e) {
      emit(GroupSettingsError(e.toString()));
    }
  }

  Future<void> deleteGroup({
    required String actorId,
    required String actorName,
  }) async {
    final current = state;
    if (current is! GroupSettingsLoaded) return;
    final group = current.group;
    emit(GroupSettingsSaving(group: group));
    try {
      final others = group.memberIds.where((id) => id != actorId).toList();
      await _repo.deleteGroup(_groupId);
      emit(GroupSettingsDeleted());

      await Future.wait(others.map((id) => _notifRepo.push(
            targetUserId: id,
            type: 'group_deleted',
            title: '"${group.name}" was deleted',
            body: '$actorName deleted the group.',
            groupId: _groupId,
            groupName: group.name,
            actorId: actorId,
            actorName: actorName,
          )));
    } catch (e) {
      emit(GroupSettingsError(e.toString()));
    }
  }
}
