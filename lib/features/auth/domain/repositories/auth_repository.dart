import 'package:paypact/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> createUserWithEmailAndPassword(
      String email, String password, String name);
  Future<UserEntity> signInWithGoogle();
  Future<void> signOut();
  UserEntity? get currentUser;
}
