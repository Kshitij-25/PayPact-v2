import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'add_members_state.dart';

class AddMembersCubit extends Cubit<AddMembersState> {
  final GroupRepository _groupRepo;
  final FirebaseFirestore _firestore;

  AddMembersCubit(this._groupRepo, this._firestore)
      : super(AddMembersIdle([]));

  Future<void> search(String query,
      {required Set<String> existingMemberIds}) async {
    final q = query.trim();
    if (q.isEmpty) {
      emit(AddMembersIdle([]));
      return;
    }
    emit(AddMembersSearching(q));
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
        final end = q + '';
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

  Future<void> addMembers(String groupId, List<UserResult> members) async {
    emit(AddMembersAdding());
    try {
      await Future.wait(
          members.map((m) => _groupRepo.addMember(groupId, m.id, m.name)));
      emit(AddMembersDone());
    } catch (e) {
      emit(AddMembersError(e.toString()));
    }
  }
}
