import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/notification/domain/notification_routing.dart';

void main() {
  test('group notifications open the group', () {
    expect(routeForNotification(type: 'expense_added', groupId: 'g1'), '/group/g1');
    expect(routeForNotification(type: 'nudge', groupId: 'g9'), '/group/g9');
    expect(routeForNotification(type: 'settlement', groupId: 'g2'), '/group/g2');
  });

  test('notifications without a group open the inbox', () {
    expect(routeForNotification(type: 'expense_added'), '/notifications');
    expect(routeForNotification(type: 'expense_added', groupId: ''), '/notifications');
    expect(routeForNotification(), '/notifications');
  });

  test('digest goes home; removed/deleted groups go to the inbox', () {
    expect(routeForNotification(type: 'digest'), '/');
    expect(routeForNotification(type: 'group_deleted', groupId: 'g1'), '/notifications');
    expect(routeForNotification(type: 'member_removed', groupId: 'g1'), '/notifications');
  });
}
