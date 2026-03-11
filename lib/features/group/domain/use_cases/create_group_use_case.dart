import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

class CreateGroupParams {
  const CreateGroupParams({
    required this.name,
    required this.createdBy,
    this.category = GroupCategory.other,
    this.imageUrl,
    this.currency = 'USD',
    this.creatorDisplayName = '',
    this.creatorEmail = '',
    this.creatorPhotoUrl,
  });

  final String name;
  final String createdBy;
  final GroupCategory category;
  final String? imageUrl;
  final String currency;
  final String creatorDisplayName;
  final String creatorEmail;
  final String? creatorPhotoUrl;
}

class CreateGroupUseCase {
  const CreateGroupUseCase(this._repository);
  final GroupRepository _repository;

  Future<Either<Failure, GroupEntity>> call(CreateGroupParams params) =>
      _repository.createGroup(
        name: params.name,
        createdBy: params.createdBy,
        category: params.category,
        imageUrl: params.imageUrl,
        currency: params.currency,
        creatorDisplayName: params.creatorDisplayName,
        creatorEmail: params.creatorEmail,
        creatorPhotoUrl: params.creatorPhotoUrl,
      );
}
