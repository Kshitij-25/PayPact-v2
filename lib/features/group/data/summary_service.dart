import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/group_summary.dart';

/// Builds a group's balance/total summary from its full history. Used for
/// groups that predate the summary, and as the "Recalculate balances" repair.
/// When it finishes the group document changes and the app's live listeners
/// pick the summary up on their own.
class SummaryService {
  SummaryService(this._firestore, this._expenses);
  final FirebaseFirestore _firestore;
  final ExpenseRepository _expenses;

  final Set<String> _requested = {};

  /// Fire-and-forget, once per group per session.
  void ensure(String groupId) {
    if (!_requested.add(groupId)) return;
    rebuild(groupId).then<void>((_) {}, onError: (_) {
      _requested.remove(groupId); // let a later refresh retry
    });
  }

  /// Recomputes the summary from every expense and settlement and stores it.
  Future<RebuiltSummary?> rebuild(String groupId) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final group = await groupRef.get();
    if (!group.exists) return null;
    final memberIds =
        List<String>.from((group.data()?['memberIds'] as List?) ?? const []);
    final expenses = _expenses.getGroupExpenses(groupId);
    final settlements = _expenses.getGroupSettlements(groupId);
    final summary = buildSummary(
      expenses: await expenses,
      settlements: await settlements,
      memberIds: memberIds,
    );
    await groupRef.update({
      ...summary.toUpdate(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return summary;
  }
}
