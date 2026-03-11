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

class GroupMemberSearchRequested extends GroupEvent {
  GroupMemberSearchRequested({required this.email, required this.groupId});
  final String email;
  final String groupId;
}

class GroupMemberAddRequested extends GroupEvent {
  GroupMemberAddRequested({required this.groupId, required this.user});
  final String groupId;
  final UserEntity user;
}

class GroupMemberSearchCleared extends GroupEvent {}

class GroupUpdateRequested extends GroupEvent {
  GroupUpdateRequested(this.group);
  final GroupEntity group;
}

class GroupDeleteRequested extends GroupEvent {
  GroupDeleteRequested(this.groupId);
  final String groupId;
}

class GroupLeaveRequested extends GroupEvent {
  GroupLeaveRequested({required this.groupId, required this.userId});
  final String groupId;
  final String userId;
}

class GroupKickMemberRequested extends GroupEvent {
  GroupKickMemberRequested({required this.groupId, required this.userId});
  final String groupId;
  final String userId;
}

class _GroupListUpdated extends GroupEvent {
  _GroupListUpdated(this.groups);
  final List<GroupEntity> groups;
}
