import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'insights_state.dart';

class _MemberData {
  _MemberData({required this.name, required this.firstExpenseDate});
  final String name;
  double totalOwed = 0;
  double totalSettled = 0;
  int settlementCount = 0;
  DateTime firstExpenseDate;
}

class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit(this._groupRepo, this._expenseRepo, this._userId)
      : super(const InsightsLoading());

  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;
  final String _userId;

  // ── Date helpers ─────────────────────────────────────────────────────────────

  static DateTime _monthFirstDay(DateTime ref, int monthOffset) {
    final total = ref.year * 12 + ref.month - 1 + monthOffset;
    return DateTime(total ~/ 12, (total % 12) + 1, 1);
  }

  (DateTime, DateTime) _periodRange(InsightsPeriod period) {
    final now = DateTime.now();
    return switch (period) {
      InsightsPeriod.week => (
          DateTime(now.year, now.month, now.day - (now.weekday - 1)),
          now
        ),
      InsightsPeriod.month => (_monthFirstDay(now, 0), now),
      InsightsPeriod.threeMonths => (_monthFirstDay(now, -2), now),
      InsightsPeriod.year => (DateTime(now.year, 1, 1), now),
    };
  }

  (DateTime, DateTime) _prevPeriodRange(InsightsPeriod period) {
    final now = DateTime.now();
    return switch (period) {
      InsightsPeriod.week => (
          DateTime(now.year, now.month, now.day - (now.weekday - 1) - 7),
          DateTime(now.year, now.month, now.day - (now.weekday - 1))
              .subtract(const Duration(seconds: 1)),
        ),
      InsightsPeriod.month => (
          _monthFirstDay(now, -1),
          _monthFirstDay(now, 0).subtract(const Duration(seconds: 1)),
        ),
      InsightsPeriod.threeMonths => (
          _monthFirstDay(now, -5),
          _monthFirstDay(now, -2).subtract(const Duration(seconds: 1)),
        ),
      InsightsPeriod.year => (
          DateTime(now.year - 1, 1, 1),
          DateTime(now.year - 1, 12, 31, 23, 59, 59),
        ),
    };
  }

  // ── Bucket helpers ────────────────────────────────────────────────────────────

  int _bucketCount(InsightsPeriod period) => switch (period) {
        InsightsPeriod.week => 7,
        InsightsPeriod.month => 4,
        InsightsPeriod.threeMonths => 3,
        InsightsPeriod.year => 12,
      };

  int _bucketIndex(ExpenseEntity e, InsightsPeriod period) {
    final date = e.createdAt;
    final now = DateTime.now();
    return switch (period) {
      InsightsPeriod.week => (date.weekday - 1).clamp(0, 6),
      InsightsPeriod.month => ((date.day - 1) ~/ 7).clamp(0, 3),
      InsightsPeriod.threeMonths => (() {
          final startMonth = _monthFirstDay(now, -2);
          final offset = (date.year * 12 + date.month) -
              (startMonth.year * 12 + startMonth.month);
          return offset.clamp(0, 2);
        })(),
      InsightsPeriod.year => (date.month - 1).clamp(0, 11),
    };
  }

  List<String> _periodLabels(InsightsPeriod period) {
    const monthAbbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return switch (period) {
      InsightsPeriod.week => ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      InsightsPeriod.month => ['W1', 'W2', 'W3', 'W4'],
      InsightsPeriod.threeMonths => [
          monthAbbr[_monthFirstDay(now, -2).month - 1],
          monthAbbr[_monthFirstDay(now, -1).month - 1],
          monthAbbr[now.month - 1],
        ],
      InsightsPeriod.year => monthAbbr,
    };
  }

  // ── Filter label ──────────────────────────────────────────────────────────────

  String _filterLabel(InsightsPeriod period, int groupCount) {
    const monthNames = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final now = DateTime.now();
    final g = '$groupCount GROUP${groupCount == 1 ? '' : 'S'}';
    return switch (period) {
      InsightsPeriod.week => 'THIS WEEK · YOU + $g',
      InsightsPeriod.month => () {
          final days = DateTime(now.year, now.month + 1, 0).day;
          return '${monthNames[now.month - 1]} · $days DAYS · YOU + $g';
        }(),
      InsightsPeriod.threeMonths => 'LAST 3 MONTHS · YOU + $g',
      InsightsPeriod.year => '${now.year} · YOU + $g',
    };
  }

  // ── Main load ─────────────────────────────────────────────────────────────────

  Future<void> loadInsights(InsightsPeriod period) async {
    emit(const InsightsLoading());
    try {
      final groups = await _groupRepo.watchUserGroups(_userId).first;

      final results = await Future.wait(
        groups.map((g) async {
          final expenses = await _expenseRepo.getGroupExpenses(g.id);
          final settlements = await _expenseRepo.getGroupSettlements(g.id);
          return (g, expenses, settlements);
        }),
      );

      final (currentStart, currentEnd) = _periodRange(period);
      final (prevStart, prevEnd) = _prevPeriodRange(period);

      double yourShare = 0;
      double totalSpent = 0;
      double prevShare = 0;
      final Map<String, double> categoryTotals = {};
      final buckets = List.filled(_bucketCount(period), 0.0);
      final Map<String, _MemberData> memberData = {};

      for (final (group, expenses, settlements) in results) {
        for (final e in expenses) {
          final inCurrent =
              !e.createdAt.isBefore(currentStart) && !e.createdAt.isAfter(currentEnd);
          final inPrev =
              !e.createdAt.isBefore(prevStart) && !e.createdAt.isAfter(prevEnd);

          if (inCurrent) {
            final myShare = e.splitAmountFor(_userId);
            yourShare += myShare;
            totalSpent += e.amount;
            categoryTotals[e.category] =
                (categoryTotals[e.category] ?? 0) + myShare;
            buckets[_bucketIndex(e, period)] += myShare;
          }
          if (inPrev) {
            prevShare += e.splitAmountFor(_userId);
          }

          // Track what each other member owes me (all time, for velocity)
          if (e.paidById == _userId) {
            for (final split in e.splits) {
              if (split.userId != _userId && split.amount > 0) {
                final md = memberData.putIfAbsent(
                  split.userId,
                  () => _MemberData(
                    name: group.memberNames[split.userId] ?? 'Member',
                    firstExpenseDate: e.createdAt,
                  ),
                );
                md.totalOwed += split.amount;
                if (e.createdAt.isBefore(md.firstExpenseDate)) {
                  md.firstExpenseDate = e.createdAt;
                }
              }
            }
          }
        }

        for (final s in settlements) {
          final fromId = s['fromUserId'] as String? ?? '';
          final toId = s['toUserId'] as String? ?? '';
          final amount = (s['amount'] as num?)?.toDouble() ?? 0.0;
          if (toId == _userId && fromId.isNotEmpty && memberData.containsKey(fromId)) {
            memberData[fromId]!.totalSettled += amount;
            memberData[fromId]!.settlementCount++;
          }
        }
      }

      // ── Categories ───────────────────────────────────────────────────────────
      final catTotal = categoryTotals.values.fold(0.0, (a, b) => a + b);
      final categories = categoryTotals.entries
          .where((e) => e.value > 0)
          .map((e) => InsightsCategoryData(
                categoryKey: e.key,
                amount: e.value,
                fraction: catTotal > 0 ? e.value / catTotal : 0,
              ))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      // ── Flow bars ────────────────────────────────────────────────────────────
      final peak = buckets.isEmpty ? 0.0 : buckets.reduce(math.max);
      final peakIndex = peak > 0 ? buckets.indexWhere((v) => v == peak) : 0;
      final labels = _periodLabels(period);
      final flowBars = List.generate(
        buckets.length,
        (i) => InsightsBarData(labels[i], buckets[i]),
      );

      // ── People velocity ──────────────────────────────────────────────────────
      final people = memberData.values
          .where((md) => md.totalOwed > 0)
          .map((md) {
            final velocity = math.min(1.0, md.totalSettled / md.totalOwed);
            double? avgDays;
            if (md.settlementCount > 0) {
              final elapsed =
                  DateTime.now().difference(md.firstExpenseDate).inDays;
              avgDays = (elapsed / md.settlementCount).roundToDouble();
            }
            return InsightsPersonData(
              name: md.name,
              velocity: velocity,
              avgDays: avgDays,
            );
          })
          .toList()
        ..sort((a, b) => b.velocity.compareTo(a.velocity));

      final symbol = groups.isNotEmpty ? currencySymbol(groups.first.currency) : '₹';

      emit(InsightsLoaded(
        filterLabel: _filterLabel(period, groups.length),
        totalSpent: totalSpent,
        yourShare: yourShare,
        prevShare: prevShare > 0 ? prevShare : null,
        currencySymbol: symbol,
        flowBars: flowBars,
        peakBarIndex: peakIndex,
        categories: categories.take(6).toList(),
        people: people.take(5).toList(),
      ));
    } catch (e) {
      emit(InsightsError(e.toString()));
    }
  }
}
