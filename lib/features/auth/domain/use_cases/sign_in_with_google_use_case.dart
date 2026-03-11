import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);
  final AuthRepository _repository;
  Future<Either<AuthFailure, UserEntity>> call() =>
      _repository.signInWithGoogle();
}
