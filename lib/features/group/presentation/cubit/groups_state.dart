part of 'groups_cubit.dart';

abstract class GroupsState {}

class GroupsInitial extends GroupsState {}

class GroupsLoading extends GroupsState {}

class GroupsLoaded extends GroupsState {
  final List<GroupEntity> groups;
  final double totalNetBalance;
  GroupsLoaded({required this.groups, required this.totalNetBalance});
}

class GroupsError extends GroupsState {
  final String message;
  GroupsError(this.message);
}
