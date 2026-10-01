import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/core/navigation/auth_redirect.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';

final _signedIn = AuthAuthenticated(
    const UserEntity(id: 'u1', name: 'Asha', email: 'a@x.com'));
final _signedOut = AuthUnauthenticated();

String? redirect(AuthState s, String loc) => authRedirect(s, Uri.parse(loc));

void main() {
  setUp(PendingLink.reset);

  group('signed out', () {
    test('protected pages bounce to sign-in', () {
      expect(redirect(_signedOut, '/'), '/sign-in');
      expect(redirect(_signedOut, '/group/g1'), '/sign-in');
      expect(redirect(_signedOut, '/settings'), '/sign-in');
    });

    test('public pages are allowed', () {
      for (final p in ['/splash', '/onboarding', '/sign-in', '/sign-up']) {
        expect(redirect(_signedOut, p), isNull, reason: p);
      }
    });

    test('an invite link is remembered across sign-in', () {
      expect(redirect(_signedOut, '/join/ABCD2345'), '/sign-in');
      expect(PendingLink.peek(), '/join/ABCD2345');
      // ...and handed over once they're authenticated.
      expect(redirect(_signedIn, '/sign-in'), '/join/ABCD2345');
      expect(PendingLink.peek(), isNull);
    });

    test('ordinary pages are NOT remembered (no landing the next user on /profile)',
        () {
      redirect(_signedOut, '/profile');
      expect(PendingLink.peek(), isNull);
      expect(redirect(_signedIn, '/sign-in'), '/');
    });
  });

  group('signed in', () {
    test('app pages are allowed', () {
      expect(redirect(_signedIn, '/'), isNull);
      expect(redirect(_signedIn, '/group/g1/settings'), isNull);
      expect(redirect(_signedIn, '/splash'), isNull);
    });

    test('auth screens go home', () {
      expect(redirect(_signedIn, '/sign-in'), '/');
      expect(redirect(_signedIn, '/sign-up'), '/');
      expect(redirect(_signedIn, '/onboarding'), '/');
    });
  });

  group('auth not resolved yet (cold start)', () {
    test('protected pages wait on the splash and are resumed after', () {
      expect(redirect(AuthInitial(), '/group/g1'), '/splash');
      expect(PendingLink.take(), '/group/g1');
    });

    test('a web reload that turns out to be signed-out drops the resume target',
        () {
      redirect(AuthInitial(), '/group/g1');
      redirect(_signedOut, '/sign-in');
      expect(PendingLink.take(), isNull);
    });

    test('an invite link survives the splash even if signed out', () {
      redirect(AuthInitial(), '/join/ABCD2345');
      redirect(_signedOut, '/onboarding');
      expect(PendingLink.take(), '/join/ABCD2345');
    });

    test('public pages are not held up', () {
      expect(redirect(AuthInitial(), '/splash'), isNull);
      expect(redirect(AuthLoading(), '/sign-in'), isNull);
    });
  });
}
