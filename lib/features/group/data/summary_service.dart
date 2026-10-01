import 'package:cloud_functions/cloud_functions.dart';

/// Asks the backend to build the balance/total summary for a group that
/// predates it. Fire-and-forget: when it finishes the group document changes
/// and the app's live listeners pick the summary up on their own.
class SummaryService {
  SummaryService(this._functions);
  final FirebaseFunctions _functions;

  final Set<String> _requested = {};

  void ensure(String groupId) {
    if (!_requested.add(groupId)) return; // once per group per session
    _functions
        .httpsCallable('recomputeGroupSummary')
        .call<void>({'groupId': groupId}).catchError((_) {
      _requested.remove(groupId); // let a later refresh retry
      return null as dynamic;
    });
  }
}
