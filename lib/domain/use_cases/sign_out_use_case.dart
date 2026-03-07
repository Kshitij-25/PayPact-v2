import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._repository);
  final AuthRepository _repository;
  Future<Either<AuthFailure, Unit>> call() => _repository.signOut();
}
