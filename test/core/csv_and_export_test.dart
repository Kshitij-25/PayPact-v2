import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/utils/csv.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/profile/domain/data_export.dart';

import '../features/group/test_helpers.dart';

class _Groups extends Mock implements GroupRepository {}

class _Expenses extends Mock implements ExpenseRepository {}

void main() {
  group('toCsv', () {
    test('joins fields and rows with CRLF', () {
      expect(toCsv([['a', 'b'], ['1', '2']]), 'a,b\r\n1,2\r\n');
    });

    test('quotes commas, quotes and newlines', () {
      expect(toCsv([['a,b', 'say "hi"', 'x\ny']]),
          '"a,b","say ""hi""","x\ny"\r\n');
    });

    test('nulls become empty and numbers stay numbers (negatives intact)', () {
      expect(toCsv([[null, 12.5, -3, 'ok']]), ',12.5,-3,ok\r\n');
    });

    test('formula-looking text is neutralised against CSV injection', () {
      expect(toCsv([['=HYPERLINK("http://x")', '+1', '-2 x', '@cmd', 'safe']]),
          '"\'=HYPERLINK(""http://x"")",\'+1,\'-2 x,\'@cmd,safe\r\n');
    });
  });

  group('DataExporter', () {
    test('includes the profile, members, every expense and settlement', () async {
      final groups = _Groups();
      final expenses = _Expenses();
      final g = makeGroup(members: ['alice', 'bob']);
      when(() => groups.watchUserGroups('alice'))
          .thenAnswer((_) => Stream.value([g]));
      when(() => expenses.getGroupExpenses('g1')).thenAnswer((_) async => [
            makeExpense(payer: 'alice', total: 90, among: ['alice', 'bob'])
          ]);
      when(() => expenses.getGroupSettlements('g1')).thenAnswer((_) async => [
            {
              'id': 's1',
              'fromUserId': 'bob',
              'fromUserName': 'Bob',
              'toUserId': 'alice',
              'toUserName': 'Alice',
              'amountPaise': 4500,
              'currency': 'INR',
              'createdAt': DateTime.utc(2026, 1, 3),
            }
          ]);

      final json = await DataExporter(groups, expenses).buildJson(
          userId: 'alice',
          name: 'Alice',
          email: 'a@x.com',
          now: DateTime.utc(2026, 10, 1));
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['exportedAt'], '2026-10-01T00:00:00.000Z');
      expect(data['profile'], {'id': 'alice', 'name': 'Alice', 'email': 'a@x.com'});
      final grp = (data['groups'] as List).single as Map<String, dynamic>;
      expect(grp['name'], 'Trip');
      expect((grp['members'] as List).length, 2);
      expect(((grp['expenses'] as List).single as Map)['amount'], 90);
      final s = (grp['settlements'] as List).single as Map;
      expect(s['amount'], 45);
      expect(s['createdAt'], '2026-01-03T00:00:00.000Z');
    });

    test('a user in no groups still gets a valid export', () async {
      final groups = _Groups();
      when(() => groups.watchUserGroups('u')).thenAnswer((_) => Stream.value([]));
      final data = await DataExporter(groups, _Expenses())
          .build(userId: 'u', name: 'U', email: 'u@x.com');
      expect(data['groups'], isEmpty);
    });
  });
}
