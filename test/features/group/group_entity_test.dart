import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('legacy groups (no adminIds) fall back to the creator as admin', () {
    final g = makeGroup(createdBy: 'alice');
    expect(g.adminIds, ['alice']);
    expect(g.isAdmin('alice'), isTrue);
    expect(g.isAdmin('bob'), isFalse);
  });

  test('explicit admins are honoured', () {
    final g = makeGroup(admins: ['alice', 'bob']);
    expect(g.isAdmin('bob'), isTrue);
  });

  test('someone who is no longer a member is never an admin', () {
    final g = makeGroup(members: ['alice'], admins: ['alice', 'bob']);
    expect(g.isAdmin('bob'), isFalse);
  });
}
