import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  late AuthCubit cubit;

  setUp(() {
    repo = _MockAuthRepo();
    cubit = AuthCubit(repo);
  });

  tearDown(() => cubit.close());

  test('returns null and trims the email on success', () async {
    when(() => repo.sendPasswordResetEmail(any())).thenAnswer((_) async {});

    final result = await cubit.sendPasswordReset('  a@b.com ');

    expect(result, isNull);
    verify(() => repo.sendPasswordResetEmail('a@b.com')).called(1);
  });

  test('does not emit auth states (sign-in form must not be disturbed)',
      () async {
    when(() => repo.sendPasswordResetEmail(any())).thenAnswer((_) async {});
    final states = <AuthState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.sendPasswordReset('a@b.com');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states, isEmpty);
  });

  test('maps Firebase errors to friendly messages', () async {
    Future<String?> failWith(String code) {
      when(() => repo.sendPasswordResetEmail(any()))
          .thenThrow(Exception('[firebase_auth/$code] boom'));
      return cubit.sendPasswordReset('a@b.com');
    }

    expect(await failWith('invalid-email'), 'Enter a valid email address.');
    expect(await failWith('too-many-requests'),
        'Too many attempts. Please try again later.');
    expect(await failWith('network-request-failed'), 'No internet connection.');
    expect(await failWith('something-else'),
        'Something went wrong. Please try again.');
  });
}
