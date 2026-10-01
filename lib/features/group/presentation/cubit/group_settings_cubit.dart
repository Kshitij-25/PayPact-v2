import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/features/settle/domain/debt_simplifier.dart';

part 'group_settings_state.dart';

class GroupSettingsCubit extends Cubit<GroupSettingsState> {
  final GroupRepository _repo;
  final NotificationsRepository _notifRepo;
  final ExpenseRepository _expenseRepo;
  final String _groupId;

  GroupSettingsCubit(
      this._repo, this._notifRepo, this._expenseRepo, this._groupId)
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
    final group = _groupOf(current);
    if (group == null) return;
    emit(GroupSettingsSaving(group: group));
    try {
      await _repo.updateGroup(_groupId,
          name: name, emoji: emoji, category: category);
      final updated = await _repo.getGroup(_groupId);
      final saved = updated ?? group;
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
      emit(GroupSettingsError(e.toString(), group: group));
    }
  }

  /// A member's net balance in paise (positive = owed money, negative = owes).
  Future<int> _netPaise(GroupEntity group, String userId) async {
    final expenses = await _expenseRepo.getGroupExpenses(_groupId);
    final settlements = await _expenseRepo.getGroupSettlements(_groupId);
    final net = computeNetBalances(
      expenses: expenses,
      settlements: settlements,
      memberIds: group.memberIds,
    );
    return net[userId] ?? 0;
  }

  String _money(GroupEntity group, int paise) {
    final v = fromPaise(paise.abs());
    final text = v == v.truncateToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(2);
    return '${currencySymbol(group.currency)}$text';
  }

  GroupEntity? _groupOf(GroupSettingsState s) => switch (s) {
        GroupSettingsLoaded(:final group) => group,
        GroupSettingsSaving(:final group) => group,
        GroupSettingsSaved(:final group) => group,
        GroupSettingsNotice(:final group) => group,
        GroupSettingsError(:final group) => group,
        _ => null,
      };

  /// Removes [userId] from the group (an admin action; use [leave] for
  /// yourself). Refuses while the member has an unsettled balance, because
  /// their share would otherwise be stranded and the group's books wouldn't
  /// add up to zero any more.
  Future<void> removeMember(
    String userId, {
    required String actorId,
    required String actorName,
  }) async {
    final group = _groupOf(state);
    if (group == null) return;
    final name = group.memberNames[userId] ?? 'This member';

    if (!group.isAdmin(actorId)) {
      emit(GroupSettingsNotice(
          group: group, message: 'Only admins can remove members.'));
      return;
    }
    if (group.isAdmin(userId)) {
      emit(GroupSettingsNotice(
          group: group,
          message: '$name is an admin. Remove their admin role first.'));
      return;
    }

    try {
      final net = await _netPaise(group, userId);
      if (net != 0) {
        emit(GroupSettingsNotice(
          group: group,
          message: net > 0
              ? '$name is still owed ${_money(group, net)}. Settle up before removing them.'
              : '$name still owes ${_money(group, net)}. Settle up before removing them.',
        ));
        return;
      }

      await _repo.removeMember(_groupId, userId);
      final updated = await _repo.getGroup(_groupId);
      if (updated != null) emit(GroupSettingsLoaded(group: updated));

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
      final remaining =
          group.memberIds.where((id) => id != actorId && id != userId).toList();
      await Future.wait(remaining.map((id) => _notifRepo.push(
            targetUserId: id,
            type: 'member_removed',
            title: '$name left "${group.name}"',
            body: '$actorName removed $name from the group.',
            groupId: _groupId,
            groupName: group.name,
            actorId: actorId,
            actorName: actorName,
          )));
    } catch (e) {
      emit(GroupSettingsError(e.toString(), group: group));
    }
  }

  /// The current user leaves. Blocked while they have an unsettled balance or
  /// are the only admin of a group that still has other people in it; the
  /// last person out deletes the group.
  Future<void> leave({
    required String userId,
    required String userName,
  }) async {
    final group = _groupOf(state);
    if (group == null) return;

    try {
      final isLastMember = group.memberIds.length == 1;
      if (isLastMember) {
        await _repo.deleteGroup(_groupId);
        emit(GroupSettingsDeleted());
        return;
      }

      final net = await _netPaise(group, userId);
      if (net != 0) {
        emit(GroupSettingsNotice(
          group: group,
          message: net > 0
              ? "You're still owed ${_money(group, net)}. Settle up before leaving."
              : 'You still owe ${_money(group, net)}. Settle up before leaving.',
        ));
        return;
      }

      final otherAdmins = group.adminIds.where((id) => id != userId);
      if (group.isAdmin(userId) && otherAdmins.isEmpty) {
        emit(GroupSettingsNotice(
          group: group,
          message:
              "You're the only admin. Make another member an admin before leaving.",
        ));
        return;
      }

      await _repo.removeMember(_groupId, userId);
      emit(GroupSettingsLeft());

      // The group is no longer readable to us, so notify from what we already hold.
      final remaining = group.memberIds.where((id) => id != userId).toList();
      await Future.wait(remaining.map((id) => _notifRepo.push(
            targetUserId: id,
            type: 'member_removed',
            title: '$userName left "${group.name}"',
            body: '$userName left the group.',
            groupId: _groupId,
            groupName: group.name,
            actorId: userId,
            actorName: userName,
          )));
    } catch (e) {
      emit(GroupSettingsError(e.toString(), group: group));
    }
  }

  Future<void> setAdmin(
    String userId, {
    required bool isAdmin,
    required String actorId,
    required String actorName,
  }) async {
    final group = _groupOf(state);
    if (group == null) return;
    if (!group.isAdmin(actorId)) {
      emit(GroupSettingsNotice(
          group: group, message: 'Only admins can change roles.'));
      return;
    }
    if (!isAdmin && group.adminIds.where((id) => id != userId).isEmpty) {
      emit(GroupSettingsNotice(
          group: group, message: 'A group needs at least one admin.'));
      return;
    }
    try {
      await _repo.setAdmin(_groupId, userId, isAdmin: isAdmin);
      final updated = await _repo.getGroup(_groupId);
      if (updated != null) emit(GroupSettingsLoaded(group: updated));
      if (userId != actorId) {
        await _notifRepo.push(
          targetUserId: userId,
          type: 'group_updated',
          title: isAdmin
              ? 'You are now an admin of "${group.name}"'
              : 'Your admin role in "${group.name}" was removed',
          body: '$actorName changed your role.',
          groupId: _groupId,
          groupName: group.name,
          actorId: actorId,
          actorName: actorName,
        );
      }
    } catch (e) {
      emit(GroupSettingsError(e.toString(), group: group));
    }
  }

  Future<void> deleteGroup({
    required String actorId,
    required String actorName,
  }) async {
    final group = _groupOf(state);
    if (group == null) return;
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
      emit(GroupSettingsError(e.toString(), group: group));
    }
  }
}
