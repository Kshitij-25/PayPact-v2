part of 'profile_cubit.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  final int groupCount;
  ProfileLoaded({required this.user, required this.groupCount});
}

class ProfileSaving extends ProfileState {
  final UserEntity user;
  ProfileSaving(this.user);
}

class ProfileSaved extends ProfileState {
  final UserEntity user;
  ProfileSaved(this.user);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
