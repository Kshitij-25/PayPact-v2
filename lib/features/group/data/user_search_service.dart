import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/auth/data/user_directory.dart';

class UserSearchHit {
  const UserSearchHit({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });
  final String id;
  final String name;

  /// Masked (`k••••@gmail.com`) — full addresses are never readable.
  final String email;
  final String? photoUrl;
}

/// People search over the public [UserDirectory]: a case-insensitive name
/// prefix, or an exact e-mail address (matched by hash).
class UserSearchService {
  UserSearchService(this._firestore);
  final FirebaseFirestore _firestore;

  static const _limit = 12;

  Future<List<UserSearchHit>> search(String query,
      {Iterable<String> excludeIds = const []}) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final dir = _firestore.collection('directory');
    final Query<Map<String, dynamic>> ref = q.contains('@')
        ? dir.where('emailHash', isEqualTo: UserDirectory.emailHash(q)).limit(5)
        : dir
            .orderBy('nameLower')
            .startAt([q])
            .endAt(['$q'])
            .limit(_limit + excludeIds.length.clamp(0, 8));
    final snap = await ref.get();
    final skip = excludeIds.toSet();
    return [
      for (final d in snap.docs)
        if (!skip.contains(d.id))
          UserSearchHit(
            id: d.id,
            name: d.data()['name'] as String? ?? '',
            email: d.data()['emailMasked'] as String? ?? '',
            photoUrl: d.data()['photoUrl'] as String?,
          ),
    ].take(_limit).toList();
  }
}
