import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:paypact/core/utils/default_currency.dart';
import 'package:paypact/features/expense/data/recurring_runner.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/data/summary_service.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/data/digest_service.dart';
import 'package:paypact/features/settle/domain/debt_simplifier.dart';

part 'groups_state.dart';

/// Everything Home / Groups needs from one group, however it was obtained.
class _GroupSlice {
  _GroupSlice({
    required this.group,
    required this.myNet,
    required this.recent,
    required this.weeklyDelta,
    required this.meta,
    required this.owedToMe,
    required this.lastActivity,
    required this.settleDays,
  });
  final GroupEntity group;
  final double myNet; // group currency
  final List<RecentExpenseItem> recent;
  final double weeklyDelta; // group currency
  final GroupMeta meta;

  /// +amount = that member owes me, −amount = I owe them (simplified plan).
  final Map<String, double> owedToMe;
  final DateTime? lastActivity;

  /// Days from the group's start to each recorded settlement.
  final List<double> settleDays;
}

class GroupsCubit extends Cubit<GroupsState> {
  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;
  final ExchangeRateService? _rates;
  final String Function()? _defaultCurrency;
  final SummaryService? _summaries;
  final RecurringRunner? _recurring;
  final DigestService? _digest;
  String _userId;
  StreamSubscription<List<GroupEntity>>? _sub;

  /// [rates] / [defaultCurrency] / [summaries] default to the app-wide
  /// instances; tests inject their own.
  GroupsCubit(this._groupRepo, this._expenseRepo, this._userId,
      {ExchangeRateService? rates,
      String Function()? defaultCurrency,
      SummaryService? summaries,
      RecurringRunner? recurring,
      DigestService? digest})
      : _rates = rates,
        _defaultCurrency = defaultCurrency,
        _summaries = summaries,
        _recurring = recurring,
        _digest = digest,
        super(GroupsInitial());

  /// Switch the active user (used by the global instance on sign in/out)
  /// and reload, without tearing down the widget tree.
  void setUser(String userId) {
    if (userId == _userId) return;
    _userId = userId;
    loadGroups();
  }

  /// Rate from each group currency into [target]. Groups whose rate can't be
  /// fetched are left out (treated 1:1) rather than failing the whole screen.
  Future<Map<String, double>> _ratesInto(
      String target, Iterable<String> currencies) async {
    final out = <String, double>{};
    ExchangeRateService svc;
    try {
      svc = _rates ?? locator<ExchangeRateService>();
    } catch (_) {
      return out;
    }
    for (final c in currencies.toSet()) {
      if (c == target) continue;
      try {
        out[c] = await svc.getRate(c, target);
      } catch (_) {}
    }
    return out;
  }

  void _ensureSummary(String groupId) {
    try {
      (_summaries ?? locator<SummaryService>()).ensure(groupId);
    } catch (_) {}
  }

  /// Work the backend used to do on a schedule, done when the app opens:
  /// recurring expenses that have fallen due, and the weekly digest.
  void _housekeeping(List<GroupEntity> groups) {
    if (_userId.isEmpty) return;
    try {
      final runner = _recurring ?? locator<RecurringRunner>();
      for (final g in groups) {
        runner
            .runForGroup(
              groupId: g.id,
              groupName: g.name,
              memberIds: g.memberIds,
              actorId: _userId,
              actorName: g.memberNames[_userId] ?? '',
            )
            .ignore();
      }
    } catch (_) {}
    try {
      (_digest ?? locator<DigestService>())
          .maybeSend(_userId, groups)
          .ignore();
    } catch (_) {}
  }

