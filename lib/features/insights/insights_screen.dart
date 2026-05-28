import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/insights/insights_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

// ── Period labels ─────────────────────────────────────────────────────────────

const _periods = ['Week', 'Month', '3M', 'Year'];

// ── Color mapping ─────────────────────────────────────────────────────────────

Color _categoryColor(String key, bool isDark) {
  if (isDark) {
    return switch (key) {
      'stay' => const Color(0xFFD4B47E),
      'food' => const Color(0xFFE8B891),
      'transport' => const Color(0xFFA8C8A6),
      'trip' => const Color(0xFF9BB8D4),
      'home' => const Color(0xFFD4A8C8),
      'shopping' => const Color(0xFFD4C8A8),
      'friends' => const Color(0xFFA8D4C8),
      'couple' => const Color(0xFFD4A8A8),
      _ => const Color(0xFFA8A090),
    };
  }
  return switch (key) {
    'stay' => const Color(0xFF6B5736),
    'food' => const Color(0xFF8B4A23),
    'transport' => const Color(0xFF4F6849),
    'trip' => const Color(0xFF3A6080),
    'home' => const Color(0xFF7A4070),
    'shopping' => const Color(0xFF706040),
    'friends' => const Color(0xFF3A7060),
    'couple' => const Color(0xFF704040),
    _ => const Color(0xFF6B6357),
  };
}

String _categoryLabel(String key) => switch (key) {
      'stay' => 'Stays',
      'food' => 'Food',
      'transport' => 'Transport',
      'trip' => 'Trip',
      'home' => 'Home',
      'shopping' => 'Shopping',
      'friends' => 'Friends',
      'couple' => 'Couple',
      _ => 'Other',
    };

// ── Amount formatter ──────────────────────────────────────────────────────────

String _fmtAmount(double amount, String symbol) {
  final abs = amount.abs().round();
  final prefix = amount < 0 ? '−$symbol' : symbol;
  if (abs == 0) return '${symbol}0';
  final s = abs.toString();
  if (s.length <= 3) return '$prefix$s';
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    buf.write(rest[i]);
    final remaining = rest.length - 1 - i;
    if (remaining > 0 && remaining % 2 == 0) buf.write(',');
  }
  return '$prefix${buf.toString()},$last3';
}

String _fmtShort(double amount, String symbol) {
  final abs = amount.abs().round();
  if (abs >= 100000) return '$symbol${(abs / 100000).toStringAsFixed(1)}L';
  if (abs >= 1000) return '$symbol${(abs / 1000).toStringAsFixed(1)}k';
  return '$symbol$abs';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : '';

    return BlocProvider(
      create: (_) => InsightsCubit(
        locator<GroupRepository>(),
        locator<ExpenseRepository>(),
        userId,
      )..loadInsights(InsightsPeriod.month),
      child: const _InsightsBody(),
    );
  }
}

class _InsightsBody extends StatefulWidget {
  const _InsightsBody();

  @override
  State<_InsightsBody> createState() => _InsightsBodyState();
}

class _InsightsBodyState extends State<_InsightsBody> {
  int _periodIndex = 1; // Default: Month

