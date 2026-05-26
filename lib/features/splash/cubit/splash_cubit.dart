import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashLoading());

  Future<void> start() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (isClosed) return;
    final user = locator<fb.FirebaseAuth>().currentUser;
    emit(SplashDone(isAuthenticated: user != null));
  }
}
