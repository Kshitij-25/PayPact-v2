import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashLoading());

  Future<void> start() async {
    final auth = locator<fb.FirebaseAuth>();
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2200)),
      auth.authStateChanges().first,
    ]);
    if (isClosed) return;
    final user = results[1] as fb.User?;
    emit(SplashDone(isAuthenticated: user != null));
  }
}
