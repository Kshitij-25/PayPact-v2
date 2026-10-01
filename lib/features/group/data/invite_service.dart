import 'package:cloud_functions/cloud_functions.dart';

class InvitePreview {
  const InvitePreview({
    required this.name,
    required this.emoji,
    required this.memberCount,
    required this.alreadyMember,
  });
  final String name;
  final String emoji;
  final int memberCount;
  final bool alreadyMember;
}

class JoinResult {
  const JoinResult({
    required this.groupId,
    required this.name,
    required this.alreadyMember,
  });
  final String groupId;
  final String name;
  final bool alreadyMember;
}

/// A failure with a message that is safe to show to the user.
class InviteException implements Exception {
  const InviteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin wrapper over the `getInvitePreview` / `joinGroupByCode` callables.
/// Joining goes through a Cloud Function because the security rules (rightly)
/// don't let a non-member read or edit a group directly.
class InviteService {
  InviteService(this._functions);
  final FirebaseFunctions _functions;

  Future<InvitePreview> preview(String code) async {
    final data = await _call('getInvitePreview', code);
    return InvitePreview(
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '✨',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      alreadyMember: data['alreadyMember'] as bool? ?? false,
    );
  }

  Future<JoinResult> join(String code) async {
    final data = await _call('joinGroupByCode', code);
    return JoinResult(
      groupId: data['groupId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      alreadyMember: data['alreadyMember'] as bool? ?? false,
    );
  }

  Future<Map<String, dynamic>> _call(String name, String code) async {
    try {
      final result =
          await _functions.httpsCallable(name).call<Map<Object?, Object?>>({
        'code': code,
      });
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw InviteException(switch (e.code) {
        'not-found' => 'This invite link is no longer valid.',
        'invalid-argument' => "That doesn't look like a valid invite link.",
        'unauthenticated' => 'Please sign in to join this group.',
        'unavailable' || 'deadline-exceeded' =>
          'No connection. Check your internet and try again.',
        _ => 'Could not use this invite. Please try again.',
      });
    } catch (_) {
      throw const InviteException('Could not use this invite. Please try again.');
    }
  }
}