  void loadGroups() {
    _sub?.cancel();
    if (_userId.isEmpty) {
      if (!isClosed) emit(GroupsInitial());
      return;
    }
    emit(GroupsLoading());
    _sub = _groupRepo.watchUserGroups(_userId).listen(
      (groups) async {
        try {
          final now = DateTime.now();
          final weekStart =
              DateTime(now.year, now.month, now.day - (now.weekday - 1));
          final slices = await Future.wait(
              groups.map((g) => _sliceFor(g, weekStart)));
          final target = (_defaultCurrency ?? userDefaultCurrency)();
          final toTarget =
              await _ratesInto(target, groups.map((g) => g.currency));
          if (isClosed) return;
          emit(_assemble(slices, now, toTarget));
          _housekeeping(groups);
        } catch (e) {
          if (!isClosed) emit(GroupsError(e.toString()));
        }
      },
      onError: (e) => emit(GroupsError(e.toString())),
    );
  }

  /// One group's contribution. With a server summary this is a handful of
  /// bounded queries no matter how long the group has existed; without one it
  /// reads the whole history (and asks the backend to build the summary so the
  /// next refresh is cheap).
  Future<_GroupSlice> _sliceFor(GroupEntity g, DateTime weekStart) async {
    Map<String, int> balances;
    List<ExpenseEntity>? all;
    List<Map<String, dynamic>>? allSettlements;

    if (g.hasSummary) {
      balances = g.balances!;
    } else {
      _ensureSummary(g.id);
      all = await _expenseRepo.getGroupExpenses(g.id);
      allSettlements = await _expenseRepo.getGroupSettlements(g.id);
      balances = computeNetBalances(
          expenses: all, settlements: allSettlements, memberIds: g.memberIds);
    }

    // Bounded reads (the legacy path already has everything in memory).
    final recentExpenses = all?.take(5).toList() ??
        await _expenseRepo.getGroupExpenses(g.id, limit: 5);
    final weekExpenses = all
            ?.where((e) => !e.createdAt.isBefore(weekStart))
            .toList() ??
        await _expenseRepo.getGroupExpenses(g.id,
            since: weekStart, limit: 200);
    final settlements = allSettlements ??
        await _expenseRepo.getGroupSettlements(g.id, limit: 50);

    // This week's movement for me.
    double weekly = 0;
    for (final e in weekExpenses) {
      final share = e.splitAmountFor(_userId);
      weekly += e.paidById == _userId ? e.amount - share : -share;
    }
    for (final s in settlements) {
      final at = s['createdAt'] as DateTime?;
      if (at == null || at.isBefore(weekStart)) continue;
      final amount = _settlementAmount(s);
      if (s['toUserId'] == _userId) weekly -= amount;
      if (s['fromUserId'] == _userId) weekly += amount;
    }

    final myNet = (balances[_userId] ?? 0) / 100.0;

    // Who owes whom, via the same minimised plan the Settle screen shows.
    final names = Map<String, String>.from(g.memberNames);
    final owedToMe = <String, double>{};
    for (final d in simplifyDebts(balances, names)) {
      if (d.toUserId == _userId) owedToMe[d.fromUserId] = d.amount;
      if (d.fromUserId == _userId) owedToMe[d.toUserId] = -d.amount;
    }

    DateTime? lastAt = g.lastActivityAt;
    String lastTitle = g.lastExpenseTitle ?? '';
    double totalSpent = (g.totalSpentMinor ?? 0) / 100.0;
    int count = g.expenseCount ?? 0;
    if (all != null) {
      totalSpent = 0;
      count = all.length;
      lastAt = null;
      for (final e in all) {
        totalSpent += e.amount;
        if (lastAt == null || e.createdAt.isAfter(lastAt)) {
          lastAt = e.createdAt;
          lastTitle = e.title;
        }
      }
    }
    for (final s in settlements) {
      final at = s['createdAt'] as DateTime?;
      if (at != null && (lastAt == null || at.isAfter(lastAt))) lastAt = at;
    }

    return _GroupSlice(
      group: g,
      myNet: myNet,
      recent: [
        for (final e in recentExpenses)
          RecentExpenseItem(
            expenseId: e.id,
            groupId: g.id,
            title: e.title,
            groupName: g.name,
            groupEmoji: g.emoji,
            amount: e.amount,
            isPaidByCurrentUser: e.paidById == _userId,
            paidByName: e.paidByName,
            createdAt: e.createdAt,
            category: e.category,
            currency: g.currency,
          ),
      ],
      weeklyDelta: weekly,
      meta: GroupMeta(
        totalSpent: totalSpent,
        expenseCount: count,
        lastExpenseTitle: lastTitle,
        lastActivityAt: lastAt,
      ),
      owedToMe: owedToMe,
      lastActivity: lastAt,
      settleDays: [
        for (final s in settlements)
          if (s['createdAt'] is DateTime &&
              (s['createdAt'] as DateTime).isAfter(g.createdAt))
            (s['createdAt'] as DateTime).difference(g.createdAt).inMinutes /
                1440.0,
      ],
    );
  }

