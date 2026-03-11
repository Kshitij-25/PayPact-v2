import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

class AddMemberToGroupUseCase {
  const AddMemberToGroupUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String groupId,
    required MemberEntity member,
  }) =>
      _repository.addMember(groupId, member);
}
