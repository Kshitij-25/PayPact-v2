import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paypact/core/constants/app_links.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';

/// Routes that don't need a signed-in user.
const Set<String> kPublicPaths = {
  '/splash',
  '/onboarding',
  '/sign-in',
  '/sign-up',
};

const _splash = '/splash';
const _signIn = '/sign-in';
const _home = '/';

/// Where the user was headed when we sent them to sign in (or to the splash
/// while auth was still resolving). Only invite links are remembered: they're
/// the one thing a signed-out visitor arrives with on purpose. Remembering
/// ordinary pages would, after an explicit sign-out from /profile, drop the
/// *next* person who signs in on that page. Consumed once authenticated.
class PendingLink {
  PendingLink._();
  static String? _location;
  static String? _resume;

  /// Remembers an invite link to open after sign-in (other locations ignored).
  static void set(String location) {
    if (AppLinks.inviteCodeFrom(Uri.parse(location)) != null) {
      _location = location;
    }
  }

  /// Remembers *any* location hit while auth was still resolving (a web
  /// reload on /group/x), to restore if it resolves to signed-in. Dropped if
  /// the user turns out to be signed out.
  static void setResume(String location) => _resume = location;
  static void _clearResume() => _resume = null;

  static String? peek() => _location ?? _resume;

  static String? take() {
    final l = _location ?? _resume;
    _location = null;
    _resume = null;
    return l;
  }

  @visibleForTesting
  static void reset() {
    _location = null;
    _resume = null;
  }
}

/// Decides whether [uri] may be shown for [auth]; returns the location to
/// redirect to, or null to allow it.
///
/// * signed in: keep out of the auth screens (go where they were headed, or home)
/// * signed out: protected pages bounce to sign-in, remembering the target
/// * not resolved yet (cold start): protected pages wait on the splash
String? authRedirect(AuthState auth, Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  final isPublic = kPublicPaths.contains(path);

  if (auth is AuthAuthenticated) {
    if (path == _signIn || path == '/sign-up' || path == '/onboarding') {
      return PendingLink.take() ?? _home;
    }
    return null;
  }

  if (auth is AuthUnauthenticated) {
    PendingLink._clearResume();
    if (isPublic) return null;
    PendingLink.set(uri.toString());
    return _signIn;
  }

  // Initial / loading / error: auth state unknown.
  if (!isPublic) {
    PendingLink.set(uri.toString());
    PendingLink.setResume(uri.toString());
    return _splash;
  }
  return null;
}

/// Maps a location go_router couldn't match onto something useful. Custom
/// scheme links (`paypact://invite/CODE`) can arrive here depending on how the
/// platform hands over the URL.
String routeForUnmatched(Uri uri) {
  final code = AppLinks.inviteCodeFrom(uri);
  if (code != null) return '/join/$code';

  // Some platforms drop the scheme+host and leave just `/CODE`. Our codes are
  // exactly 8 characters, which keeps this from swallowing ordinary typos.
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segs.length == 1 && RegExp(r'^[A-Za-z0-9]{8}$').hasMatch(segs.first)) {
    return '/join/${segs.first.toUpperCase()}';
  }
  return _home;
}

/// Re-runs the router's redirect whenever the auth cubit emits.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
