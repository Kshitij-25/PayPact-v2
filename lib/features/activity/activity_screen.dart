import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/adaptive_nav_scaffold.dart';
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

    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        final total = state is ActivityLoaded
            ? state.days.fold(0, (s, d) => s + d.items.length)
            : 0;
        final need = state is ActivityLoaded
            ? state.days.fold<int>(
                0,
                (s, d) =>
                    s + d.items.where((i) => i.tone == 'negative').length)
            : 0;

        return AdaptiveNavScaffold(
          currentIndex: 2,
          onNavTap: (i) => [
            () => context.go(AppRoutes.home),
            () => context.go(AppRoutes.groups),
            () => context.go(AppRoutes.activity),
            () => context.go(AppRoutes.profile),
          ][i](),
          onFabTap: () => context.push('/group/create'),
          webEyebrow: 'ACTIVITY',
          webTitle: 'Activity.',
          webSubtitle: state is ActivityLoaded
              ? '$total events · ${need > 0 ? '$need need attention' : 'all settled up'}'
              : null,
          body: context.isDesktop
              ? _WebActivityBody(state: state)
              : Stack(
                  children: [
                    const PpBackdropGlow(intensity: 0.06),
                    SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                PayPactSpacing.s6,
                                PayPactSpacing.s1,
                                PayPactSpacing.s6,
                                PayPactSpacing.s4),
                            child: Row(children: [
                              Text('RECENT',
                                  style: PayPactTypography.label.copyWith(
                                      color: pt.ink3, letterSpacing: 1.6)),
                              const Spacer(),
                              PpGlassIconButton(
                                  icon: Icons.refresh_rounded,
                                  onTap: () {
                                    final auth =
                                        context.read<AuthCubit>().state;
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
                                if (state is ActivityLoaded)
                                  Text.rich(
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
                                  )
                                else
                                  Text('Loading activity…',
                                      style: PayPactTypography.bodyMd
                                          .copyWith(color: pt.ink3)),
                              ],
                            ),
                          ),
                          Expanded(child: _ActivityList(state: state)),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ── Shared activity list ──────────────────────────────────────────────────────

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.state});
  final ActivityState state;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    if (state is ActivityLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ActivityError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text((state as ActivityError).message,
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink3),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (state is ActivityLoaded) {
      final days = (state as ActivityLoaded).days;
      if (days.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, color: pt.ink3, size: 48),
              const SizedBox(height: 14),
              Text('No activity yet',
                  style: PayPactTypography.headingMd.copyWith(color: pt.ink2)),
              const SizedBox(height: 6),
              Text('Add an expense to get started.',
                  style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            PayPactSpacing.s6, 0, PayPactSpacing.s6, 120),
        itemCount: days.length,
        itemBuilder: (_, di) =>
            _DaySection(label: days[di].label, items: days[di].items),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Web activity body ─────────────────────────────────────────────────────────

class _WebActivityBody extends StatelessWidget {
  const _WebActivityBody({required this.state});
  final ActivityState state;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    if (state is ActivityLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ActivityError) {
      return Center(
        child: Text((state as ActivityError).message,
            style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
      );
    }
    if (state is ActivityLoaded) {
      final days = (state as ActivityLoaded).days;
      if (days.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, color: pt.ink3, size: 48),
              const SizedBox(height: 14),
              Text('No activity yet',
                  style: PayPactTypography.headingMd.copyWith(color: pt.ink2)),
            ],
          ),
        );
      }

      final allItems = [
        for (final day in days)
          for (final item in day.items) (day: day.label, item: item),
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: Container(
          decoration: BoxDecoration(
            color: pt.surface,
            borderRadius: PayPactRadius.lg,
            border: Border.all(color: pt.border),
          ),
          child: Column(
            children: [
              // Table header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('DATE',
                          style: PayPactTypography.label
                              .copyWith(color: pt.ink3, letterSpacing: 1.4)),
                    ),
                    Expanded(
                      child: Text('EVENT',
                          style: PayPactTypography.label
                              .copyWith(color: pt.ink3, letterSpacing: 1.4)),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text('AMOUNT',
                          textAlign: TextAlign.end,
                          style: PayPactTypography.label
                              .copyWith(color: pt.ink3, letterSpacing: 1.4)),
                    ),
                  ],
                ),
              ),
              Divider(color: pt.border, height: 1),
              for (int i = 0; i < allItems.length; i++) ...[
                if (i > 0) Divider(color: pt.border, height: 1),
                _WebActivityRow(
                  dayLabel: allItems[i].day,
                  item: allItems[i].item,
                ),
              ],
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _WebActivityRow extends StatelessWidget {
  const _WebActivityRow({required this.dayLabel, required this.item});
  final String dayLabel;
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
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(dayLabel,
                  style:
                      PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PpCategoryDisc(
                      category: item.category, icon: item.icon, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: PayPactTypography.bodyMd
                            .copyWith(color: pt.ink, height: 1.4),
                        children: [
                          TextSpan(
                              text: item.who,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          TextSpan(
                              text: ' ${item.verb} ',
                              style: TextStyle(color: pt.ink2)),
                          TextSpan(
                              text: item.what,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          if (item.where != null)
                            TextSpan(
                                text: ' in ${item.where}',
                                style: TextStyle(color: pt.ink2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                item.amount != null
                    ? '₹${item.amount!.toStringAsFixed(0)}'
                    : '—',
                textAlign: TextAlign.end,
                style: PayPactTypography.amountMd
                    .copyWith(color: amountColor),
              ),
            ),
          ],
        ),
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
