import 'package:paypact/domain/entities/group_entity.dart';
import 'package:paypact/domain/repositories/group_repository.dart';

class WatchUserGroupsUseCase {
  const WatchUserGroupsUseCase(this._repository);
  final GroupRepository _repository;
  Stream<List<GroupEntity>> call(String userId) =>
      _repository.watchUserGroups(userId);
}
