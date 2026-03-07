import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paypact/domain/entities/group_entity.dart';
import 'package:paypact/domain/entities/member_entity.dart';
import 'package:paypact/domain/entities/user_entity.dart';
import 'package:paypact/domain/use_cases/add_member_to_group_use_case.dart';
import 'package:paypact/domain/use_cases/create_group_use_case.dart';
import 'package:paypact/domain/use_cases/delete_group_use_case.dart';
import 'package:paypact/domain/use_cases/generate_invite_link_use_case.dart';
import 'package:paypact/domain/use_cases/join_group_use_case.dart';
import 'package:paypact/domain/use_cases/search_user_by_email_use_case.dart';
import 'package:paypact/domain/use_cases/update_group_use_case.dart';
import 'package:paypact/domain/use_cases/watch_user_groups_use_case.dart';

part 'group_event.dart';
part 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  GroupBloc({
    required WatchUserGroupsUseCase watchUserGroups,
    required CreateGroupUseCase createGroup,
    required JoinGroupUseCase joinGroup,
    required GenerateInviteLinkUseCase generateInviteLink,
    required SearchUserByEmailUseCase searchUserByEmail,
    required AddMemberToGroupUseCase addMemberToGroup,
    required UpdateGroupUseCase updateGroup,
    required DeleteGroupUseCase deleteGroup,
  })  : _watchUserGroups = watchUserGroups,
        _createGroup = createGroup,
        _joinGroup = joinGroup,
        _generateInviteLink = generateInviteLink,
        _searchUserByEmail = searchUserByEmail,
        _addMemberToGroup = addMemberToGroup,
        _updateGroup = updateGroup,
        _deleteGroup = deleteGroup,
        super(const GroupState()) {
    on<GroupLoadRequested>(_onLoad);
    on<GroupCreateRequested>(_onCreate);
    on<GroupJoinRequested>(_onJoin);
    on<GroupInviteLinkRequested>(_onInviteLink);
    on<GroupMemberSearchRequested>(_onMemberSearch);
    on<GroupMemberAddRequested>(_onMemberAdd);
    on<GroupMemberSearchCleared>(_onMemberSearchCleared);
    on<GroupUpdateRequested>(_onUpdate);
    on<GroupDeleteRequested>(_onDelete);
    on<_GroupListUpdated>(_onListUpdated);
  }

  final WatchUserGroupsUseCase _watchUserGroups;
  final CreateGroupUseCase _createGroup;
  final JoinGroupUseCase _joinGroup;
  final GenerateInviteLinkUseCase _generateInviteLink;
  final SearchUserByEmailUseCase _searchUserByEmail;
  final AddMemberToGroupUseCase _addMemberToGroup;
  final UpdateGroupUseCase _updateGroup;
  final DeleteGroupUseCase _deleteGroup;
  StreamSubscription<List<GroupEntity>>? _groupsSub;

  void _onLoad(GroupLoadRequested event, Emitter<GroupState> emit) {
    emit(state.copyWith(status: GroupStatus.loading));
    _groupsSub?.cancel();
    _groupsSub = _watchUserGroups(event.userId).listen(
      (groups) => add(_GroupListUpdated(groups)),
    );
  }

  void _onListUpdated(_GroupListUpdated event, Emitter<GroupState> emit) {
    emit(state.copyWith(status: GroupStatus.success, groups: event.groups));
  }

  Future<void> _onCreate(
      GroupCreateRequested event, Emitter<GroupState> emit) async {
    final result = await _createGroup(event.params);
    result.fold(
      (f) => emit(
          state.copyWith(status: GroupStatus.failure, errorMessage: f.message)),
      (_) => null,
    );
  }

  Future<void> _onJoin(
      GroupJoinRequested event, Emitter<GroupState> emit) async {
    emit(state.copyWith(status: GroupStatus.loading));
    final result = await _joinGroup(
      inviteCode: event.inviteCode,
      user: event.user,
    );
    result.fold(
      (f) => emit(
          state.copyWith(status: GroupStatus.failure, errorMessage: f.message)),
      (_) => emit(state.copyWith(status: GroupStatus.success)),
    );
  }

  Future<void> _onInviteLink(
      GroupInviteLinkRequested event, Emitter<GroupState> emit) async {
    final result = await _generateInviteLink(event.groupId);
    result.fold(
      (f) => emit(
          state.copyWith(status: GroupStatus.failure, errorMessage: f.message)),
      (link) => emit(state.copyWith(inviteLink: link)),
    );
  }

  Future<void> _onMemberSearch(
      GroupMemberSearchRequested event, Emitter<GroupState> emit) async {
    emit(state.copyWith(
      memberSearchStatus: MemberSearchStatus.searching,
      clearFoundUser: true,
      memberSearchError: null,
    ));
    final result = await _searchUserByEmail(event.email);
    result.fold(
      (f) => emit(state.copyWith(
        memberSearchStatus: MemberSearchStatus.notFound,
        memberSearchError: f.message,
      )),
      (user) {
        if (user == null) {
          emit(state.copyWith(memberSearchStatus: MemberSearchStatus.notFound));
          return;
        }
        final group =
            state.groups.where((g) => g.id == event.groupId).firstOrNull;
        final alreadyMember =
            group?.members.any((m) => m.userId == user.id) ?? false;
        emit(state.copyWith(
          memberSearchStatus: alreadyMember
              ? MemberSearchStatus.alreadyMember
              : MemberSearchStatus.found,
          foundUser: user,
        ));
      },
    );
  }

  Future<void> _onMemberAdd(
      GroupMemberAddRequested event, Emitter<GroupState> emit) async {
    emit(state.copyWith(memberSearchStatus: MemberSearchStatus.adding));
    final member = MemberEntity(
      userId: event.user.id,
      displayName: event.user.displayName,
      email: event.user.email,
      photoUrl: event.user.photoUrl,
      joinedAt: DateTime.now(),
      role: MemberRole.member,
    );
    final result =
        await _addMemberToGroup(groupId: event.groupId, member: member);
    result.fold(
      (f) => emit(state.copyWith(
        memberSearchStatus: MemberSearchStatus.addFailure,
        memberSearchError: f.message,
      )),
      (_) => emit(state.copyWith(
        memberSearchStatus: MemberSearchStatus.added,
        clearFoundUser: true,
      )),
    );
  }

  void _onMemberSearchCleared(
      GroupMemberSearchCleared event, Emitter<GroupState> emit) {
    emit(state.copyWith(
      memberSearchStatus: MemberSearchStatus.idle,
      clearFoundUser: true,
      memberSearchError: null,
    ));
  }

  Future<void> _onUpdate(
      GroupUpdateRequested event, Emitter<GroupState> emit) async {
    final result = await _updateGroup(event.group);
    result.fold(
      (f) => emit(
          state.copyWith(status: GroupStatus.failure, errorMessage: f.message)),
      (_) => emit(state.copyWith(status: GroupStatus.success)),
    );
  }

  Future<void> _onDelete(
      GroupDeleteRequested event, Emitter<GroupState> emit) async {
    emit(state.copyWith(status: GroupStatus.loading));
    final result = await _deleteGroup(event.groupId);
    result.fold(
      (f) => emit(
          state.copyWith(status: GroupStatus.failure, errorMessage: f.message)),
      (_) => emit(state.copyWith(status: GroupStatus.success)),
    );
  }

  @override
  Future<void> close() {
    _groupsSub?.cancel();
    return super.close();
  }
}
