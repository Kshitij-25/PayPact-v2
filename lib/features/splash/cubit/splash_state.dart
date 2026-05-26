part of 'splash_cubit.dart';

abstract class SplashState {}

class SplashLoading extends SplashState {}

class SplashDone extends SplashState {
  final bool isAuthenticated;
  SplashDone({required this.isAuthenticated});
}
