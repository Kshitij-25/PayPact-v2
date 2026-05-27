import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/widgets/pp_atoms.dart';

part 'activity_state.dart';

class ActivityCubit extends Cubit<ActivityState> {
  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;

  ActivityCubit(this._groupRepo, this._expenseRepo) : super(ActivityInitial());

  Future<void> load(String userId) async {
    emit(ActivityLoading());
    try {
      final groups = await _groupRepo.watchUserGroups(userId).first;
      final groupNameMap = {for (final g in groups) g.id: g.name};
      final groupCategoryMap = {for (final g in groups) g.id: g.category};

      final cutoff = DateTime.now().subtract(const Duration(days: 60));
      final allItems = <ActivityItem>[];

      await Future.wait(groups.map((group) async {
        final expenses = await _expenseRepo.getGroupExpenses(group.id);
        for (final e in expenses) {
          if (e.createdAt.isBefore(cutoff)) continue;
          final isMe = e.paidById == userId || e.createdById == userId;
          final who = e.paidById == userId ? 'You' : e.paidByName;
          final myOwed = e.splitAmountFor(userId);
          final sub = (!isMe && myOwed > 0)
              ? 'you owe ₹${myOwed.toStringAsFixed(0)}'
              : null;
          allItems.add(ActivityItem(
            id: e.id,
            who: who,
            verb: 'added',
            what: e.title,
            where: groupNameMap[e.groupId],
            sub: sub,
            amount: e.amount,
            tone: e.paidById == userId
                ? 'neutral'
                : myOwed > 0
                    ? 'negative'
                    : 'neutral',
            icon: _categoryIcon(groupCategoryMap[e.groupId] ?? e.category),
            category: _ppCategory(groupCategoryMap[e.groupId] ?? e.category),
            createdAt: e.createdAt,
            expenseId: e.id,
            groupId: e.groupId,
          ));
        }
      }));

      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final Map<String, List<ActivityItem>> grouped = {};
      for (final item in allItems) {
        final d = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
        final String label;
        if (d == today) {
          label = 'TODAY';
        } else if (d == yesterday) {
          label = 'YESTERDAY';
        } else {
          label = DateFormat('MMM d').format(item.createdAt).toUpperCase();
        }
        grouped.putIfAbsent(label, () => []).add(item);
      }

      final days = grouped.entries
          .map((e) => (label: e.key, items: e.value))
          .toList();

      emit(ActivityLoaded(days));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

  IconData _categoryIcon(String cat) => switch (cat.toLowerCase()) {
        'food' || 'dining' => Icons.restaurant_outlined,
        'transport' || 'travel' => Icons.directions_car_outlined,
        'stay' || 'hotel' => Icons.hotel_outlined,
        'entertainment' => Icons.movie_outlined,
        'shopping' => Icons.shopping_bag_outlined,
        'groceries' => Icons.local_grocery_store_outlined,
        'health' => Icons.favorite_border_rounded,
        'utilities' => Icons.bolt_outlined,
        'trip' => Icons.flight_outlined,
        'home' => Icons.home_outlined,
        _ => Icons.receipt_long_outlined,
      };

  PpCategory _ppCategory(String cat) => switch (cat.toLowerCase()) {
        'food' || 'dining' => PpCategory.food,
        'transport' || 'travel' => PpCategory.transport,
        'stay' || 'hotel' => PpCategory.stay,
        'entertainment' => PpCategory.entertainment,
        'shopping' => PpCategory.shopping,
        'groceries' => PpCategory.groceries,
        'health' => PpCategory.health,
        'utilities' => PpCategory.utilities,
        'trip' => PpCategory.trip,
        'home' => PpCategory.home,
        _ => PpCategory.other,
      };
}
