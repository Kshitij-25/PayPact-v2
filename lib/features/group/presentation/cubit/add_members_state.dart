part of 'add_members_cubit.dart';

class UserResult {
  final String id;
  final String name;
  final String email;

  const UserResult({required this.id, required this.name, required this.email});

  factory UserResult.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserResult(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
    );
  }
}

abstract class AddMembersState {}

class AddMembersIdle extends AddMembersState {
  final List<UserResult> results;
  AddMembersIdle(this.results);
}

class AddMembersSearching extends AddMembersState {
  final String query;
  AddMembersSearching(this.query);
}

class AddMembersSearchDone extends AddMembersState {
  final String query;
  final List<UserResult> results;
  AddMembersSearchDone(this.query, this.results);
}

class AddMembersAdding extends AddMembersState {}

class AddMembersDone extends AddMembersState {}

class AddMembersError extends AddMembersState {
  final String message;
  AddMembersError(this.message);
}