  void _changePeriod(int i) {
    setState(() => _periodIndex = i);
    context
        .read<InsightsCubit>()
        .loadInsights(InsightsPeriod.values[i]);
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Scaffold(
      backgroundColor: pt.bg,
      bottomNavigationBar: PayPactBottomNav(
        currentIndex: 0,
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
          const PpBackdropGlow(intensity: 0.10),
          SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => context.pop()),
                Expanded(
                  child: BlocBuilder<InsightsCubit, InsightsState>(
                    builder: (context, state) {
                      if (state is InsightsLoading) {
                        return _buildLoading(pt);
                      }
                      if (state is InsightsError) {
                        return _buildError(pt, state.message);
                      }
                      if (state is InsightsLoaded) {
                        return _buildLoaded(context, pt, state);
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

  Widget _buildLoading(PayPactThemeExtension pt) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(PayPactThemeExtension pt, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: pt.negative, size: 36),
            const SizedBox(height: 12),
            Text(
              'Could not load insights',
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    PayPactThemeExtension pt,
    InsightsLoaded state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trendPct = state.prevShare != null && state.prevShare! > 0
        ? ((state.yourShare - state.prevShare!) / state.prevShare! * 100).round()
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter row ───────────────────────────────────────────
          Text(
            state.filterLabel,
            style: PayPactTypography.label.copyWith(
              color: pt.ink3,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          // ── Hero amount ──────────────────────────────────────────
          Text(
            _fmtAmount(state.yourShare, state.currencySymbol),
            style: PayPactTypography.amountHero.copyWith(
              color: pt.ink,
              fontSize: 52,
              letterSpacing: -0.04 * 52,
            ),
          ),
          const SizedBox(height: 6),
          _TrendLine(
            pt: pt,
            yourShare: state.yourShare,
            totalSpent: state.totalSpent,
            currencySymbol: state.currencySymbol,
            trendPct: trendPct,
          ),
          const SizedBox(height: 22),
          // ── Period tabs ──────────────────────────────────────────
          _PeriodTabs(
            selected: _periodIndex,
            onChanged: _changePeriod,
          ),
          const SizedBox(height: 20),
          // ── Flow card ────────────────────────────────────────────
          _FlowCard(
            flowBars: state.flowBars,
            peakBarIndex: state.peakBarIndex,
            currencySymbol: state.currencySymbol,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          // ── Categories ───────────────────────────────────────────
          _WhereItWentCard(
            categories: state.categories,
            currencySymbol: state.currencySymbol,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          // ── People velocity ──────────────────────────────────────
          if (state.people.isNotEmpty)
            _PeopleSection(people: state.people, isDark: isDark),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Row(children: [
        PpGlassIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const Spacer(),
        Text(
          'Insights',
          style: PayPactTypography.bodyMd
              .copyWith(color: pt.ink, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        PpGlassIconButton(icon: Icons.ios_share_outlined, onTap: () {}),
      ]),
    );
  }
}

// ── Trend line ────────────────────────────────────────────────────────────────

class _TrendLine extends StatelessWidget {
  const _TrendLine({
    required this.pt,
    required this.yourShare,
    required this.totalSpent,
    required this.currencySymbol,
    required this.trendPct,
  });

  final PayPactThemeExtension pt;
  final double yourShare;
  final double totalSpent;
  final String currencySymbol;
  final int? trendPct;

  @override
  Widget build(BuildContext context) {
    final shareText = _fmtAmount(yourShare, currencySymbol);
    final isUp = (trendPct ?? 0) >= 0;

    return Row(
      children: [
        Text('Your share was ',
            style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
        Text(
          shareText,
          style: PayPactTypography.bodySm
              .copyWith(color: pt.ink, fontWeight: FontWeight.w600),
        ),
        if (trendPct != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isUp ? pt.negativeSoft : pt.positiveSoft,
              borderRadius: PayPactRadius.full,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color: isUp ? pt.negative : pt.positive,
                ),
                const SizedBox(width: 2),
                Text(
                  '${trendPct!.abs()}% vs last',
                  style: PayPactTypography.micro.copyWith(
                    color: isUp ? pt.negative : pt.positive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Period tabs ───────────────────────────────────────────────────────────────

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pt.surfaceAlt,
        borderRadius: PayPactRadius.full,
        border: Border.all(color: pt.border),
      ),
      child: Row(
        children: List.generate(_periods.length, (i) {
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: active ? pt.surface : Colors.transparent,
                  borderRadius: PayPactRadius.full,
                  boxShadow: active ? pt.shadowSm : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _periods[i],
                  style: PayPactTypography.bodySm.copyWith(
                    color: active ? pt.ink : pt.ink3,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Flow card ─────────────────────────────────────────────────────────────────

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.flowBars,
    required this.peakBarIndex,
    required this.currencySymbol,
    required this.isDark,
  });

  final List<InsightsBarData> flowBars;
  final int peakBarIndex;
  final String currencySymbol;
  final bool isDark;

  double get _barWidth {
    final n = flowBars.length;
    if (n <= 3) return 60.0;
    if (n <= 4) return 48.0;
    if (n <= 7) return 30.0;
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    if (flowBars.isEmpty) return const SizedBox.shrink();

    final maxVal = flowBars.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
    final peakBar = flowBars.isNotEmpty ? flowBars[peakBarIndex] : null;

    return PayPactCard(
      raised: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              'SPENDING FLOW',
              style: PayPactTypography.label
                  .copyWith(color: pt.ink3, letterSpacing: 1.5),
            ),
            const Spacer(),
            if (peakBar != null && peakBar.amount > 0) ...[
              Text(
                'peak ',
                style: PayPactTypography.micro.copyWith(color: pt.ink3),
              ),
              Text(
                _fmtShort(peakBar.amount, currencySymbol),
                style: PayPactTypography.micro
                    .copyWith(color: pt.ink, fontWeight: FontWeight.w600),
              ),
              Text(
                '  ${peakBar.label}',
                style:
                    PayPactTypography.micro.copyWith(color: pt.accent),
              ),
            ],
          ]),
          const SizedBox(height: 18),
          maxVal == 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No expenses this period',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3),
                    ),
                  ),
                )
              : SizedBox(
                  height: 100,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: maxVal * 1.25,
                      minY: 0,
                      barTouchData: BarTouchData(enabled: false),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= flowBars.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  flowBars[i].label,
                                  style: PayPactTypography.micro.copyWith(
                                    color: i == peakBarIndex
                                        ? pt.accent
                                        : pt.ink3,
                                    fontWeight: i == peakBarIndex
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: flowBars.length > 7
                                        ? 8.5
                                        : 10.0,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(flowBars.length, (i) {
                        final isPeak = i == peakBarIndex;
                        final barColor = isPeak
                            ? pt.accent
                            : (isDark
                                ? const Color(0xFF3A3028)
                                : const Color(0xFFE8E0D4));
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: flowBars[i].amount,
                              color: barColor,
                              width: _barWidth,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                                bottom: Radius.circular(2),
                              ),
                              rodStackItems: [],
                            ),
                          ],
                          showingTooltipIndicators: [],
                        );
                      }),
                    ),
                  ),
                ),
          if (maxVal > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(flowBars.length, (i) {
                final v = flowBars[i].amount;
                final label = v == 0
                    ? '—'
                    : _fmtShort(v, '');
                return SizedBox(
                  width: flowBars.length > 7 ? 24 : 42,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: PayPactTypography.micro.copyWith(
                      color: i == peakBarIndex ? pt.accent : pt.ink3,
                      fontWeight: i == peakBarIndex
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: flowBars.length > 7 ? 8.5 : 10.0,
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Where it went card ────────────────────────────────────────────────────────

class _WhereItWentCard extends StatelessWidget {
  const _WhereItWentCard({
    required this.categories,
    required this.currencySymbol,
    required this.isDark,
  });

  final List<InsightsCategoryData> categories;
  final String currencySymbol;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final ringBg =
        isDark ? const Color(0xFF2A241C) : const Color(0xFFF0E8DC);

    if (categories.isEmpty) {
      return PayPactCard(
        raised: true,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHERE IT WENT',
              style: PayPactTypography.label
                  .copyWith(color: pt.ink3, letterSpacing: 1.5),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No expenses tracked yet',
                style:
                    PayPactTypography.bodySm.copyWith(color: pt.ink3),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
    }

    return PayPactCard(
      raised: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              'WHERE IT WENT',
              style: PayPactTypography.label
                  .copyWith(color: pt.ink3, letterSpacing: 1.5),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2.5,
                        centerSpaceRadius: 34,
                        centerSpaceColor: ringBg,
                        startDegreeOffset: -90,
                        sections: categories
                            .map((c) => PieChartSectionData(
                                  value: c.fraction * 100,
                                  color: _categoryColor(
                                      c.categoryKey, isDark),
                                  radius: 22,
                                  showTitle: false,
                                ))
                            .toList(),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CATEG.',
                          style: PayPactTypography.micro.copyWith(
                              color: pt.ink3,
                              fontSize: 8,
                              letterSpacing: 0.6),
                        ),
                        Text(
                          '${categories.length}',
                          style: PayPactTypography.amountLg
                              .copyWith(color: pt.ink, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: categories
                      .map((c) => _CategoryRow(
                            cat: c,
                            pt: pt,
                            isDark: isDark,
                            currencySymbol: currencySymbol,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.cat,
    required this.pt,
    required this.isDark,
    required this.currencySymbol,
  });

  final InsightsCategoryData cat;
  final PayPactThemeExtension pt;
  final bool isDark;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final pct = (cat.fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _categoryColor(cat.categoryKey, isDark),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _categoryLabel(cat.categoryKey),
            style: PayPactTypography.bodySm.copyWith(color: pt.ink2),
          ),
        ),
        Text(
          '$pct%',
          style: PayPactTypography.micro.copyWith(color: pt.ink3),
        ),
        const SizedBox(width: 8),
        Text(
          _fmtShort(cat.amount, currencySymbol),
          style: PayPactTypography.amountSm.copyWith(color: pt.ink),
        ),
      ]),
    );
  }
}

// ── People · settlement velocity ──────────────────────────────────────────────

class _PeopleSection extends StatelessWidget {
  const _PeopleSection(
      {required this.people, required this.isDark});
  final List<InsightsPersonData> people;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'PEOPLE · SETTLEMENT VELOCITY',
            style: PayPactTypography.label
                .copyWith(color: pt.ink3, letterSpacing: 1.5),
          ),
        ),
        PayPactCard(
          raised: true,
          padding: EdgeInsets.zero,
          child: Column(
            children: people.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return Column(
                children: [
                  if (i > 0) Divider(color: pt.border, height: 1),
                  _PersonRow(person: p, isDark: isDark),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.isDark});
  final InsightsPersonData person;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final trackColor =
        isDark ? const Color(0xFF2A241C) : const Color(0xFFEDE5D8);
    final avgText = person.avgDays != null
        ? '${person.avgDays!.round()}d'
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        PpAvatar(name: person.name, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: PayPactTypography.bodyMd
                    .copyWith(color: pt.ink, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: PayPactRadius.full,
                child: SizedBox(
                  height: 5,
                  child: LinearProgressIndicator(
                    value: person.velocity,
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation(pt.positive),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              avgText,
              style: PayPactTypography.amountMd
                  .copyWith(color: pt.ink, fontWeight: FontWeight.w600),
            ),
            Text(
              'avg. settle',
              style:
                  PayPactTypography.micro.copyWith(color: pt.ink3),
            ),
          ],
        ),
      ]),
    );
  }
}
