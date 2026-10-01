import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/auth/domain/account_deletion_plan.dart';

GroupForDeletion _g(String id,
        {List<String> members = const ['me', 'x'],
        List<String> admins = const ['me'],
        int net = 0}) =>
    GroupForDeletion(
      id: id,
      name: id,
      currency: 'INR',
      memberIds: members,
      adminIds: admins,
      createdBy: 'me',
      netMinor: net,
    );

void main() {
  test('a group of one is deleted, whatever the balance', () {
    final plan = planAccountDeletion('me', [_g('solo', members: ['me'], net: 500)]);
    expect(plan.blockers, isEmpty);
    expect(plan.actions.single.type, DeletionActionType.deleteGroup);
  });

  test('an outstanding balance blocks the deletion', () {
    final plan = planAccountDeletion('me', [_g('trip', net: -2500)]);
    expect(plan.blockers.single.id, 'trip');
    expect(plan.actions, isEmpty);
  });

  test('settled groups are left, and a sole admin hands over', () {
    final plan = planAccountDeletion('me', [
      _g('a', members: ['me', 'x', 'y']),
      _g('b', members: ['me', 'x'], admins: ['me', 'x']),
    ]);
    expect(plan.blockers, isEmpty);
    expect(plan.actions[0].type, DeletionActionType.leave);
    expect(plan.actions[0].promote, 'x');
    expect(plan.actions[1].promote, isNull); // another admin already exists
  });

  test('legacy groups without admins fall back to the creator', () {
    final plan = planAccountDeletion('me', [_g('old', admins: [])]);
    expect(plan.actions.single.promote, 'x');
  });

  test('one blocked group does not stop the others being planned', () {
    final plan = planAccountDeletion(
        'me', [_g('owes', net: 100), _g('ok'), _g('solo', members: ['me'])]);
    expect(plan.blockers.map((b) => b.id), ['owes']);
    expect(plan.actions.map((a) => a.group.id), ['ok', 'solo']);
  });
}
