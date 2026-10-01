import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/photo_store.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'create_group_state.dart';

class CreateGroupCubit extends Cubit<CreateGroupState> {
  final GroupRepository _repo;

  CreateGroupCubit(this._repo) : super(CreateGroupInitial());

  Future<void> createGroup({
    required String name,
    required String emoji,
    required String category,
    required String currency,
    required String userId,
    required String userName,
    Uint8List? coverBytes,
  }) async {
    if (name.trim().isEmpty) {
      emit(CreateGroupError('Group name cannot be empty'));
      return;
    }
    emit(CreateGroupLoading());
    try {
      final group = await _repo.createGroup(
        name: name.trim(),
        emoji: emoji,
        category: category,
        currency: currency,
        createdByUid: userId,
        createdByName: userName,
      );
      // The cover needs the group to exist (photos are members-only), so it
      // goes up afterwards; failing to upload mustn't lose the new group.
      var coverFailed = false;
      if (coverBytes != null) {
        try {
          final url =
              await locator<PhotoStore>().saveGroupCover(group.id, coverBytes);
          await _repo.setCoverUrl(group.id, url);
        } catch (_) {
          coverFailed = true;
        }
      }
      emit(CreateGroupSuccess(group, coverFailed: coverFailed));
    } catch (e) {
      emit(CreateGroupError(e.toString()));
    }
  }
}
