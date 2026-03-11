import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Returns the currently authenticated user or null
  Stream<UserEntity?> get authStateChanges;

  Future<Either<AuthFailure, UserEntity>> signInWithGoogle();

  Future<Either<AuthFailure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserEntity>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Either<AuthFailure, Unit>> signOut();

  Future<Either<AuthFailure, UserEntity>> getCurrentUser();

  Future<Either<AuthFailure, Unit>> updateFcmToken(String token);

  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail(String email);

  Future<Either<AuthFailure, Unit>> deleteAccount();
}
