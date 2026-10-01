import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/locale_cubit.dart';
import 'package:paypact/l10n/app_localizations.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/services/app_lock_service.dart';
import 'package:paypact/core/services/background_inbox.dart';
import 'package:paypact/core/services/inbox_watcher.dart';
import 'package:paypact/core/services/notification_service.dart';
import 'package:paypact/core/services/telemetry_service.dart';
import 'package:paypact/features/notification/domain/notification_routing.dart';
import 'package:paypact/widgets/app_lock_gate.dart';
import 'package:paypact/widgets/connectivity_banner.dart';
import 'package:paypact/core/theme/theme_cubit.dart';
import 'package:paypact/design_system/theme/paypact_theme.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';
import 'package:paypact/firebase_options.dart';

/// `flutter run --dart-define=USE_EMULATORS=true` points the app at the local
/// Firebase emulators (see README) — handy for trying signed-in flows without
/// touching production data. `EMULATOR_HOST` defaults to localhost; use
/// 10.0.2.2 from an Android emulator.
const _useEmulators = bool.fromEnvironment('USE_EMULATORS');
const _emulatorHost =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

/// reCAPTCHA v3 site key for App Check on the web build
/// (`--dart-define=RECAPTCHA_SITE_KEY=...`). Without it web skips App Check.
const _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

Future<void> _connectEmulators() async {
  await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
}

/// App Check proves requests come from the genuine app. Debug providers are
/// used in debug builds (register the printed debug token in the Firebase
/// console). A failure here must never stop the app from starting.
Future<void> _activateAppCheck() async {
  if (_useEmulators) return;
  try {
    if (kIsWeb) {
      if (_recaptchaSiteKey.isEmpty) return;
      await FirebaseAppCheck.instance
          .activate(providerWeb: ReCaptchaV3Provider(_recaptchaSiteKey));
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e) {
    debugPrint('App Check activation failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (_useEmulators) {
    await _connectEmulators();
  } else {
    // Keep working from the cache while offline; writes queue and sync later.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  await _activateAppCheck();
  await initializeDependencies();
  await locator<TelemetryService>().init();

  final authCubit = locator<AuthCubit>();
  authCubit.init();
  // Device notifications come from the person's live Firestore inbox.
  void syncInbox(AuthState state) {
    final watcher = locator<InboxWatcher>();
    if (state is AuthAuthenticated) {
      watcher.start(state.user.id);
      unawaited(BackgroundInbox.schedule());
    } else {
      watcher.stop();
      unawaited(BackgroundInbox.cancel());
    }
  }

  authCubit.stream.listen(syncInbox);
  syncInbox(authCubit.state);

  // Tapping a notification opens what it's about.
  locator<NotificationService>().onOpen = (data) {
    final route = routeForNotification(
      type: data['type'] as String?,
      groupId: data['groupId'] as String?,
    );
    appRouter.push(route);
  };

  runApp(const PaypactApp());

  // Set up notifications after the app is running. Kept off the startup
  // await-chain so a failure can never block the UI from rendering.
  unawaited(locator<NotificationService>().initialize());
}

class PaypactApp extends StatelessWidget {
  const PaypactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: locator<AuthCubit>()),
        BlocProvider.value(value: locator<ThemeCubit>()),
        BlocProvider.value(value: locator<LocaleCubit>()),
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
          child: BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) => BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) => MaterialApp.router(
                title: 'PayPact',
                debugShowCheckedModeBanner: false,
                theme: PayPactTheme.lightTheme,
                darkTheme: PayPactTheme.darkTheme,
                themeMode: themeMode,
                // null = follow the device, falling back to English.
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                routerConfig: appRouter,
                builder: (context, child) => AppLockGate(
                  service: locator<AppLockService>(),
                  child: ConnectivityBanner(child: child ?? const SizedBox()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _userIdOf(AuthState s) =>
      s is AuthAuthenticated ? s.user.id : '';
}
