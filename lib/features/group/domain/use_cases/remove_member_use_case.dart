import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

class RemoveMemberUseCase {
  const RemoveMemberUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String groupId,
    required String userId,
  }) =>
      _repository.removeMember(groupId, userId);
}
