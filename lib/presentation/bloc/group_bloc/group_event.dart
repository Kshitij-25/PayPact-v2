part of 'group_bloc.dart';

abstract class GroupEvent {}

class GroupLoadRequested extends GroupEvent {
  GroupLoadRequested(this.userId);
  final String userId;
}

class GroupCreateRequested extends GroupEvent {
  GroupCreateRequested(this.params);
  final CreateGroupParams params;
}

class GroupJoinRequested extends GroupEvent {
  GroupJoinRequested({required this.inviteCode, required this.user});
  final String inviteCode;
  final UserEntity user;
}

class GroupInviteLinkRequested extends GroupEvent {
  GroupInviteLinkRequested(this.groupId);
  final String groupId;
}

class _GroupListUpdated extends GroupEvent {
  _GroupListUpdated(this.groups);
  final List<GroupEntity> groups;
}
