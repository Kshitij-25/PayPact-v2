import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/expense/presentation/cubit/add_expense_cubit.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

class _MockExpenseRepo extends Mock implements ExpenseRepository {}

class _MockNotifRepo extends Mock implements NotificationsRepository {}

class _MockRates extends Mock implements ExchangeRateService {}

class _FakeRecurring extends Fake implements RecurringExpense {}

ExpenseEntity _existing({String originalCurrency = 'USD', double rate = 80}) =>
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

const _even = [
  ExpenseSplitEntity(userId: 'a', userName: 'Asha', amount: 60),
  ExpenseSplitEntity(userId: 'b', userName: 'Ben', amount: 60),
];

void main() {
  late _MockExpenseRepo repo;
  late _MockNotifRepo notifs;
  late _MockRates rates;
  late AddExpenseCubit cubit;

  setUpAll(() => registerFallbackValue(_FakeRecurring()));

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
          date: any(named: 'date'),
          note: any(named: 'note'),
          receiptUrl: any(named: 'receiptUrl'),
        )).thenAnswer((_) async {});
    when(() => repo.createExpense(
          groupId: any(named: 'groupId'),
          title: any(named: 'title'),
          amount: any(named: 'amount'),
          originalAmount: any(named: 'originalAmount'),
          originalCurrency: any(named: 'originalCurrency'),
          exchangeRate: any(named: 'exchangeRate'),
          category: any(named: 'category'),
          paidById: any(named: 'paidById'),
          paidByName: any(named: 'paidByName'),
          splits: any(named: 'splits'),
          createdById: any(named: 'createdById'),
          date: any(named: 'date'),
          note: any(named: 'note'),
          receiptUrl: any(named: 'receiptUrl'),
        )).thenAnswer((_) async => _existing());
    when(() => repo.addHistory(any(), any(),
            by: any(named: 'by'),
            byName: any(named: 'byName'),
            changes: any(named: 'changes')))
        .thenAnswer((_) async {});
    when(() => repo.createRecurring(any())).thenAnswer((_) async {});
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
    String? note,
    DateTime? date,
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
        splits: splits ?? _even,
        currentUserId: 'a',
        currentUserName: 'Asha',
        note: note,
        date: date,
      );

  List captured() => verify(() => repo.updateExpense(
        groupId: 'g1',
        expenseId: 'e1',
        title: any(named: 'title'),
        amount: captureAny(named: 'amount'),
        originalAmount: any(named: 'originalAmount'),
        originalCurrency: any(named: 'originalCurrency'),
        exchangeRate: captureAny(named: 'exchangeRate'),
        category: any(named: 'category'),
        paidById: any(named: 'paidById'),
        paidByName: any(named: 'paidByName'),
        splits: captureAny(named: 'splits'),
        date: any(named: 'date'),
        note: captureAny(named: 'note'),
        receiptUrl: any(named: 'receiptUrl'),
      )).captured;

  group('editing', () {
    test('keeps the recorded exchange rate when the currency is unchanged',
        () async {
      await update(_existing());
      verifyNever(() => rates.getRate(any(), any()));
      final c = captured();
      expect(c[0], 9600); // 120 × 80
      expect(c[1], 80);
      expect((c[2] as List<ExpenseSplitEntity>).map((s) => s.amount),
          [4800, 4800]);
      expect(cubit.state, isA<AddExpenseSuccess>());
    });

    test('fetches a fresh rate when the currency changes', () async {
      when(() => rates.getRate('EUR', 'INR')).thenAnswer((_) async => 90);
      await update(_existing(), currency: 'EUR');
      verify(() => rates.getRate('EUR', 'INR')).called(1);
      final c = captured();
      expect(c[0], 10800);
      expect(c[1], 90);
    });

    test('converted shares add up to the converted total exactly', () async {
      // ₹ rate with awkward decimals: 3 equal USD shares of 33.33… at 83.17.
      when(() => rates.getRate('USD', 'INR')).thenAnswer((_) async => 83.17);
      await update(
        _existing(originalCurrency: 'EUR'),
        currency: 'USD',
        amount: 100,
        splits: const [
          ExpenseSplitEntity(userId: 'a', userName: 'A', amount: 33.34),
          ExpenseSplitEntity(userId: 'b', userName: 'B', amount: 33.33),
          ExpenseSplitEntity(userId: 'c', userName: 'C', amount: 33.33),
        ],
      );
      final c = captured();
      final total = c[0] as double;
      final splitMinor = (c[2] as List<ExpenseSplitEntity>)
          .fold<int>(0, (s, e) => s + (e.amount * 100).round());
      expect(splitMinor, (total * 100).round());
      expect(total, 8317);
    });

    test('notifies everyone affected except the editor', () async {
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

    test('records what changed in the edit history, with the editor', () async {
      await update(_existing(), amount: 150);
      final c = verify(() => repo.addHistory('g1', 'e1',
          by: 'a',
          byName: 'Asha',
          changes: captureAny(named: 'changes'))).captured.single as List;
      expect(c, contains(startsWith('Title: "Dinner" → "Dinner out"')));
      expect(c, contains('Amount: \$100 → \$150'));
    });

    test('an edit that changes nothing writes no history entry', () async {
      final e = _existing();
      await update(e,
          title: e.title,
          amount: e.originalAmount,
          splits: const [
            ExpenseSplitEntity(userId: 'a', userName: 'Asha', amount: 50),
            ExpenseSplitEntity(userId: 'b', userName: 'Ben', amount: 50),
          ]);
      verifyNever(() => repo.addHistory(any(), any(),
          by: any(named: 'by'),
          byName: any(named: 'byName'),
          changes: any(named: 'changes')));
    });

    test('a blank note is stored as no note', () async {
      await update(_existing(), note: '   ');
      expect(captured()[3], isNull);
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
            date: any(named: 'date'),
            note: any(named: 'note'),
            receiptUrl: any(named: 'receiptUrl'),
          ));
    });
  });

  group('creating', () {
    Future<void> create({RecurrenceInterval? repeat, DateTime? date}) =>
        cubit.saveExpense(
          groupId: 'g1',
          groupCurrency: 'INR',
          title: 'Rent',
          amount: 100,
          originalCurrency: 'INR',
          category: 'stay',
          paidById: 'a',
          paidByName: 'Asha',
          splits: const [
            ExpenseSplitEntity(userId: 'a', userName: 'Asha', amount: 33.34),
            ExpenseSplitEntity(userId: 'b', userName: 'Ben', amount: 33.33),
            ExpenseSplitEntity(userId: 'c', userName: 'Cy', amount: 33.33),
          ],
          currentUserId: 'a',
          date: date,
          repeat: repeat,
        );

    test('shares sum exactly to the total and the chosen date is stored',
        () async {
      await create(date: DateTime(2026, 3, 5));
      final c = verify(() => repo.createExpense(
            groupId: 'g1',
            title: 'Rent',
            amount: captureAny(named: 'amount'),
            originalAmount: any(named: 'originalAmount'),
            originalCurrency: any(named: 'originalCurrency'),
            exchangeRate: any(named: 'exchangeRate'),
            category: any(named: 'category'),
            paidById: any(named: 'paidById'),
            paidByName: any(named: 'paidByName'),
            splits: captureAny(named: 'splits'),
            createdById: 'a',
            date: captureAny(named: 'date'),
            note: any(named: 'note'),
            receiptUrl: any(named: 'receiptUrl'),
          )).captured;
      final minor = (c[1] as List<ExpenseSplitEntity>)
          .fold<int>(0, (s, e) => s + (e.amount * 100).round());
      expect(minor, 10000);
      expect(c[2], DateTime(2026, 3, 5));
      verifyNever(() => repo.createRecurring(any()));
    });

    test('"repeat" also saves a template that starts one interval later',
        () async {
      await create(
          repeat: RecurrenceInterval.monthly, date: DateTime(2026, 1, 31));
      final t = verify(() => repo.createRecurring(captureAny()))
          .captured
          .single as RecurringExpense;
      expect(t.interval, RecurrenceInterval.monthly);
      expect(t.nextRunAt, DateTime(2026, 2, 28)); // clamped to month end
      expect(t.title, 'Rent');
      expect(t.splits.length, 3);
      expect(t.active, isTrue);
    });
  });
}
