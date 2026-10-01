part of 'create_group_cubit.dart';

abstract class CreateGroupState {}

class CreateGroupInitial extends CreateGroupState {}

class CreateGroupLoading extends CreateGroupState {}

class CreateGroupSuccess extends CreateGroupState {
  final GroupEntity group;

  /// A cover photo was chosen but couldn't be uploaded (the group itself
  /// was created fine).
  final bool coverFailed;
  CreateGroupSuccess(this.group, {this.coverFailed = false});
}

class CreateGroupError extends CreateGroupState {
  final String message;
  CreateGroupError(this.message);
}