  double _settlementAmount(Map<String, dynamic> s) {
    final paise = (s['amountPaise'] as num?)?.toInt();
    return paise != null
        ? paise / 100.0
        : (s['amount'] as num?)?.toDouble() ?? 0.0;
  }

  GroupsLoaded _assemble(
      List<_GroupSlice> slices, DateTime now, Map<String, double> toTarget) {
    final groups = [for (final s in slices) s.group];
    for (final s in slices) {
      s.group.netBalance = s.myNet;
    }

    // Cross-group totals are shown in the user's default currency; each
    // group's own balance stays in that group's currency.
    double rate(String c) => toTarget[c] ?? 1.0;

    final total =
        slices.fold<double>(0, (sum, s) => sum + s.myNet * rate(s.group.currency));
    final weeklyDelta = slices.fold<double>(
        0, (sum, s) => sum + s.weeklyDelta * rate(s.group.currency));

    // Open balances per person *and currency* — summing a USD debt into an INR
    // one would be meaningless.
    final byKey = <String, MemberBalanceItem>{};
    final byKeyAbs = <String, double>{};
    SmartNudgeData? nudge;
    int longestSilence = 0;
    for (final s in slices) {
      final cur = s.group.currency;
      final silent =
          s.lastActivity != null ? now.difference(s.lastActivity!).inDays : 0;
      s.owedToMe.forEach((uid, amount) {
        final key = '$uid|$cur';
        final prev = byKey[key];
        final net = (prev?.netBalance ?? 0) + amount;
        // Label the row with the group that contributes most.
        final dominant = amount.abs() >= (byKeyAbs[key] ?? 0);
        if (dominant) byKeyAbs[key] = amount.abs();
        byKey[key] = MemberBalanceItem(
          userId: uid,
          name: s.group.memberNames[uid] ?? prev?.name ?? 'Member',
          netBalance: net,
          currency: cur,
          groupName: dominant ? s.group.name : prev!.groupName,
          groupId: dominant ? s.group.id : prev!.groupId,
          daysSilent: dominant ? silent : prev!.daysSilent,
        );

        if (amount >= 10 && silent >= 5 && silent > longestSilence) {
          longestSilence = silent;
          nudge = SmartNudgeData(
            memberName: s.group.memberNames[uid] ?? 'Member',
            groupName: s.group.name,
            groupId: s.group.id,
            fromUserId: uid,
            amountOwed: amount,
            daysSilent: silent,
            currency: cur,
          );
        }
      });
    }
    final memberBalances = byKey.values
        .where((m) => m.netBalance.abs() >= 1)
        .toList()
      ..sort((a, b) => b.netBalance.abs().compareTo(a.netBalance.abs()));

    final recent = [for (final s in slices) ...s.recent]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final settleDays = [for (final s in slices) ...s.settleDays];
    final avgSettleDays = settleDays.isEmpty
        ? 0.0
        : settleDays.reduce((a, b) => a + b) / settleDays.length;

    return GroupsLoaded(
      groups: groups,
      totalNetBalance: total,
      weeklyDelta: weeklyDelta,
      smartNudge: nudge,
      memberBalances: memberBalances,
      avgSettleDays: avgSettleDays,
      recentExpenses: recent.take(5).toList(),
      groupMetas: {for (final s in slices) s.group.id: s.meta},
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
