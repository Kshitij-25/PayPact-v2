import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:paypact/presentation/screens/auth/sign_in_screen.dart';
import 'package:paypact/presentation/screens/expense/add_expense_screen.dart';
import 'package:paypact/presentation/screens/expense/expense_details_screen.dart';
import 'package:paypact/presentation/screens/group/create_group_screen.dart';
import 'package:paypact/presentation/screens/group/group_details_screen.dart';
import 'package:paypact/presentation/screens/home/home_screen.dart';
import 'package:paypact/presentation/screens/profile/profile_screen.dart';

class AppRoutes {
  static const signIn = '/sign-in';
  static const home = '/';
  static const groupDetail = '/group/:groupId';
  static const createGroup = '/group/create';
  static const addExpense = '/group/:groupId/expense/add';
  static const expenseDetail = '/expense/:expenseId';
  static const profile = '/profile';
}

class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) {
      final isAuth = _authBloc.state.isAuthenticated;
      final location = state.matchedLocation;
      final isSignIn = location == AppRoutes.signIn;

      if (!isAuth && !isSignIn) return AppRoutes.signIn;
      if (isAuth && isSignIn) return AppRoutes.home;
      return null;
    },
    onException: (_, state, router) {
      router.go(AppRoutes.home);
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, __) => const SignInScreen(),
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
