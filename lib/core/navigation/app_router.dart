import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:paypact/features/expense/presentation/screens/add_expense_screen.dart';
import 'package:paypact/features/expense/presentation/screens/expense_details_screen.dart';
import 'package:paypact/features/group/presentation/screens/create_group_screen.dart';
import 'package:paypact/features/group/presentation/screens/group_details_screen.dart';
import 'package:paypact/features/group/presentation/screens/group_settings_screen.dart';
import 'package:paypact/features/group/presentation/screens/invite_join_screen.dart';
import 'package:paypact/features/group/presentation/screens/qr_scanner_screen.dart';
import 'package:paypact/features/home/presentation/screens/home_screen.dart';
import 'package:paypact/features/profile/presentation/screens/profile_screen.dart';
import 'package:paypact/features/splash/splash_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const home = '/';
  static const invite = '/invite/:code';
  static const join = '/join/:code';
  static const groupDetail = '/group/:groupId';
  static const createGroup = '/group/create';
  static const addExpense = '/group/:groupId/expense/add';
  static const editExpense = '/group/:groupId/expense/:expenseId/edit';
  static const qrScanner = '/scan';
  static const groupSettings = '/group/:groupId/settings';

  static const profile = '/profile';
}

class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) {
      final authStatus = _authBloc.state.status;
      final location = state.matchedLocation;

      // ── Still waiting for Firebase to resolve the session ──────────────────
      // Hold on /splash and don't redirect anywhere until we know.
      if (authStatus == AuthStatus.initial) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuth = authStatus == AuthStatus.authenticated;
      final isSplash = location == AppRoutes.splash;
      final isSignIn = location == AppRoutes.signIn;

      // Authenticated: leave splash/sign-in → home
      if (isAuth && (isSplash || isSignIn)) return AppRoutes.home;

      // Unauthenticated: leave splash/protected routes → sign-in
      // (invite/join routes are intentionally reachable while signed out —
      //  InviteJoinScreen handles the "not signed in" case itself)
      if (!isAuth &&
          (isSplash ||
              (!isSignIn &&
                  !location.startsWith('/invite') &&
                  !location.startsWith('/join')))) {
        return AppRoutes.signIn;
      }

      return null;
    },
    // GoRouter also receives the raw platform URI (paypact://invite/CODE).
    // It can't match that scheme as a route, so we redirect all unknown
    // paths to home instead of showing an error page.
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.qrScanner,
        builder: (_, __) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/invite/:code',
        builder: (_, state) => InviteJoinScreen(
          inviteCode: state.pathParameters['code']!,
        ),
      ),
      GoRoute(
        // /join/:code is the web-app entry point linked from the landing page.
        // It hits Flutter directly (the Firebase /invite/** rewrite does NOT
        // match /join/**), so the Flutter web app handles auth + join flow.
        path: '/join/:code',
        builder: (_, state) => InviteJoinScreen(
          inviteCode: state.pathParameters['code']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'group/create',
            builder: (_, __) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: 'group/:groupId',
            builder: (_, state) => GroupDetailScreen(
              groupId: state.pathParameters['groupId']!,
            ),
            routes: [
              GoRoute(
                path: 'expense/add',
                builder: (_, state) => AddExpenseScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
              ),
              GoRoute(
                path: 'expense/:expenseId/edit',
                builder: (_, state) => AddExpenseScreen(
                  groupId: state.pathParameters['groupId']!,
                  expenseId: state.pathParameters['expenseId'],
                ),
              ),
              GoRoute(
                path: 'settings',
                builder: (_, state) => GroupSettingsScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'expense/:expenseId',
            builder: (_, state) => ExpenseDetailScreen(
              expenseId: state.pathParameters['expenseId']!,
            ),
          ),
          GoRoute(
            path: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    (_sub as dynamic).cancel();
    super.dispose();
  }
}
