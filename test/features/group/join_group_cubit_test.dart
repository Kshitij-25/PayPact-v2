import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/features/group/data/invite_service.dart';
import 'package:paypact/features/group/presentation/cubit/join_group_cubit.dart';

class _Service extends Mock implements InviteService {}

const _preview = InvitePreview(
    name: 'Trip', emoji: '🏖', memberCount: 3, alreadyMember: false);

void main() {
  late _Service service;
  late JoinGroupCubit cubit;

  setUp(() {
    service = _Service();
    cubit = JoinGroupCubit(service, 'ABCD2345');
  });
  tearDown(() => cubit.close());

  test('load shows the preview', () async {
    when(() => service.preview('ABCD2345')).thenAnswer((_) async => _preview);
    await cubit.load();
    expect(cubit.state, isA<JoinGroupReady>());
    expect((cubit.state as JoinGroupReady).preview.name, 'Trip');
  });

  test('load surfaces a bad/expired link as a message', () async {
    when(() => service.preview(any()))
        .thenThrow(const InviteException('This invite link is no longer valid.'));
    await cubit.load();
    expect((cubit.state as JoinGroupFailed).message,
        'This invite link is no longer valid.');
  });

  test('join goes Ready → Joining → Joined', () async {
    when(() => service.preview(any())).thenAnswer((_) async => _preview);
    when(() => service.join('ABCD2345')).thenAnswer((_) async =>
        const JoinResult(groupId: 'g1', name: 'Trip', alreadyMember: false));
    await cubit.load();

    final states = <JoinGroupState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.join();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states.map((s) => s.runtimeType),
        [JoinGroupJoining, JoinGroupJoined]);
    expect((cubit.state as JoinGroupJoined).result.groupId, 'g1');
  });

  test('join before the preview has loaded does nothing', () async {
    await cubit.join();
    expect(cubit.state, isA<JoinGroupLoading>());
    verifyNever(() => service.join(any()));
  });

  test('a failed join reports the reason', () async {
    when(() => service.preview(any())).thenAnswer((_) async => _preview);
    when(() => service.join(any()))
        .thenThrow(const InviteException('No connection. Check your internet and try again.'));
    await cubit.load();
    await cubit.join();
    expect((cubit.state as JoinGroupFailed).message, contains('No connection'));
  });
}
