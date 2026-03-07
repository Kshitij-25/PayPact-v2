import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/repositories/group_repository.dart';

class GenerateInviteLinkUseCase {
  const GenerateInviteLinkUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, String>> call(String groupId) =>
      _repository.generateInviteLink(groupId);
}
