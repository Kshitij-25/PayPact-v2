import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';

import 'test_helpers.dart';

class _GroupRepo extends Mock implements GroupRepository {}

class _ExpenseRepo extends Mock implements ExpenseRepository {}

class _Rates extends Mock implements ExchangeRateService {}

void main() {
  late _GroupRepo groups;
  late _ExpenseRepo expenses;
  late _Rates rates;

  setUp(() {
    groups = _GroupRepo();
    expenses = _ExpenseRepo();
    rates = _Rates();
    when(() => expenses.getGroupSettlements(any())).thenAnswer((_) async => []);
  });

  /// alice is owed 100 in an INR group and 10 in a USD group.
  void arrange() {
    final inr = makeGroup(id: 'inr', currency: 'INR');
    final usd = makeGroup(id: 'usd', currency: 'USD');
    when(() => groups.watchUserGroups('alice'))
        .thenAnswer((_) => Stream.value([inr, usd]));
    when(() => expenses.getGroupExpenses('inr')).thenAnswer((_) async => [
          makeExpense(
              payer: 'alice', total: 200, among: ['alice', 'bob'],
              groupId: 'inr', at: DateTime.now())
        ]);
    when(() => expenses.getGroupExpenses('usd')).thenAnswer((_) async => [
          makeExpense(
              payer: 'alice', total: 20, among: ['alice', 'bob'],
              groupId: 'usd', title: 'Coffee', at: DateTime.now())
        ]);
  }

  Future<GroupsLoaded> load(GroupsCubit cubit) async {
    cubit.loadGroups();
    return await cubit.stream.firstWhere((s) => s is GroupsLoaded)
        as GroupsLoaded;
  }

  test('cross-group totals are converted into the default currency', () async {
    arrange();
    when(() => rates.getRate('USD', 'INR')).thenAnswer((_) async => 80);
    final cubit = GroupsCubit(groups, expenses, 'alice',
        rates: rates, defaultCurrency: () => 'INR');

    final loaded = await load(cubit);

    // 100 INR + 10 USD × 80 = 900
    expect(loaded.totalNetBalance, closeTo(900, 0.001));
    // each group keeps its own currency
    final byId = {for (final g in loaded.groups) g.id: g};
    expect(byId['inr']!.netBalance, closeTo(100, 0.001));
    expect(byId['usd']!.netBalance, closeTo(10, 0.001));
    // the weekly delta uses the same conversion
    expect(loaded.weeklyDelta, closeTo(900, 0.001));
    await cubit.close();
  });

  test('the target follows the user setting', () async {
    arrange();
    when(() => rates.getRate('INR', 'USD')).thenAnswer((_) async => 0.0125);
    final cubit = GroupsCubit(groups, expenses, 'alice',
        rates: rates, defaultCurrency: () => 'USD');

    final loaded = await load(cubit);

    expect(loaded.totalNetBalance, closeTo(100 * 0.0125 + 10, 0.001));
    verifyNever(() => rates.getRate('USD', any()));
    await cubit.close();
  });

  test('an unavailable rate degrades gracefully instead of failing', () async {
    arrange();
    when(() => rates.getRate(any(), any())).thenThrow(Exception('offline'));
    final cubit = GroupsCubit(groups, expenses, 'alice',
        rates: rates, defaultCurrency: () => 'INR');

    final loaded = await load(cubit);

    expect(loaded.totalNetBalance, closeTo(110, 0.001)); // 1:1 fallback
    await cubit.close();
  });
}
