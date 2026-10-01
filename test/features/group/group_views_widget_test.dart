import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/theme/paypact_theme.dart';
import 'package:paypact/features/group/data/invite_service.dart';
import 'package:paypact/features/group/presentation/cubit/group_detail_cubit.dart';
import 'package:paypact/features/group/presentation/screens/join_group_screen.dart';
import 'package:paypact/features/group/presentation/widgets/group_tab_views.dart';

import 'test_helpers.dart';

class _Service extends Mock implements InviteService {}

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: dark ? PayPactTheme.darkTheme : PayPactTheme.lightTheme,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

GroupDetailLoaded _loaded() => GroupDetailLoaded(
      group: makeGroup(
          members: ['alice', 'bob', 'cy'], admins: ['alice'], currency: 'USD'),
      expenses: [
        makeExpense(payer: 'alice', total: 90, among: ['alice', 'bob', 'cy'])
      ],
      netBalance: 60,
      memberBalances: const {'bob': 30, 'cy': 30},
      globalMemberBalances: const {'alice': 60, 'bob': -30, 'cy': -30},
      settlements: [
        {
          'fromUserName': 'Bob',
          'toUserName': 'Alice',
          'amountPaise': 1000,
          'createdAt': DateTime(2026, 1, 3),
        }
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The theme uses Google Fonts; never hit the network from a test.
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final dark in [false, true]) {
    final label = dark ? 'dark' : 'light';

    testWidgets('balances tab lists everyone with the group currency ($label)',
        (tester) async {
      await tester.pumpWidget(_host(
          GroupBalancesView(loaded: _loaded(), currentUserId: 'alice'),
          dark: dark));

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Cy'), findsOneWidget);
      expect(find.text(r'$60'), findsOneWidget); // alice is owed
      expect(find.text(r'$30'), findsNWidgets(2)); // bob + cy owe
      expect(find.text('gets back'), findsOneWidget);
      expect(find.text('owes'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('activity tab shows expenses and settlements ($label)',
        (tester) async {
      await tester.pumpWidget(
          _host(GroupActivityView(loaded: _loaded()), dark: dark));

      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Bob paid Alice'), findsOneWidget);
      expect(find.text(r'$10'), findsOneWidget); // settlement 1000 paise
      expect(tester.takeException(), isNull);
    });

    testWidgets('members tab marks admins and offers invite actions ($label)',
        (tester) async {
      await tester.pumpWidget(_host(
          GroupMembersView(loaded: _loaded(), currentUserId: 'bob'),
          dark: dark));

      expect(find.text('You'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget); // only alice
      expect(find.text('Add people'), findsOneWidget);
      expect(find.text('Invite link'), findsOneWidget);
      // not an admin → no role management link
      expect(find.text('Manage roles & members'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an empty activity tab says so', (tester) async {
    await tester.pumpWidget(_host(GroupActivityView(
        loaded: GroupDetailLoaded(
      group: makeGroup(),
      expenses: const [],
      netBalance: 0,
      memberBalances: const {},
      globalMemberBalances: const {},
    ))));
    expect(find.text('No activity yet in this group'), findsOneWidget);
  });

  group('JoinGroupScreen', () {
    late _Service service;

    setUp(() async {
      await locator.reset();
      service = _Service();
      locator.registerSingleton<InviteService>(service);
    });
    tearDown(() => locator.reset());

    testWidgets('a malformed code never calls the backend', (tester) async {
      await tester.pumpWidget(MaterialApp(
          theme: PayPactTheme.lightTheme,
          home: const JoinGroupScreen(code: 'oops')));
      await tester.pump();

      expect(find.text('Invalid invite link'), findsOneWidget);
      verifyNever(() => service.preview(any()));
    });

    testWidgets('shows what you are joining and offers to join',
        (tester) async {
      when(() => service.preview('ABCD2345')).thenAnswer((_) async =>
          const InvitePreview(
              name: 'Goa trip', emoji: '🏖', memberCount: 4, alreadyMember: false));
      await tester.pumpWidget(MaterialApp(
          theme: PayPactTheme.lightTheme,
          home: const JoinGroupScreen(code: 'abcd2345')));
      await tester.pumpAndSettle();

      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('4 members'), findsOneWidget);
      expect(find.text('Join group'), findsOneWidget);
      verify(() => service.preview('ABCD2345')).called(1); // normalised
    });

    testWidgets('an expired link explains itself', (tester) async {
      when(() => service.preview(any())).thenThrow(
          const InviteException('This invite link is no longer valid.'));
      await tester.pumpWidget(MaterialApp(
          theme: PayPactTheme.lightTheme,
          home: const JoinGroupScreen(code: 'ABCD2345')));
      await tester.pumpAndSettle();

      expect(find.text("Can't join this group"), findsOneWidget);
      expect(find.text('This invite link is no longer valid.'), findsOneWidget);
    });
  });
}
