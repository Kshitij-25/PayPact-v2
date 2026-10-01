import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/notification/domain/notification_prefs.dart';

void main() {
  group('notifCategoryFor', () {
    test('maps event types onto the four settings', () {
      expect(notifCategoryFor('expense_added'), 'expenses');
      expect(notifCategoryFor('expense_updated'), 'expenses');
      expect(notifCategoryFor('expense_deleted'), 'expenses');
      expect(notifCategoryFor('settlement'), 'settlements');
      expect(notifCategoryFor('nudge'), 'nudges');
      expect(notifCategoryFor('digest'), 'digest');
    });

    test('membership and group events are always delivered', () {
      for (final t in [
        'member_added',
        'member_removed',
        'group_updated',
        'group_deleted',
        'something_new',
      ]) {
        expect(notifCategoryFor(t), isNull, reason: t);
        expect(shouldDeliver(type: t, userData: {
          'notifPrefs': {'expenses': false, 'settlements': false}
        }), isTrue);
      }
    });
  });

  group('shouldDeliver', () {
    test('defaults: everything on except the weekly digest', () {
      expect(shouldDeliver(type: 'expense_added'), isTrue);
      expect(shouldDeliver(type: 'settlement', userData: {}), isTrue);
      expect(shouldDeliver(type: 'nudge', userData: null), isTrue);
      expect(shouldDeliver(type: 'digest'), isFalse);
    });

    test('respects an explicit opt-out and opt-in', () {
      final data = {
        'notifPrefs': {'expenses': false, 'digest': true}
      };
      expect(shouldDeliver(type: 'expense_added', userData: data), isFalse);
      expect(shouldDeliver(type: 'expense_deleted', userData: data), isFalse);
      expect(shouldDeliver(type: 'settlement', userData: data), isTrue);
      expect(shouldDeliver(type: 'digest', userData: data), isTrue);
    });

    test('ignores malformed preference values', () {
      expect(
          shouldDeliver(type: 'expense_added', userData: {
            'notifPrefs': {'expenses': 'no'}
          }),
          isTrue);
      expect(
          shouldDeliver(type: 'expense_added', userData: {'notifPrefs': 7}),
          isTrue);
    });

    test('a muted group silences categorised notifications only', () {
      final data = {
        'mutedGroups': ['g1']
      };
      expect(
          shouldDeliver(type: 'expense_added', groupId: 'g1', userData: data),
          isFalse);
      expect(shouldDeliver(type: 'nudge', groupId: 'g1', userData: data),
          isFalse);
      expect(
          shouldDeliver(type: 'expense_added', groupId: 'g2', userData: data),
          isTrue);
      expect(
          shouldDeliver(type: 'member_removed', groupId: 'g1', userData: data),
          isTrue);
    });
  });
}
