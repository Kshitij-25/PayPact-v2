import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paypact/domain/entities/user_entity.dart';
import 'package:paypact/domain/use_cases/get_current_user_use_case.dart';
import 'package:paypact/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:paypact/domain/use_cases/sign_out_use_case.dart';
import 'package:paypact/domain/use_cases/watch_auth_state_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required WatchAuthStateUseCase watchAuthState,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
    required GetCurrentUserUseCase getCurrentUser,
  })  : _watchAuthState = watchAuthState,
        _signInWithGoogle = signInWithGoogle,
        _signOut = signOut,
        _getCurrentUser = getCurrentUser,
        super(const AuthState()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<_AuthUserChanged>(_onUserChanged);
  }

  final WatchAuthStateUseCase _watchAuthState;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;
  StreamSubscription<UserEntity?>? _authSub;

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    _authSub?.cancel();
    _authSub = _watchAuthState().listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: event.user,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      ));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _signInWithGoogle();
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await _signOut();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    ));
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
