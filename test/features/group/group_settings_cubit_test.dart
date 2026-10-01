import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/group_settings_cubit.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

import 'test_helpers.dart';

class _GroupRepo extends Mock implements GroupRepository {}

class _ExpenseRepo extends Mock implements ExpenseRepository {}

class _NotifRepo extends Mock implements NotificationsRepository {}

void main() {
  late _GroupRepo groups;
  late _ExpenseRepo expenses;
  late _NotifRepo notifs;
  late GroupSettingsCubit cubit;

  Future<void> loadWith(GroupEntity g) async {
    when(() => groups.getGroup('g1')).thenAnswer((_) async => g);
    await cubit.load();
  }

  setUp(() {
    groups = _GroupRepo();
    expenses = _ExpenseRepo();
    notifs = _NotifRepo();
    cubit = GroupSettingsCubit(groups, notifs, expenses, 'g1');

    when(() => expenses.getGroupExpenses('g1')).thenAnswer((_) async => []);
    when(() => expenses.getGroupSettlements('g1')).thenAnswer((_) async => []);
    when(() => groups.removeMember(any(), any())).thenAnswer((_) async {});
    when(() => groups.deleteGroup(any())).thenAnswer((_) async {});
    when(() => groups.setAdmin(any(), any(), isAdmin: any(named: 'isAdmin')))
        .thenAnswer((_) async {});
    when(() => notifs.push(
          targetUserId: any(named: 'targetUserId'),
          type: any(named: 'type'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          groupId: any(named: 'groupId'),
          groupName: any(named: 'groupName'),
          actorId: any(named: 'actorId'),
          actorName: any(named: 'actorName'),
        )).thenAnswer((_) async {});
  });

  tearDown(() => cubit.close());

  String noticeOf() => (cubit.state as GroupSettingsNotice).message;

  group('removeMember', () {
    test('refuses while the member still owes money', () async {
      // bob owes alice 50 (alice paid 100, split evenly).
      when(() => expenses.getGroupExpenses('g1')).thenAnswer((_) async => [
            makeExpense(payer: 'alice', total: 100, among: ['alice', 'bob'])
          ]);
      await loadWith(makeGroup());

      await cubit.removeMember('bob', actorId: 'alice', actorName: 'Alice');

      expect(cubit.state, isA<GroupSettingsNotice>());
      expect(noticeOf(), contains('Bob still owes ₹50'));
      verifyNever(() => groups.removeMember(any(), any()));
    });

    test('refuses while the member is still owed money', () async {
      when(() => expenses.getGroupExpenses('g1')).thenAnswer((_) async => [
            makeExpense(payer: 'bob', total: 100, among: ['alice', 'bob'])
          ]);
      await loadWith(makeGroup());

      await cubit.removeMember('bob', actorId: 'alice', actorName: 'Alice');

      expect(noticeOf(), contains('Bob is still owed ₹50'));
      verifyNever(() => groups.removeMember(any(), any()));
    });

    test('removes a settled-up member and notifies them', () async {
      final g = makeGroup();
      await loadWith(g);

      await cubit.removeMember('bob', actorId: 'alice', actorName: 'Alice');

      verify(() => groups.removeMember('g1', 'bob')).called(1);
      verify(() => notifs.push(
            targetUserId: 'bob',
            type: 'member_removed',
            title: any(named: 'title'),
            body: any(named: 'body'),
            groupId: 'g1',
            groupName: 'Trip',
            actorId: 'alice',
            actorName: 'Alice',
          )).called(1);
    });

    test('only admins may remove, and admins must be demoted first', () async {
      await loadWith(makeGroup(members: ['alice', 'bob', 'cy'], admins: ['alice', 'bob']));

      await cubit.removeMember('cy', actorId: 'bob', actorName: 'Bob');
      verify(() => groups.removeMember('g1', 'cy')).called(1);

      await cubit.removeMember('bob', actorId: 'alice', actorName: 'Alice');
      expect(noticeOf(), contains('admin'));

      // a plain member can't remove anyone
      await loadWith(makeGroup(members: ['alice', 'bob', 'cy']));
      await cubit.removeMember('cy', actorId: 'bob', actorName: 'Bob');
      expect(noticeOf(), 'Only admins can remove members.');
    });
  });

  group('leave', () {
    test('blocked with an unsettled balance', () async {
      when(() => expenses.getGroupExpenses('g1')).thenAnswer((_) async => [
            makeExpense(payer: 'alice', total: 100, among: ['alice', 'bob'])
          ]);
      await loadWith(makeGroup(admins: ['alice', 'bob']));

      await cubit.leave(userId: 'bob', userName: 'Bob');

      expect(noticeOf(), contains('You still owe ₹50'));
      verifyNever(() => groups.removeMember(any(), any()));
    });

    test('the only admin cannot leave a group that has other members',
        () async {
      await loadWith(makeGroup());

      await cubit.leave(userId: 'alice', userName: 'Alice');

      expect(noticeOf(), contains('only admin'));
      verifyNever(() => groups.removeMember(any(), any()));
    });

    test('a member leaves and the others are told', () async {
      await loadWith(makeGroup(members: ['alice', 'bob', 'cy']));

      await cubit.leave(userId: 'bob', userName: 'Bob');

      verify(() => groups.removeMember('g1', 'bob')).called(1);
      expect(cubit.state, isA<GroupSettingsLeft>());
      verify(() => notifs.push(
            targetUserId: any(named: 'targetUserId'),
            type: 'member_removed',
            title: any(named: 'title'),
            body: any(named: 'body'),
            groupId: 'g1',
            groupName: 'Trip',
            actorId: 'bob',
            actorName: 'Bob',
          )).called(2); // alice + cy
    });

    test('the last member out deletes the group', () async {
      await loadWith(makeGroup(members: ['alice']));

      await cubit.leave(userId: 'alice', userName: 'Alice');

      verify(() => groups.deleteGroup('g1')).called(1);
      verifyNever(() => groups.removeMember(any(), any()));
      expect(cubit.state, isA<GroupSettingsDeleted>());
    });
  });

  group('setAdmin', () {
    test('an admin can promote a member and the member is told', () async {
      await loadWith(makeGroup());

      await cubit.setAdmin('bob',
          isAdmin: true, actorId: 'alice', actorName: 'Alice');

      verify(() => groups.setAdmin('g1', 'bob', isAdmin: true)).called(1);
      verify(() => notifs.push(
            targetUserId: 'bob',
            type: 'group_updated',
            title: any(named: 'title'),
            body: any(named: 'body'),
            groupId: 'g1',
            groupName: 'Trip',
            actorId: 'alice',
            actorName: 'Alice',
          )).called(1);
    });

    test('non-admins cannot change roles', () async {
      await loadWith(makeGroup());

      await cubit.setAdmin('bob',
          isAdmin: true, actorId: 'bob', actorName: 'Bob');

      expect(noticeOf(), 'Only admins can change roles.');
      verifyNever(
          () => groups.setAdmin(any(), any(), isAdmin: any(named: 'isAdmin')));
    });

    test('the last admin cannot be demoted', () async {
      await loadWith(makeGroup());

      await cubit.setAdmin('alice',
          isAdmin: false, actorId: 'alice', actorName: 'Alice');

      expect(noticeOf(), 'A group needs at least one admin.');
    });
  });
}
