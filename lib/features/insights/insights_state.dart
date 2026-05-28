part of 'insights_cubit.dart';

enum InsightsPeriod { week, month, threeMonths, year }

class InsightsBarData {
  const InsightsBarData(this.label, this.amount);
  final String label;
  final double amount;
}

class InsightsCategoryData {
  const InsightsCategoryData({
    required this.categoryKey,
    required this.amount,
    required this.fraction,
  });
  final String categoryKey;
  final double amount;
  final double fraction;
}

class InsightsPersonData {
  const InsightsPersonData({
    required this.name,
    required this.velocity,
    this.avgDays,
  });
  final String name;
  final double velocity; // 0–1, fraction of owed amount settled
  final double? avgDays; // null = never settled
}

sealed class InsightsState {
  const InsightsState();
}

final class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

final class InsightsLoaded extends InsightsState {
  const InsightsLoaded({
    required this.filterLabel,
    required this.totalSpent,
    required this.yourShare,
    this.prevShare,
    required this.currencySymbol,
    required this.flowBars,
    required this.peakBarIndex,
    required this.categories,
    required this.people,
  });

  final String filterLabel;
  final double totalSpent;
  final double yourShare;
  final double? prevShare;
  final String currencySymbol;
  final List<InsightsBarData> flowBars;
  final int peakBarIndex;
  final List<InsightsCategoryData> categories;
  final List<InsightsPersonData> people;
}

final class InsightsError extends InsightsState {
  const InsightsError(this.message);
  final String message;
}
