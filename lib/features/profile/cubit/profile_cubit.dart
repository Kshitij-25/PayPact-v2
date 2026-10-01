import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/storage_service.dart';
import 'package:paypact/core/utils/upi.dart';
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
        upiId: data['upiId'] as String?,
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
        upiId: current.user.upiId,
      );
      emit(ProfileLoaded(user: updated, groupCount: groupCount));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// Saves (or clears, with null/blank) the UPI address friends can pay.
  /// Returns an error message, or null on success.
  Future<String?> updateUpiId(String? raw) async {
    final current = state;
    if (current is! ProfileLoaded) return 'Profile not loaded yet.';
    final trimmed = raw?.trim() ?? '';
    final normalized = trimmed.isEmpty ? null : normalizeUpiId(trimmed);
    if (trimmed.isNotEmpty && normalized == null) {
      return 'That doesn\'t look like a UPI ID (e.g. name@okbank).';
    }
    try {
      await _firestore.collection('users').doc(current.user.id).set(
        {'upiId': normalized ?? FieldValue.delete()},
        SetOptions(merge: true),
      );
      emit(ProfileLoaded(
        user: _with(current.user, upiId: normalized, clearUpi: normalized == null),
        groupCount: current.groupCount,
      ));
      return null;
    } catch (_) {
      return "Couldn't save your UPI ID. Try again.";
    }
  }

  /// Uploads a new profile photo (or removes it with [bytes] == null).
  Future<String?> updatePhoto(Uint8List? bytes) async {
    final current = state;
    if (current is! ProfileLoaded) return 'Profile not loaded yet.';
    final storage = locator<StorageService>();
    try {
      final uid = current.user.id;
      String? url;
      if (bytes != null) {
        url = await storage.uploadAvatar(uid, bytes);
      } else {
        await storage.deleteByUrl(current.user.photoUrl);
      }
      await Future.wait([
        _firestore.collection('users').doc(uid).set(
          {'photoUrl': url ?? FieldValue.delete()},
          SetOptions(merge: true),
        ),
        _fbAuth.currentUser?.updatePhotoURL(url) ?? Future.value(),
      ]);
      emit(ProfileLoaded(
        user: _with(current.user, photoUrl: url, clearPhoto: url == null),
        groupCount: current.groupCount,
      ));
      return null;
    } catch (_) {
      return "Couldn't update your photo. Try again.";
    }
  }

  UserEntity _with(UserEntity u,
          {String? photoUrl,
          String? upiId,
          bool clearPhoto = false,
          bool clearUpi = false}) =>
      UserEntity(
        id: u.id,
        name: u.name,
        email: u.email,
        photoUrl: clearPhoto ? null : (photoUrl ?? u.photoUrl),
        upiId: clearUpi ? null : (upiId ?? u.upiId),
      );
}
