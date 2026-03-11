import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

class UpdateGroupUseCase {
  const UpdateGroupUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, GroupEntity>> call(GroupEntity group) =>
      _repository.updateGroup(group);
}
