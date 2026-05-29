import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

part 'add_members_state.dart';

class AddMembersCubit extends Cubit<AddMembersState> {
  final GroupRepository _groupRepo;
  final FirebaseFirestore _firestore;
  final NotificationsRepository _notifRepo;
  Timer? _debounce;

  AddMembersCubit(this._groupRepo, this._firestore, this._notifRepo)
      : super(AddMembersIdle([]));

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  void search(String query, {required Set<String> existingMemberIds}) {
    _debounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      emit(AddMembersIdle([]));
      return;
    }
    emit(AddMembersSearching(q));
    _debounce = Timer(const Duration(milliseconds: 350),
        () => _runSearch(q, existingMemberIds));
  }

  Future<void> _runSearch(String q, Set<String> existingMemberIds) async {
    try {
      final results = <UserResult>[];

      // email exact match
      final emailSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: q.toLowerCase())
          .limit(5)
          .get();
      for (final d in emailSnap.docs) {
        if (!existingMemberIds.contains(d.id)) {
          results.add(UserResult.fromDoc(d));
        }
      }

      // name prefix search if no email hits
      if (results.isEmpty) {
        final end = '$q';
        final nameSnap = await _firestore
            .collection('users')
            .orderBy('name')
            .startAt([q])
            .endAt([end])
            .limit(10)
            .get();
        for (final d in nameSnap.docs) {
          if (!existingMemberIds.contains(d.id) &&
              !results.any((r) => r.id == d.id)) {
            results.add(UserResult.fromDoc(d));
          }
        }
      }

      emit(AddMembersSearchDone(q, results));
    } catch (e) {
      emit(AddMembersError(e.toString()));
    }
  }

  Future<void> addMembers(
    String groupId,
    List<UserResult> members, {
    required String actorId,
    required String actorName,
    String? groupName,
    List<String> existingMemberIds = const [],
  }) async {
    emit(AddMembersAdding());
    try {
      await Future.wait(
          members.map((m) => _groupRepo.addMember(groupId, m.id, m.name)));

      final addedIds = members.map((m) => m.id).toSet();

      // Notify each added member
      await Future.wait(members.map((m) => _notifRepo.push(
            targetUserId: m.id,
            type: 'member_added',
            title: '$actorName added you to a group',
            body: groupName != null
                ? 'You\'ve been added to "$groupName"'
                : 'You\'ve been added to a group',
            groupId: groupId,
            groupName: groupName,
            actorId: actorId,
            actorName: actorName,
          )));

      // Notify existing members (not the actor, not the newly added ones)
      final addedNames = members.map((m) => m.name).join(', ');
      final existing = existingMemberIds
          .where((id) => id != actorId && !addedIds.contains(id))
          .toList();
      if (existing.isNotEmpty) {
        await Future.wait(existing.map((id) => _notifRepo.push(
              targetUserId: id,
              type: 'member_added',
              title: '$addedNames joined "${groupName ?? 'the group'}"',
              body: '$actorName added $addedNames to the group.',
              groupId: groupId,
              groupName: groupName,
              actorId: actorId,
              actorName: actorName,
            )));
      }

      emit(AddMembersDone());
    } catch (e) {
      emit(AddMembersError(e.toString()));
    }
  }
}
