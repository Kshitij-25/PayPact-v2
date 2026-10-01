import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/core/services/background_inbox.dart';

void main() {
  final now = DateTime(2026, 10, 1, 12);

  test('first check looks back a day', () {
    expect(BackgroundInbox.sinceFor(null, now), DateTime(2026, 9, 30, 12));
  });

  test('later checks resume just before the last one', () {
    final last = now.subtract(const Duration(minutes: 20));
    expect(BackgroundInbox.sinceFor(last.millisecondsSinceEpoch, now),
        last.subtract(const Duration(minutes: 2)));
  });

  test('a long gap never reaches back further than a day', () {
    final last = now.subtract(const Duration(days: 10));
    expect(BackgroundInbox.sinceFor(last.millisecondsSinceEpoch, now),
        DateTime(2026, 9, 30, 12));
  });
}
