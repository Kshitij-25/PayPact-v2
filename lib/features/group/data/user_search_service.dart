import 'package:cloud_functions/cloud_functions.dart';

class UserSearchHit {
  const UserSearchHit({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });
  final String id;
  final String name;

  /// Masked (`k••••@gmail.com`) — full addresses are never sent to the app.
  final String email;
  final String? photoUrl;
}

/// People search via the `searchUsers` Cloud Function. The users collection
/// can't be listed from the app, so the server does the lookup (name prefix,
/// case-insensitive, or an exact email) and masks email addresses.
class UserSearchService {
  UserSearchService(this._functions);
  final FirebaseFunctions _functions;

  Future<List<UserSearchHit>> search(String query,
      {Iterable<String> excludeIds = const []}) async {
    final result = await _functions
        .httpsCallable('searchUsers')
        .call<Map<Object?, Object?>>({
      'query': query,
      'excludeIds': excludeIds.toList(),
    });
    final users = (result.data['users'] as List? ?? []);
    return [
      for (final u in users)
        UserSearchHit(
          id: (u as Map)['id'] as String,
          name: u['name'] as String? ?? '',
          email: u['email'] as String? ?? '',
          photoUrl: u['photoUrl'] as String?,
        ),
    ];
  }
}
