import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Entity representing the current state of the widget displayed on the home screen
class WidgetDataEntity extends Equatable {
  final double spent;
  final double limit;
  final String month;
  final String currency;
  final bool isDarkMode;
  final DateTime lastUpdated;
  final String groupId;
  final String? groupName;

  const WidgetDataEntity({
    required this.spent,
    required this.limit,
    required this.month,
    this.currency = '€',
    required this.isDarkMode,
    required this.lastUpdated,
    required this.groupId,
    this.groupName,
  });

  /// Calculate percentage of budget used
  double get percentage => (spent / limit) * 100;

  /// Format spent amount with currency
  String get formattedSpent => '$currency${spent.toStringAsFixed(2)}';

  /// Format limit amount with currency
  String get formattedLimit => '$currency${limit.toStringAsFixed(0)}';

  /// Display text for widget: "€450.00 / €800 (56%)"
  String get displayText =>
      '$formattedSpent / $formattedLimit (${percentage.toStringAsFixed(0)}%)';

  /// Is budget in warning state (80-99% used)
  bool get isWarning => percentage >= 80 && percentage < 100;

  /// Is budget in critical state (>=100% used)
  bool get isCritical => percentage >= 100;

  /// Is data stale (last updated more than 5 minutes ago)
  bool get isStale => DateTime.now().difference(lastUpdated).inMinutes > 5;

  @override
  List<Object?> get props => [
        spent,
        limit,
        month,
        currency,
        isDarkMode,
        lastUpdated,
        groupId,
        groupName,
      ];
}
