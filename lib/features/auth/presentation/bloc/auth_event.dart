part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthStarted extends AuthEvent {}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class _AuthUserChanged extends AuthEvent {
  _AuthUserChanged(this.user);
  final UserEntity? user;
}
