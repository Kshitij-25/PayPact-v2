import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _fbAuth;
  final GroupRepository _groupRepo;

  ProfileCubit(this._firestore, this._fbAuth, this._groupRepo)
      : super(ProfileInitial());

  Future<void> load(String userId) async {
    emit(ProfileLoading());
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data() ?? {};
      final user = UserEntity(
        id: userId,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        photoUrl: data['photoUrl'] as String?,
      );
      final groups = await _groupRepo.watchUserGroups(userId).first;
      emit(ProfileLoaded(user: user, groupCount: groups.length));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateName(String name) async {
    final current = state;
    if (current is! ProfileLoaded) return;
    final groupCount = current.groupCount;
    emit(ProfileSaving(current.user));
    try {
      final uid = current.user.id;
      await Future.wait([
        _fbAuth.currentUser!.updateDisplayName(name),
        _firestore.collection('users').doc(uid).update({'name': name}),
      ]);
      final updated = UserEntity(
        id: uid,
        name: name,
        email: current.user.email,
        photoUrl: current.user.photoUrl,
      );
      emit(ProfileLoaded(user: updated, groupCount: groupCount));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
