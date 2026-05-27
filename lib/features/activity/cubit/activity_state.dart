part of 'activity_cubit.dart';

class ActivityItem {
  final String id;
  final String who;
  final String verb;
  final String what;
  final String? where;
  final String? sub;
  final double? amount;
  final String tone;
  final IconData icon;
  final PpCategory category;
  final DateTime createdAt;
  final String? expenseId;
  final String? groupId;

  const ActivityItem({
    required this.id,
    required this.who,
    required this.verb,
    required this.what,
    this.where,
    this.sub,
    this.amount,
    required this.tone,
    required this.icon,
    required this.category,
    required this.createdAt,
    required this.expenseId,
    required this.groupId,
  });
}

abstract class ActivityState {}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivityLoaded extends ActivityState {
  final List<({String label, List<ActivityItem> items})> days;
  ActivityLoaded(this.days);
}

class ActivityError extends ActivityState {
  final String message;
  ActivityError(this.message);
}
