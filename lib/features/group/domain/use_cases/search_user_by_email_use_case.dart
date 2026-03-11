import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

class SearchUserByEmailUseCase {
  const SearchUserByEmailUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, UserEntity?>> call(String email) =>
      _repository.searchUserByEmail(email);
}
