import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/group/presentation/cubit/group_detail_cubit.dart';
import 'package:paypact/features/group/presentation/widgets/group_tab_views.dart';

import 'test_helpers.dart';

void main() {
  test('merges expenses and settlements newest-first', () {
    final loaded = GroupDetailLoaded(
      group: makeGroup(),
      expenses: [
        makeExpense(
            payer: 'alice', total: 100, among: ['alice', 'bob'],
            title: 'Old dinner', at: DateTime(2026, 1, 1)),
        makeExpense(
            payer: 'bob', total: 60, among: ['alice', 'bob'],
            title: 'Taxi', at: DateTime(2026, 1, 5)),
      ],
      netBalance: 0,
      memberBalances: const {},
      globalMemberBalances: const {},
      settlements: [
        {
          'fromUserName': 'Bob',
          'toUserName': 'Alice',
          'amountPaise': 5000,
          'createdAt': DateTime(2026, 1, 3),
        },
      ],
    );

    final items = buildGroupActivity(loaded);

    expect(items.map((i) => i.title), ['Taxi', 'Bob paid Alice', 'Old dinner']);
    expect(items[1].isSettlement, isTrue);
    expect(items[1].amount, 50); // paise → rupees
    expect(items[0].subtitle, 'Bob paid');
  });

  test('legacy settlements (only `amount`) and missing dates still render', () {
    final loaded = GroupDetailLoaded(
      group: makeGroup(),
      expenses: const [],
      netBalance: 0,
      memberBalances: const {},
      globalMemberBalances: const {},
      settlements: [
        {'fromUserName': 'Bob', 'toUserName': 'Alice', 'amount': 12.5},
      ],
    );

    final items = buildGroupActivity(loaded);

    expect(items, hasLength(1));
    expect(items.single.amount, 12.5);
  });
}
