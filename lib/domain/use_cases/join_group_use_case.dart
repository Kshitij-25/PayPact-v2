import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/entities/group_entity.dart';
import 'package:paypact/domain/entities/user_entity.dart';
import 'package:paypact/domain/repositories/group_repository.dart';

class JoinGroupUseCase {
  const JoinGroupUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, GroupEntity>> call({
    required String inviteCode,
    required UserEntity user,
  }) =>
      _repository.joinGroupByInviteCode(inviteCode, user);
}
