import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/repositories/group_repository.dart';

class DeleteGroupUseCase {
  const DeleteGroupUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, Unit>> call(String groupId) =>
      _repository.deleteGroup(groupId);
}
