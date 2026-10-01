// Decides what deleting an account means for each group the user is in.
// Pure so it can be tested; AccountService applies the plan.

class GroupForDeletion {
  const GroupForDeletion({
    required this.id,
    required this.name,
    required this.currency,
    required this.memberIds,
    required this.adminIds,
    required this.createdBy,
    required this.netMinor,
  });
  final String id;
  final String name;
  final String currency;
  final List<String> memberIds;
  final List<String> adminIds;
  final String createdBy;

  /// + = the user is owed, − = the user owes (minor units).
  final int netMinor;
}

enum DeletionActionType { deleteGroup, leave }

class DeletionAction {
  const DeletionAction(this.type, this.group, {this.promote});
  final DeletionActionType type;
  final GroupForDeletion group;

  /// Sole admin leaving: the member who takes over.
  final String? promote;
}

class AccountDeletionPlan {
  const AccountDeletionPlan(this.blockers, this.actions);
  final List<GroupForDeletion> blockers;
  final List<DeletionAction> actions;
}

AccountDeletionPlan planAccountDeletion(
    String uid, List<GroupForDeletion> groups) {
  final blockers = <GroupForDeletion>[];
  final actions = <DeletionAction>[];

  for (final g in groups) {
    final others = g.memberIds.where((m) => m != uid).toList();

    // A group of one disappears with its only member, whatever the balance.
    if (others.isEmpty) {
      actions.add(DeletionAction(DeletionActionType.deleteGroup, g));
      continue;
    }

    // Leaving with a balance would strand money and break the group's books.
    if (g.netMinor != 0) {
      blockers.add(g);
      continue;
    }

    final admins = g.adminIds.isEmpty ? [g.createdBy] : g.adminIds;
    final otherAdmins =
        admins.where((a) => a != uid && others.contains(a)).toList();
    // Sole admin: hand the group to the longest-standing remaining member.
    final promote =
        admins.contains(uid) && otherAdmins.isEmpty ? others.first : null;
    actions.add(DeletionAction(DeletionActionType.leave, g, promote: promote));
  }
  return AccountDeletionPlan(blockers, actions);
}
