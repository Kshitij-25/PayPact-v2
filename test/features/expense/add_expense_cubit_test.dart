import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/expense/presentation/cubit/add_expense_cubit.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

class _MockExpenseRepo extends Mock implements ExpenseRepository {}

class _MockNotifRepo extends Mock implements NotificationsRepository {}

class _MockRates extends Mock implements ExchangeRateService {}

ExpenseEntity _existing({
  String originalCurrency = 'USD',
  double rate = 80,
}) =>
    ExpenseEntity(
      id: 'e1',
      groupId: 'g1',
      title: 'Dinner',
      amount: 8000,
      originalAmount: 100,
      originalCurrency: originalCurrency,
      exchangeRate: rate,
      category: 'food',
      paidById: 'a',
      paidByName: 'Asha',
      splits: const [
        ExpenseSplitEntity(userId: 'a', userName: 'Asha', amount: 4000),
        ExpenseSplitEntity(userId: 'b', userName: 'Ben', amount: 4000),
      ],
      createdAt: DateTime(2026, 1, 1),
      createdById: 'a',
    );

void main() {
  late _MockExpenseRepo repo;
  late _MockNotifRepo notifs;
  late _MockRates rates;
  late AddExpenseCubit cubit;

  setUp(() {
    repo = _MockExpenseRepo();
    notifs = _MockNotifRepo();
    rates = _MockRates();
    cubit = AddExpenseCubit(repo, notifs, rates);

    when(() => repo.updateExpense(
          groupId: any(named: 'groupId'),
          expenseId: any(named: 'expenseId'),
          title: any(named: 'title'),
          amount: any(named: 'amount'),
          originalAmount: any(named: 'originalAmount'),
          originalCurrency: any(named: 'originalCurrency'),
          exchangeRate: any(named: 'exchangeRate'),
          category: any(named: 'category'),
          paidById: any(named: 'paidById'),
          paidByName: any(named: 'paidByName'),
          splits: any(named: 'splits'),
        )).thenAnswer((_) async {});
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

  Future<void> update(
    ExpenseEntity existing, {
    String currency = 'USD',
    double amount = 120,
    String title = 'Dinner out',
    List<ExpenseSplitEntity>? splits,
  }) =>
      cubit.updateExpense(
        existing: existing,
        groupCurrency: 'INR',
        groupName: 'Trip',
        title: title,
        amount: amount,
        originalCurrency: currency,
        category: 'food',
        paidById: 'a',
        paidByName: 'Asha',
        splits: splits ??
            const [
              ExpenseSplitEntity(userId: 'a', userName: 'Asha', amount: 60),
              ExpenseSplitEntity(userId: 'b', userName: 'Ben', amount: 60),
            ],
        currentUserId: 'a',
        currentUserName: 'Asha',
      );

  test('keeps the recorded exchange rate when the currency is unchanged',
      () async {
    await update(_existing());

    verifyNever(() => rates.getRate(any(), any()));
    final captured = verify(() => repo.updateExpense(
          groupId: 'g1',
          expenseId: 'e1',
          title: 'Dinner out',
          amount: captureAny(named: 'amount'),
          originalAmount: 120,
          originalCurrency: 'USD',
          exchangeRate: 80,
          category: 'food',
          paidById: 'a',
          paidByName: 'Asha',
          splits: captureAny(named: 'splits'),
        )).captured;
    expect(captured[0], 9600);
    final splits = captured[1] as List<ExpenseSplitEntity>;
    expect(splits.map((s) => s.amount), [4800, 4800]);
    expect(cubit.state, isA<AddExpenseSuccess>());
  });

  test('fetches a fresh rate when the currency changes', () async {
    when(() => rates.getRate('EUR', 'INR')).thenAnswer((_) async => 90);

    await update(_existing(), currency: 'EUR');

    verify(() => rates.getRate('EUR', 'INR')).called(1);
    verify(() => repo.updateExpense(
          groupId: 'g1',
          expenseId: 'e1',
          title: any(named: 'title'),
          amount: 10800,
          originalAmount: 120,
          originalCurrency: 'EUR',
          exchangeRate: 90,
          category: any(named: 'category'),
          paidById: any(named: 'paidById'),
          paidByName: any(named: 'paidByName'),
          splits: any(named: 'splits'),
        )).called(1);
  });

  test('notifies everyone affected except the editor', () async {
    // Ben was in the old split; Cy is newly added; Asha is the editor.
    await update(_existing(), splits: const [
      ExpenseSplitEntity(userId: 'a', userName: 'Asha', amount: 60),
      ExpenseSplitEntity(userId: 'c', userName: 'Cy', amount: 60),
    ]);

    final targets = verify(() => notifs.push(
          targetUserId: captureAny(named: 'targetUserId'),
          type: 'expense_updated',
          title: any(named: 'title'),
          body: any(named: 'body'),
          groupId: 'g1',
          groupName: 'Trip',
          actorId: 'a',
          actorName: 'Asha',
        )).captured;
    expect(targets.toSet(), {'b', 'c'});
  });

  test('rejects an empty title or non-positive amount without writing',
      () async {
    await update(_existing(), title: '  ');
    expect(cubit.state, isA<AddExpenseError>());

    await update(_existing(), amount: 0);
    expect(cubit.state, isA<AddExpenseError>());

    verifyNever(() => repo.updateExpense(
          groupId: any(named: 'groupId'),
          expenseId: any(named: 'expenseId'),
          title: any(named: 'title'),
          amount: any(named: 'amount'),
          originalAmount: any(named: 'originalAmount'),
          originalCurrency: any(named: 'originalCurrency'),
          exchangeRate: any(named: 'exchangeRate'),
          category: any(named: 'category'),
          paidById: any(named: 'paidById'),
          paidByName: any(named: 'paidByName'),
          splits: any(named: 'splits'),
        ));
  });
}
