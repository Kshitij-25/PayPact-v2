import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/expense/domain/expense_changes.dart';

void main() {
  test('nothing is due before the run date', () {
    final r = dueOccurrences(DateTime(2026, 11, 1), RecurrenceInterval.monthly,
        DateTime(2026, 10, 31));
    expect(r.due, isEmpty);
    expect(r.next, DateTime(2026, 11, 1));
  });

  test('a missed month is caught up, then moves forward', () {
    final r = dueOccurrences(DateTime(2026, 8, 1), RecurrenceInterval.monthly,
        DateTime(2026, 10, 2));
    expect(r.due, [DateTime(2026, 8, 1), DateTime(2026, 9, 1), DateTime(2026, 10, 1)]);
    expect(r.next, DateTime(2026, 11, 1));
  });

  test('weekly steps by seven days', () {
    final r = dueOccurrences(DateTime(2026, 10, 1), RecurrenceInterval.weekly,
        DateTime(2026, 10, 15));
    expect(r.due, hasLength(3));
    expect(r.next, DateTime(2026, 10, 22));
  });

  test('a long absence is capped instead of flooding the group', () {
    final r = dueOccurrences(DateTime(2020, 1, 1), RecurrenceInterval.monthly,
        DateTime(2026, 10, 2));
    expect(r.due, hasLength(kMaxRecurringCatchUp));
    expect(r.next.isAfter(DateTime(2026, 10, 2)), isTrue);
  });

  test('month ends are clamped (Jan 31 → Feb 28)', () {
    final r = dueOccurrences(DateTime(2026, 1, 31), RecurrenceInterval.monthly,
        DateTime(2026, 2, 28));
    expect(r.due, [DateTime(2026, 1, 31), DateTime(2026, 2, 28)]);
  });
}
