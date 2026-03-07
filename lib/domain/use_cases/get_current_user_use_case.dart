import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/entities/user_entity.dart';
import 'package:paypact/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;
  Future<Either<AuthFailure, UserEntity>> call() =>
      _repository.getCurrentUser();
}
