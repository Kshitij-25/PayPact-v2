part of 'group_bloc.dart';

enum GroupStatus { initial, loading, success, failure }

enum MemberSearchStatus {
  idle,
  searching,
  found,
  notFound,
  alreadyMember,
  adding,
  added,
  addFailure
}

class GroupState extends Equatable {
  const GroupState({
    this.status = GroupStatus.initial,
    this.groups = const [],
    this.inviteLink,
    this.errorMessage,
    this.memberSearchStatus = MemberSearchStatus.idle,
    this.foundUser,
    this.memberSearchError,
  });

  final GroupStatus status;
  final List<GroupEntity> groups;
  final String? inviteLink;
  final String? errorMessage;
  final MemberSearchStatus memberSearchStatus;
  final UserEntity? foundUser;
  final String? memberSearchError;

  GroupState copyWith({
    GroupStatus? status,
    List<GroupEntity>? groups,
    String? inviteLink,
    String? errorMessage,
    MemberSearchStatus? memberSearchStatus,
    UserEntity? foundUser,
    bool clearFoundUser = false,
    String? memberSearchError,
  }) =>
      GroupState(
        status: status ?? this.status,
        groups: groups ?? this.groups,
        inviteLink: inviteLink ?? this.inviteLink,
        errorMessage: errorMessage ?? this.errorMessage,
        memberSearchStatus: memberSearchStatus ?? this.memberSearchStatus,
        foundUser: clearFoundUser ? null : (foundUser ?? this.foundUser),
        memberSearchError: memberSearchError ?? this.memberSearchError,
      );

  @override
  List<Object?> get props => [
        status,
        groups,
        inviteLink,
        errorMessage,
        memberSearchStatus,
        foundUser,
        memberSearchError
      ];
}
