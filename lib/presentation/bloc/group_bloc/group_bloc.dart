import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paypact/domain/entities/group_entity.dart';
import 'package:paypact/domain/entities/user_entity.dart';
import 'package:paypact/domain/use_cases/create_group_use_case.dart';
import 'package:paypact/domain/use_cases/generate_invite_link_use_case.dart';
import 'package:paypact/domain/use_cases/join_group_use_case.dart';
import 'package:paypact/domain/use_cases/watch_user_groups_use_case.dart';

part 'group_event.dart';
part 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  GroupBloc({
    required WatchUserGroupsUseCase watchUserGroups,
    required CreateGroupUseCase createGroup,
    required JoinGroupUseCase joinGroup,
    required GenerateInviteLinkUseCase generateInviteLink,
  })  : _watchUserGroups = watchUserGroups,
        _createGroup = createGroup,
        _joinGroup = joinGroup,
        _generateInviteLink = generateInviteLink,
        super(const GroupState()) {
    on<GroupLoadRequested>(_onLoad);
    on<GroupCreateRequested>(_onCreate);
    on<GroupJoinRequested>(_onJoin);
    on<GroupInviteLinkRequested>(_onInviteLink);
    on<_GroupListUpdated>(_onListUpdated);
  }

  final WatchUserGroupsUseCase _watchUserGroups;
  final CreateGroupUseCase _createGroup;
  final JoinGroupUseCase _joinGroup;
  final GenerateInviteLinkUseCase _generateInviteLink;
  StreamSubscription<List<GroupEntity>>? _groupsSub;

  void _onLoad(GroupLoadRequested event, Emitter<GroupState> emit) {
    emit(state.copyWith(status: GroupStatus.loading));
    _groupsSub?.cancel();
    _groupsSub = _watchUserGroups(event.userId).listen(
      (groups) => add(_GroupListUpdated(groups)),
    );
  }

  void _onListUpdated(_GroupListUpdated event, Emitter<GroupState> emit) {
    emit(state.copyWith(
      status: GroupStatus.success,
      groups: event.groups,
    ));
  }

  Future<void> _onCreate(
    GroupCreateRequested event,
    Emitter<GroupState> emit,
  ) async {
    // Don't emit loading here — it would clear the existing groups list
    // and show a shimmer. The Firestore stream will automatically push
    // the new group to _onListUpdated as soon as the write completes.
    final result = await _createGroup(event.params);
    result.fold(
      (f) => emit(state.copyWith(
        status: GroupStatus.failure,
        errorMessage: f.message,
      )),
      // On success do nothing — the realtime stream emits the update.
      (_) => null,
    );
  }

  Future<void> _onJoin(
    GroupJoinRequested event,
    Emitter<GroupState> emit,
  ) async {
    emit(state.copyWith(status: GroupStatus.loading));
    final result = await _joinGroup(
      inviteCode: event.inviteCode,
      user: event.user,
    );
    result.fold(
      (f) => emit(state.copyWith(
        status: GroupStatus.failure,
        errorMessage: f.message,
      )),
      (_) => emit(state.copyWith(status: GroupStatus.success)),
    );
  }

  Future<void> _onInviteLink(
    GroupInviteLinkRequested event,
    Emitter<GroupState> emit,
  ) async {
    final result = await _generateInviteLink(event.groupId);
    result.fold(
      (f) => emit(state.copyWith(
        status: GroupStatus.failure,
        errorMessage: f.message,
      )),
      (link) => emit(state.copyWith(inviteLink: link)),
    );
  }

  @override
  Future<void> close() {
    _groupsSub?.cancel();
    return super.close();
  }
}
