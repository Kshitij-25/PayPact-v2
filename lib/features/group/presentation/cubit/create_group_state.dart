part of 'create_group_cubit.dart';

abstract class CreateGroupState {}

class CreateGroupInitial extends CreateGroupState {}

class CreateGroupLoading extends CreateGroupState {}

class CreateGroupSuccess extends CreateGroupState {
  final GroupEntity group;
  CreateGroupSuccess(this.group);
}

class CreateGroupError extends CreateGroupState {
  final String message;
  CreateGroupError(this.message);
}
