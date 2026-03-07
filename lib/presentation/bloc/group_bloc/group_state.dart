part of 'group_bloc.dart';

enum GroupStatus { initial, loading, success, failure }

class GroupState extends Equatable {
  const GroupState({
    this.status = GroupStatus.initial,
    this.groups = const [],
    this.inviteLink,
    this.errorMessage,
  });

  final GroupStatus status;
  final List<GroupEntity> groups;
  final String? inviteLink;
  final String? errorMessage;

  GroupState copyWith({
    GroupStatus? status,
    List<GroupEntity>? groups,
    String? inviteLink,
    String? errorMessage,
  }) =>
      GroupState(
        status: status ?? this.status,
        groups: groups ?? this.groups,
        inviteLink: inviteLink ?? this.inviteLink,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, groups, inviteLink, errorMessage];
}
