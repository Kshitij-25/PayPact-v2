import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/services/notification_service.dart';
import 'package:paypact/core/theme/theme_cubit.dart';
import 'package:paypact/design_system/theme/paypact_theme.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';
import 'package:paypact/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDependencies();
  await locator<NotificationService>().initialize();
  final authCubit = locator<AuthCubit>();
  authCubit.init();
  authCubit.stream.listen((state) {
    if (state is AuthAuthenticated) {
      locator<NotificationService>().saveToken(state.user.id);
    }
  });
  runApp(const PaypactApp());
}

class PaypactApp extends StatelessWidget {
  const PaypactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: locator<AuthCubit>()),
        BlocProvider.value(value: locator<ThemeCubit>()),
      ],
      // Global GroupsCubit so the workspace net balance is available to the
      // sidebar on every screen. Created once; it reloads on sign in/out via a
      // listener so the router/MaterialApp is never rebuilt by auth changes.
      child: BlocProvider<GroupsCubit>(
        create: (_) => GroupsCubit(
          locator<GroupRepository>(),
          locator<ExpenseRepository>(),
          _userIdOf(locator<AuthCubit>().state),
        )..loadGroups(),
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) => _userIdOf(prev) != _userIdOf(curr),
          listener: (context, state) =>
              context.read<GroupsCubit>().setUser(_userIdOf(state)),
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) => MaterialApp.router(
              title: 'PayPact',
              debugShowCheckedModeBanner: false,
              theme: PayPactTheme.lightTheme,
              darkTheme: PayPactTheme.darkTheme,
              themeMode: themeMode,
              locale: const Locale('en'),
              supportedLocales: const [Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              routerConfig: appRouter,
            ),
          ),
        ),
      ),
    );
  }

  static String _userIdOf(AuthState s) =>
      s is AuthAuthenticated ? s.user.id : '';
}
