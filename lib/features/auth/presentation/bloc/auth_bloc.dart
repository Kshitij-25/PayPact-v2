import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:paypact/features/auth/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:paypact/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:paypact/features/auth/domain/use_cases/watch_auth_state_use_case.dart';

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

  bool _isFirstAuthEvent = true;

  Future<void> _onAuthStarted(
      AuthStarted event, Emitter<AuthState> emit) async {
    _authSub?.cancel();

    // Run the auth check and a minimum splash timer in parallel.
    // Both must complete before we proceed — guarantees splash is visible
    // for at least 600 ms regardless of how fast Firebase responds.
    final results = await Future.wait([
      _getCurrentUser(),
      Future.delayed(const Duration(seconds: 1)),
    ]);

    final result = results[0] as dynamic;
    result.fold(
      (_) {
        // No cached user → genuinely not signed in.
        // Emit unauthenticated now so the router goes to sign-in directly
        // without waiting for the stream's first event.
        if (state.status == AuthStatus.initial) {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      },
      (user) {
        // A user exists in the local cache → we're authenticated.
        // Emit now so the router goes home without waiting for Firestore.
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      },
    );

    _authSub = _watchAuthState().listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      _isFirstAuthEvent = false;
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: event.user,
      ));
    } else {
      // Guard: if this is the very first stream event and we already emitted
      // authenticated (from the seed above), ignore this null — it's the
      // transient null Firebase emits while restoring the session.
      if (_isFirstAuthEvent && state.status == AuthStatus.authenticated) {
        _isFirstAuthEvent = false;
        return;
      }
      _isFirstAuthEvent = false;
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
