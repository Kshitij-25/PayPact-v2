import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  final Future<void> Function(String userId)? _onBeforeSignOut;
  StreamSubscription<UserEntity?>? _sub;

  AuthCubit(this._repo, {Future<void> Function(String userId)? onBeforeSignOut})
      : _onBeforeSignOut = onBeforeSignOut,
        super(AuthInitial());

  void init() {
    _sub = _repo.authStateChanges.listen(
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      },
      onError: (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _repo.signInWithEmailAndPassword(email, password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> createAccount(
      String email, String password, String name) async {
    emit(AuthLoading());
    try {
      final user = await _repo.createUserWithEmailAndPassword(
          email, password, name);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _repo.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  /// Sends a password-reset email. Returns an error message, or null on
  /// success. Deliberately doesn't emit auth states so the sign-in form isn't
  /// disturbed. Firebase (with email-enumeration protection) reports success
  /// for unknown addresses too, so callers should word success generically.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordResetEmail(email.trim());
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  bool get isEmailVerified => _repo.isEmailVerified;

  /// Sends a verification email; returns an error message or null on success.
  Future<String?> sendEmailVerification() async {
    try {
      await _repo.sendEmailVerification();
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  /// Refreshes the account from Firebase; true once the email is verified.
  Future<bool> refreshEmailVerified() async {
    try {
      return await _repo.reloadEmailVerified();
    } catch (_) {
      return _repo.isEmailVerified;
    }
  }

  Future<void> signInWithApple() async {
    emit(AuthLoading());
    try {
      final user = await _repo.signInWithApple();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_friendlyError(e)));
    }
  }

  Future<void> signOut() async {
    final uid = _repo.currentUser?.id;
    if (uid != null) {
      try {
        await _onBeforeSignOut?.call(uid);
      } catch (_) {
        // Never let cleanup block signing out.
      }
    }
    await _repo.signOut();
    emit(AuthUnauthenticated());
  }

  UserEntity? get currentUser => _repo.currentUser;

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('user-not-found')) return 'No account found for that email.';
    if (msg.contains('email-already-in-use')) return 'Email is already in use.';
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('invalid-email')) return 'Enter a valid email address.';
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (msg.contains('network-request-failed')) return 'No internet connection.';
    if (msg.contains('cancelled') ||
        msg.contains('canceled') ||
        msg.contains('popup-closed-by-user')) {
      return 'Sign-in was cancelled.';
    }
    if (msg.contains('operation-not-allowed') ||
        msg.contains('invalid-oauth-client-id')) {
      return "That sign-in method isn't set up for this app yet.";
    }
    if (msg.contains('requires-recent-login')) {
      return 'Please sign in again to do that.';
    }
    if (msg.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email using another sign-in method.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
