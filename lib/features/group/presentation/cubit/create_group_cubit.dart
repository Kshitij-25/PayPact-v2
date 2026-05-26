import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(CreateGroupSuccess(group));
    } catch (e) {
      emit(CreateGroupError(e.toString()));
    }
  }
}
