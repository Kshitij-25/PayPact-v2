import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashLoading());

  Future<void> start() async {
    // Wait on the app's own AuthCubit (not the raw Firebase stream) so the
    // router's auth guard agrees with us about who's signed in by the time we
    // navigate.
    final auth = locator<AuthCubit>();
    bool resolved(AuthState s) =>
        s is AuthAuthenticated || s is AuthUnauthenticated;
    final results = await Future.wait<Object?>([
      Future.delayed(const Duration(milliseconds: 2200)),
      resolved(auth.state)
          ? Future.value(auth.state)
          : auth.stream.firstWhere(resolved),
    ]);
    if (isClosed) return;
    emit(SplashDone(isAuthenticated: results[1] is AuthAuthenticated));
  }
}
