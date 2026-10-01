import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/services/inbox_watcher.dart';
import 'package:paypact/features/notification/domain/digest.dart';
import 'package:paypact/features/notification/domain/entities/notification_entity.dart';
import 'package:paypact/features/notification/domain/inbox_delivery.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Mock implements NotificationsRepository {}

final _now = DateTime(2026, 10, 1, 12);

NotificationEntity _n(String id,
        {bool read = false, Duration age = const Duration(minutes: 1)}) =>
    NotificationEntity(
      id: id,
      type: 'expense_added',
      title: 'T $id',
      body: 'B $id',
      groupId: 'g1',
      actorId: 'bob',
      actorName: 'Bob',
      isRead: read,
      createdAt: _now.subtract(age),
    );

void main() {
  group('digest wording', () {
    test('nothing to say', () {
      expect(buildDigest(expenseCount: 0, groupCount: 2, net: {'INR': 50}), isNull);
    });

    test('expenses, owed and owing', () {
      final d = buildDigest(
          expenseCount: 3, groupCount: 2, net: {'INR': 120000, 'USD': -2550})!;
      expect(d.title, 'Your weekly PayPact digest');
      expect(d.body,
          "3 new expenses across 2 groups · you're owed ₹1200 · you owe \$25.50.");
    });

    test('singular wording', () {
      expect(buildDigest(expenseCount: 1, groupCount: 1, net: {})!.body,
          '1 new expense across 1 group.');
    });

    test('formatMoney', () {
      expect(formatMoney(-12345, 'EUR'), '€123.45');
      expect(formatMoney(5000, 'XYZ'), 'XYZ 50');
    });
  });

  group('which inbox entries pop up', () {
    test('unread, fresh and not yet shown', () {
      final picked = pickToShow(
        inbox: [
          _n('fresh'),
          _n('read', read: true),
          _n('shown'),
          _n('old', age: const Duration(days: 3)),
        ],
        alreadyShown: {'shown'},
        now: _now,
      );
      expect(picked.map((n) => n.id), ['fresh']);
    });

    test('oldest first', () {
      final picked = pickToShow(
        inbox: [
          _n('new', age: const Duration(minutes: 1)),
          _n('older', age: const Duration(hours: 2)),
        ],
        alreadyShown: {},
        now: _now,
      );
      expect(picked.map((n) => n.id), ['older', 'new']);
    });
  });

  group('InboxWatcher', () {
    late SharedPreferences prefs;
    late List<Map<String, dynamic>> shown;
    late InboxWatcher watcher;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      shown = [];
      watcher = InboxWatcher(_Repo(), prefs, now: () => _now,
          show: ({required title, required body, required id, required data}) async {
        shown.add({'title': title, 'body': body, 'id': id, ...data});
      });
    });

    test('shows each new entry once, with its destination', () async {
      expect(await watcher.process('me', [_n('a')]), 1);
      expect(shown.single['title'], 'T a');
      expect(shown.single['groupId'], 'g1');
      expect(shown.single['type'], 'expense_added');

      // the same snapshot again (or a later one still containing it): silent
      expect(await watcher.process('me', [_n('a')]), 0);
      expect(await watcher.process('me', [_n('b'), _n('a')]), 1);
      expect(shown.map((s) => s['title']), ['T a', 'T b']);
    });

    test('remembers across restarts (stored per user)', () async {
      await watcher.process('me', [_n('a')]);
      final again = InboxWatcher(_Repo(), prefs, now: () => _now,
          show: ({required title, required body, required id, required data}) async {
        shown.add({'title': title});
      });
      expect(await again.process('me', [_n('a')]), 0);
      expect(await again.process('someone-else', [_n('a')]), 1);
    });

    test('a burst collapses into one summary', () async {
      await watcher.process('me', [for (var i = 0; i < 5; i++) _n('n$i')]);
      expect(shown, hasLength(1));
      expect(shown.single['body'], '5 new updates');
    });

    test('read and stale entries stay quiet', () async {
      await watcher.process('me',
          [_n('r', read: true), _n('s', age: const Duration(days: 9))]);
      expect(shown, isEmpty);
    });
  });
}
