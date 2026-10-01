import 'package:paypact/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> createUserWithEmailAndPassword(
      String email, String password, String name);
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();

  /// True when the signed-in account's email is verified. Non-password
  /// sign-ins (Google) are verified by the provider.
  bool get isEmailVerified;

  /// Re-reads the account from Firebase and returns the fresh verified flag.
  Future<bool> reloadEmailVerified();
  Future<void> signOut();
  UserEntity? get currentUser;
}
