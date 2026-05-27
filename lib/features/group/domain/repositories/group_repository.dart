import 'package:paypact/features/group/domain/entities/group_entity.dart';

abstract class GroupRepository {
  Stream<List<GroupEntity>> watchUserGroups(String userId);
  Stream<GroupEntity?> watchGroup(String groupId);
  Future<GroupEntity?> getGroup(String groupId);
  Future<GroupEntity> createGroup({
    required String name,
    required String emoji,
    required String category,
    required String currency,
    required String createdByUid,
    required String createdByName,
  });
  Future<void> addMember(String groupId, String userId, String userName);
  Future<void> removeMember(String groupId, String userId);
  Future<void> updateGroup(String groupId, {String? name, String? emoji, String? category});
  Future<void> deleteGroup(String groupId);
}
