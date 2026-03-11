import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/services/deep_link_service.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';
import 'package:paypact/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:paypact/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:paypact/firebase_options.dart';

import 'core/di/injection_container.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeDependencies();
  runApp(const PaypactApp());
}

class PaypactApp extends StatefulWidget {
  const PaypactApp({super.key});

  @override
  State<PaypactApp> createState() => _PaypactAppState();
}

class _PaypactAppState extends State<PaypactApp> {
  late final AuthBloc _authBloc;
  late final GroupBloc _groupBloc;
  late final AppRouter _appRouter;
  late final DeepLinkService _deepLinkService;
  String? _lastInviteCode;

  @override
  void initState() {
    super.initState();

    _authBloc = locator<AuthBloc>()..add(AuthStarted());
    _groupBloc = locator<GroupBloc>();
    _appRouter = AppRouter(_authBloc);

    _deepLinkService = DeepLinkService();

    // Listen first
    _deepLinkService.onInviteCodeReceived.listen(_handleInviteCode);

    // Then initialize
    _deepLinkService.initialize();
  }

  void _handleInviteCode(String code) {
    if (_lastInviteCode == code) return;
    _lastInviteCode = code;

    final user = _authBloc.state.user;

    if (user != null) {
      _groupBloc.add(GroupJoinRequested(inviteCode: code, user: user));
    } else {
      _authBloc.stream.firstWhere((s) => s.user != null).then((s) {
        _groupBloc.add(
          GroupJoinRequested(inviteCode: code, user: s.user!),
        );
      });
    }
  }

  @override
  void dispose() {
    _authBloc.close();
    _groupBloc.close();
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _groupBloc),
        BlocProvider(create: (_) => locator<ExpenseBloc>()),
        BlocProvider.value(value: locator<SettingsBloc>()),
        BlocProvider(
          create: (_) =>
              locator<NotificationBloc>()..add(NotificationInitRequested()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (p, c) => p.themeMode != c.themeMode,
        builder: (_, settings) => MaterialApp.router(
          title: 'Paypact',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
