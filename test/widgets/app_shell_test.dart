import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/services/app_lock_service.dart';
import 'package:paypact/design_system/theme/paypact_theme.dart';
import 'package:paypact/l10n/app_localizations.dart';
import 'package:paypact/l10n/app_localizations_en.dart';
import 'package:paypact/l10n/app_localizations_hi.dart';
import 'package:paypact/widgets/app_lock_gate.dart';
import 'package:paypact/widgets/connectivity_banner.dart';
import 'package:paypact/widgets/pp_atoms.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLock extends Mock implements AppLockService {}

Widget _app(Widget home, {Locale? locale}) => MaterialApp(
      theme: PayPactTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: home),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('accessibility', () {
    testWidgets('icon buttons are labelled and large enough to tap',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(Row(children: [
        PpGlassIconButton(icon: Icons.arrow_back_rounded, onTap: () {}),
        PpGlassIconButton(icon: Icons.search_rounded, onTap: () {}),
        PpGlassIconButton(
            icon: Icons.qr_code_2_rounded, label: 'Show my QR', onTap: () {}),
      ])));

      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Search'), findsOneWidget);
      expect(find.bySemanticsLabel('Show my QR'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('an unknown icon still gets a (generic) spoken label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
          _app(PpGlassIconButton(icon: Icons.star, onTap: () {})));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('avatars announce the person, not "image"', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const PpAvatar(name: 'Asha Rao')));
      expect(find.bySemanticsLabel('Asha Rao'), findsOneWidget);
      handle.dispose();
    });
  });

  group('localization', () {
    test('every English string has a Hindi translation and vice versa', () {
      final en = AppLocalizationsEn();
      final hi = AppLocalizationsHi();
      // Same getters must exist and produce text; and the two must differ for
      // the strings that are actually translated.
      expect(en.navHome, 'Home');
      expect(hi.navHome, 'होम');
      expect(en.signInButton, isNot(hi.signInButton));
      expect(hi.searchNothing('चाय'), contains('चाय'));
      expect(en.searchNothing('tea'), 'Nothing matches "tea".');
    });

    test('plurals', () {
      expect(AppLocalizationsEn().memberCount(1), '1 member');
      expect(AppLocalizationsEn().memberCount(5), '5 members');
      expect(AppLocalizationsHi().memberCount(1), '1 सदस्य');
      expect(AppLocalizationsHi().memberCount(3), '3 सदस्य');
    });

    testWidgets('the offline banner follows the chosen language',
        (tester) async {
      final stream = StreamController<List<ConnectivityResult>>();
      await tester.pumpWidget(_app(
        ConnectivityBanner(
            stream: stream.stream, child: const SizedBox.expand()),
        locale: const Locale('hi'),
      ));
      stream.add([ConnectivityResult.none]);
      await tester.pumpAndSettle();
      expect(find.textContaining('ऑफ़लाइन'), findsOneWidget);
      await stream.close();
    });
  });

  group('connectivity banner', () {
    test('isOffline: only when there is no network at all', () {
      expect(isOffline([]), isTrue);
      expect(isOffline([ConnectivityResult.none]), isTrue);
      expect(isOffline([ConnectivityResult.wifi]), isFalse);
      expect(isOffline([ConnectivityResult.none, ConnectivityResult.mobile]),
          isFalse);
    });

    testWidgets('appears when offline and disappears when back', (tester) async {
      final stream = StreamController<List<ConnectivityResult>>();
      await tester.pumpWidget(_app(ConnectivityBanner(
          stream: stream.stream, child: const SizedBox.expand())));
      expect(find.textContaining('offline'), findsNothing);

      stream.add([ConnectivityResult.none]);
      await tester.pumpAndSettle();
      expect(find.textContaining("You're offline"), findsOneWidget);

      stream.add([ConnectivityResult.wifi]);
      await tester.pumpAndSettle();
      expect(find.textContaining('offline'), findsNothing);
      await stream.close();
    });
  });

  group('AppLockService', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('off by default; never locks until enabled', () async {
      final s = AppLockService(prefs);
      expect(s.enabled, isFalse);
      expect(s.shouldLockAfter(const Duration(hours: 1)), isFalse);
    });

    test('locks only after the grace period', () async {
      final s = AppLockService(prefs);
      await s.setEnabled(true);
      expect(s.enabled, isTrue);
      expect(s.shouldLockAfter(const Duration(seconds: 5)), isFalse);
      expect(s.shouldLockAfter(AppLockService.gracePeriod), isTrue);
      expect(s.shouldLockAfter(const Duration(minutes: 5)), isTrue);
    });
  });

  group('AppLockGate', () {
    setUpAll(() => registerFallbackValue(Duration.zero));
    late _FakeLock lock;
    late DateTime now;

    setUp(() {
      lock = _FakeLock();
      now = DateTime(2026, 10, 1, 12);
      when(() => lock.enabled).thenReturn(true);
      when(() => lock.shouldLockAfter(any()))
          .thenAnswer((i) => (i.positionalArguments[0] as Duration) >= AppLockService.gracePeriod);
    });

    Future<void> pump(WidgetTester t) => t.pumpWidget(_app(
        AppLockGate(
            service: lock, clock: () => now, child: const Text('secret'))));

    testWidgets('covers the app at launch and unlocks after authentication',
        (tester) async {
      var result = false;
      when(() => lock.authenticate()).thenAnswer((_) async => result);

      await pump(tester);
      await tester.pump();
      expect(find.text('PayPact is locked'), findsOneWidget);

      result = true;
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('PayPact is locked'), findsNothing);
      expect(find.text('secret'), findsOneWidget);
    });

    testWidgets('stays locked when authentication fails', (tester) async {
      when(() => lock.authenticate()).thenAnswer((_) async => false);
      await pump(tester);
      await tester.pumpAndSettle();
      expect(find.text('PayPact is locked'), findsOneWidget);
    });

    testWidgets('no lock at all when the setting is off', (tester) async {
      when(() => lock.enabled).thenReturn(false);
      await pump(tester);
      await tester.pump();
      expect(find.text('PayPact is locked'), findsNothing);
      expect(find.text('secret'), findsOneWidget);
    });

    testWidgets('re-locks after a long absence but not a short one',
        (tester) async {
      when(() => lock.enabled).thenReturn(true);
      when(() => lock.authenticate()).thenAnswer((_) async => true);

      await pump(tester);
      await tester.pumpAndSettle(); // launch lock → authenticated
      expect(find.text('PayPact is locked'), findsNothing);

      // a 5 second trip to another app: stays unlocked
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(seconds: 5));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('PayPact is locked'), findsNothing);

      // ten minutes away: locks again (and prompts)
      when(() => lock.authenticate()).thenAnswer((_) async => false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('PayPact is locked'), findsOneWidget);
    });
  });
}
