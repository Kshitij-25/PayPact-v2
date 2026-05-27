import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/design_system/tokens/motion.dart';
import 'package:paypact/features/activity/activity_screen.dart';
import 'package:paypact/features/auth/presentation/screens/create_account_screen.dart';
import 'package:paypact/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:paypact/features/expense/presentation/screens/add_expense_screen.dart';
import 'package:paypact/features/expense/presentation/screens/expense_detail_screen.dart';
import 'package:paypact/features/group/presentation/screens/add_members_screen.dart';
import 'package:paypact/features/group/presentation/screens/create_group_screen.dart';
import 'package:paypact/features/group/presentation/screens/group_detail_screen.dart';
import 'package:paypact/features/group/presentation/screens/groups_screen.dart';
import 'package:paypact/features/home/presentation/screens/home_screen.dart';
import 'package:paypact/features/notification/presentation/screens/notifications_screen.dart';
import 'package:paypact/features/onboarding/onboarding_screen.dart';
import 'package:paypact/features/profile/presentation/screens/profile_screen.dart';
import 'package:paypact/features/group/presentation/screens/group_settings_screen.dart';
import 'package:paypact/features/profile/presentation/screens/settings_screen.dart';
import 'package:paypact/features/settle/settle_success_screen.dart';
import 'package:paypact/features/settle/settle_up_screen.dart';
import 'package:paypact/features/splash/splash_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const home = '/';
  static const groups = '/groups';
  static const activity = '/activity';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const profileSettings = '/settings';
  static const groupDetail = '/group/:groupId';
  static const createGroup = '/group/create';
  static const addExpense = '/group/:groupId/expense/add';
  static const editExpense = '/group/:groupId/expense/:expenseId/edit';
  static const groupSettings = '/group/:groupId/settings';
  static const settleUp = '/group/:groupId/settle';
  static const signUp = '/sign-up';
  static const addMembers = '/group/add-members';
}

// ── Transition helpers ────────────────────────────────────────────────────────

CustomTransitionPage<void> _fade({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 350),
}) =>
    CustomTransitionPage(
      key: key,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );

CustomTransitionPage<void> _slideRight({
  required LocalKey key,
  required Widget child,
  Duration forward = const Duration(milliseconds: 300),
  Duration reverse = const Duration(milliseconds: 250),
}) =>
    CustomTransitionPage(
      key: key,
      transitionDuration: forward,
      reverseTransitionDuration: reverse,
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: PayPactMotion.easeOut)),
        ),
        child: child,
      ),
      child: child,
    );

CustomTransitionPage<void> _slideUpModal({
  required LocalKey key,
  required Widget child,
  Duration forward = const Duration(milliseconds: 300),
  Duration reverse = const Duration(milliseconds: 250),
}) =>
    CustomTransitionPage(
      key: key,
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: forward,
      reverseTransitionDuration: reverse,
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: animation.drive(
          Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: PayPactMotion.easeOut)),
        ),
        child: child,
      ),
      child: child,
    );

// ── Router ────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _fade(
        key: state.pageKey,
        child: const SplashScreen(),
        duration: const Duration(milliseconds: 400),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => _fade(
        key: state.pageKey,
        child: OnboardingScreen(onFinish: () => context.go(AppRoutes.signIn)),
        duration: const Duration(milliseconds: 400),
      ),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      pageBuilder: (context, state) => _fade(
        key: state.pageKey,
        child: const SignInScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      pageBuilder: (context, state) => _slideRight(
        key: state.pageKey,
        child: const CreateAccountScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.addMembers,
      pageBuilder: (context, state) => _slideRight(
        key: state.pageKey,
        child: AddMembersScreen(
          groupId:
              (state.extra as Map<String, dynamic>?)?['groupId'] as String?,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.groups,
      pageBuilder: (context, state) => _fade(
        key: state.pageKey,
        child: const GroupsScreen(),
        duration: PayPactMotion.fast,
      ),
    ),
    GoRoute(
      path: AppRoutes.activity,
      pageBuilder: (context, state) => _fade(
        key: state.pageKey,
        child: const ActivityScreen(),
        duration: PayPactMotion.fast,
      ),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        transitionDuration: PayPactMotion.mid,
        reverseTransitionDuration: PayPactMotion.mid,
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: animation.drive(
            Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                .chain(CurveTween(curve: PayPactMotion.easeOut)),
          ),
          child: child,
        ),
        child: const NotificationsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.profileSettings,
      pageBuilder: (context, state) => _slideRight(
        key: state.pageKey,
        child: const SettingsScreen(),
        forward: PayPactMotion.mid,
        reverse: PayPactMotion.mid,
      ),
    ),
    GoRoute(
      path: AppRoutes.profile,
      pageBuilder: (context, state) => _fade(
        key: state.pageKey,
        child: const ProfileScreen(),
        duration: PayPactMotion.fast,
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => _fade(
        key: state.pageKey,
        child: const HomeScreen(),
      ),
      routes: [
        // group/create must be before group/:groupId to avoid param conflict
        GoRoute(
          path: 'group/create',
          pageBuilder: (context, state) => _slideUpModal(
            key: state.pageKey,
            child: const CreateGroupScreen(),
          ),
        ),
        GoRoute(
          path: 'group/:groupId',
          pageBuilder: (context, state) => _slideRight(
            key: state.pageKey,
            child: GroupDetailScreen(
              groupId: state.pathParameters['groupId']!,
            ),
          ),
          routes: [
            GoRoute(
              path: 'expense/add',
              pageBuilder: (context, state) => _slideUpModal(
                key: state.pageKey,
                child: AddExpenseScreen(
                  groupId: state.pathParameters['groupId'],
                ),
                forward: const Duration(milliseconds: 250),
                reverse: const Duration(milliseconds: 200),
              ),
            ),
            GoRoute(
              path: 'expense/:expenseId/edit',
              pageBuilder: (context, state) => _slideUpModal(
                key: state.pageKey,
                child: AddExpenseScreen(
                  groupId: state.pathParameters['groupId'],
                ),
                forward: const Duration(milliseconds: 250),
                reverse: const Duration(milliseconds: 200),
              ),
            ),
            GoRoute(
              path: 'settle',
              pageBuilder: (context, state) => _slideUpModal(
                key: state.pageKey,
                child: SettleUpScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
              ),
            ),
            GoRoute(
              path: 'settle-success',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                transitionDuration: const Duration(milliseconds: 350),
                reverseTransitionDuration: const Duration(milliseconds: 250),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: PayPactMotion.easeOut,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: SettleSuccessScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
              ),
            ),
            GoRoute(
              path: 'settings',
              pageBuilder: (context, state) => _slideRight(
                key: state.pageKey,
                child: GroupSettingsScreen(
                  groupId: state.pathParameters['groupId']!,
                ),
                forward: PayPactMotion.mid,
                reverse: PayPactMotion.mid,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'expense/:expenseId',
          pageBuilder: (context, state) => _slideRight(
            key: state.pageKey,
            child: ExpenseDetailScreen(
              expenseId: state.pathParameters['expenseId']!,
              groupId:
                  (state.extra as Map<String, dynamic>?)?['groupId'] as String?,
            ),
            forward: const Duration(milliseconds: 280),
            reverse: const Duration(milliseconds: 230),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);
