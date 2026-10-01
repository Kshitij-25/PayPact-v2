import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/services/nudge_service.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NotifRepo extends Mock implements NotificationsRepository {}

const _nudge = SmartNudgeData(
  memberName: 'Ben Carter',
  groupName: 'Goa trip',
  groupId: 'g1',
  fromUserId: 'ben',
  amountOwed: 1250,
  daysSilent: 6,
  currency: 'INR',
);

void main() {
  late _NotifRepo notifs;
  late SharedPreferences prefs;
  late DateTime now;
  late NudgeService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notifs = _NotifRepo();
    now = DateTime(2026, 10, 1, 12);
    service = NudgeService(notifs, prefs, now: () => now);
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

  test('delivers a nudge notification to the person who owes', () async {
    await service.send(nudge: _nudge, actorId: 'asha', actorName: 'Asha Rao');

    verify(() => notifs.push(
          targetUserId: 'ben',
          type: 'nudge',
          title: 'Asha sent a gentle reminder',
          body: 'You still owe ₹1250 in "Goa trip".',
          groupId: 'g1',
          groupName: 'Goa trip',
          actorId: 'asha',
          actorName: 'Asha Rao',
        )).called(1);
  });

  test('the same person is not offered again until the cooldown passes',
      () async {
    expect(service.canNudge('asha', _nudge), isTrue);
    await service.send(nudge: _nudge, actorId: 'asha', actorName: 'Asha');
    expect(service.canNudge('asha', _nudge), isFalse);

    now = now.add(const Duration(days: 2, hours: 23));
    expect(service.canNudge('asha', _nudge), isFalse);

    now = now.add(const Duration(hours: 2));
    expect(service.canNudge('asha', _nudge), isTrue);
  });

  test('cooldown is per person, per group and per sender', () async {
    await service.send(nudge: _nudge, actorId: 'asha', actorName: 'Asha');

    const otherGroup = SmartNudgeData(
        memberName: 'Ben', groupName: 'Flat', groupId: 'g2',
        fromUserId: 'ben', amountOwed: 20, daysSilent: 9, currency: 'INR');
    expect(service.canNudge('asha', otherGroup), isTrue);
    expect(service.canNudge('cy', _nudge), isTrue);
  });

  test('a failed send does not start the cooldown', () async {
    when(() => notifs.push(
          targetUserId: any(named: 'targetUserId'),
          type: any(named: 'type'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          groupId: any(named: 'groupId'),
          groupName: any(named: 'groupName'),
          actorId: any(named: 'actorId'),
          actorName: any(named: 'actorName'),
        )).thenThrow(Exception('offline'));

    await expectLater(
        service.send(nudge: _nudge, actorId: 'asha', actorName: 'Asha'),
        throwsException);
    expect(service.canNudge('asha', _nudge), isTrue);
  });
}
