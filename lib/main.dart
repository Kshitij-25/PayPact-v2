import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/services/deep_link_service.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';
import 'package:paypact/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:paypact/features/profile/presentation/bloc/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDependencies();

  // Initialize local notifications (creates Android channel, requests iOS permission)
  // await locator<LocalNotificationService>().initialize();

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
  // final LocalNotificationService _localNotif =
  //     locator<LocalNotificationService>();

  @override
  void initState() {
    super.initState();
    _authBloc = locator<AuthBloc>()..add(AuthStarted());
    _groupBloc = locator<GroupBloc>();
    _appRouter = AppRouter(_authBloc);

    // Start/stop Firestore notification listener based on auth state
    // _authBloc.stream.listen((state) {
    //   if (state.user != null) {
    //     _localNotif.startListening(state.user!.id);
    //   } else {
    //     _localNotif.stopListening();
    //   }
    // });

    // Deep link handling
    _deepLinkService = DeepLinkService();
    _deepLinkService.initialize();

    _deepLinkService.onInviteCodeReceived.listen((code) {
      final user = _authBloc.state.user;
      if (user != null) {
        _groupBloc.add(GroupJoinRequested(inviteCode: code, user: user));
      } else {
        _authBloc.stream.firstWhere((s) => s.user != null).then((s) {
          _groupBloc.add(
            GroupJoinRequested(inviteCode: code, user: s.user!),
          );
        }).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _groupBloc.close();
    _deepLinkService.dispose();
    // _localNotif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _groupBloc),
        BlocProvider(create: (_) => locator<ExpenseBloc>()),
        BlocProvider(
          create: (_) =>
              locator<NotificationBloc>()..add(NotificationInitRequested()),
        ),
        BlocProvider.value(value: locator<SettingsBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (p, c) =>
            p.themeMode != c.themeMode || p.languageCode != c.languageCode,
        builder: (_, settings) => MaterialApp.router(
          title: 'Paypact',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          // ── Localisation ────────────────────────────────────────────────
          locale: Locale(settings.languageCode),
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('de'),
            Locale('hi'),
            Locale('zh'),
            Locale('ja'),
            Locale('ko'),
            Locale('ar'),
            Locale('pt'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
