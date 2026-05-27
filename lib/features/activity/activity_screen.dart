import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/activity/cubit/activity_cubit.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : null;

    return BlocProvider(
      create: (_) {
        final cubit = locator<ActivityCubit>();
        if (userId != null) cubit.load(userId);
        return cubit;
      },
      child: const _ActivityBody(),
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Scaffold(
      backgroundColor: pt.bg,
      bottomNavigationBar: PayPactBottomNav(
        currentIndex: 2,
        onTap: (i) => [
          () => context.go(AppRoutes.home),
          () => context.go(AppRoutes.groups),
          () => context.go(AppRoutes.activity),
          () => context.go(AppRoutes.profile),
        ][i](),
        onFabTap: () => context.push('/group/create'),
      ),
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.06),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(PayPactSpacing.s6,
                      PayPactSpacing.s1, PayPactSpacing.s6, PayPactSpacing.s4),
                  child: Row(children: [
                    Text('RECENT',
                        style: PayPactTypography.label
                            .copyWith(color: pt.ink3, letterSpacing: 1.6)),
                    const Spacer(),
                    PpGlassIconButton(
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          final auth = context.read<AuthCubit>().state;
                          if (auth is AuthAuthenticated) {
                            context
                                .read<ActivityCubit>()
                                .load(auth.user.id);
                          }
                        }),
                    const SizedBox(width: 10),
                    PpGlassIconButton(
                        icon: Icons.search_rounded, onTap: () {}),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PayPactSpacing.s6, 0, PayPactSpacing.s6, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activity.',
                          style: PayPactTypography.displayLg
                              .copyWith(color: pt.ink)),
                      const SizedBox(height: 6),
                      BlocBuilder<ActivityCubit, ActivityState>(
                        builder: (context, state) {
                          if (state is ActivityLoaded) {
                            final total = state.days
                                .fold(0, (s, d) => s + d.items.length);
                            final need = state.days
                                .fold<int>(
                                    0,
                                    (s, d) =>
                                        s +
                                        d.items
                                            .where((i) => i.tone == 'negative')
                                            .length);
                            return Text.rich(
                              TextSpan(
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink2),
                                children: [
                                  TextSpan(text: '$total events · '),
                                  if (need > 0)
                                    TextSpan(
                                        text: '$need need attention',
                                        style: TextStyle(
                                            color: pt.accent,
                                            fontWeight: FontWeight.w600))
                                  else
                                    TextSpan(text: 'all settled up'),
                                ],
                              ),
                            );
                          }
                          return Text('Loading activity…',
                              style: PayPactTypography.bodyMd
                                  .copyWith(color: pt.ink3));
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ActivityCubit, ActivityState>(
                    builder: (context, state) {
                      if (state is ActivityLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ActivityError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(state.message,
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink3),
                                textAlign: TextAlign.center),
                          ),
                        );
                      }
                      if (state is ActivityLoaded) {
                        if (state.days.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    color: pt.ink3, size: 48),
                                const SizedBox(height: 14),
                                Text('No activity yet',
                                    style: PayPactTypography.headingMd
                                        .copyWith(color: pt.ink2)),
                                const SizedBox(height: 6),
                                Text('Add an expense to get started.',
                                    style: PayPactTypography.bodyMd
                                        .copyWith(color: pt.ink3)),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              PayPactSpacing.s6, 0, PayPactSpacing.s6, 120),
                          itemCount: state.days.length,
                          itemBuilder: (_, di) {
                            final day = state.days[di];
                            return _DaySection(
                                label: day.label, items: day.items);
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.label, required this.items});
  final String label;
  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
          child: Text(label,
              style: PayPactTypography.label
                  .copyWith(color: pt.ink3, letterSpacing: 1.5)),
        ),
        Stack(children: [
          Positioned(
            left: 19,
            top: 6,
            bottom: 6,
            child: Container(width: 1.5, color: pt.border),
          ),
          Column(children: [for (final it in items) _Tile(item: it)]),
        ]),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final amountColor = switch (item.tone) {
      'positive' => pt.positive,
      'negative' => pt.negative,
      'pending' => pt.warn,
      _ => pt.ink2,
    };

    return GestureDetector(
      onTap: item.expenseId != null
          ? () => context.push(
                '/expense/${item.expenseId}',
                extra: item.groupId != null ? {'groupId': item.groupId} : null,
              )
          : item.groupId != null
              ? () => context.push('/group/${item.groupId}')
              : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PpCategoryDisc(
                category: item.category, icon: item.icon, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: PayPactTypography.bodyMd
                          .copyWith(color: pt.ink, height: 1.45),
                      children: [
                        TextSpan(
                            text: item.who,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(
                            text: ' ${item.verb} ',
                            style: TextStyle(color: pt.ink2)),
                        TextSpan(
                            text: item.what,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (item.where != null)
                          TextSpan(
                              text: ' in ${item.where}',
                              style: TextStyle(color: pt.ink2)),
                      ],
                    ),
                  ),
                  if (item.sub != null) ...[
                    const SizedBox(height: 2),
                    Text(item.sub!,
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(
                      DateFormat('h:mm a').format(item.createdAt),
                      style: PayPactTypography.label
                          .copyWith(color: pt.ink3, fontSize: 9.5),
                    ),
                    if (item.amount != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '₹${item.amount!.toStringAsFixed(0)}',
                        style: PayPactTypography.amountSm.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
