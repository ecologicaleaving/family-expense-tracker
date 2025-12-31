import 'package:equatable/equatable.dart';

/// Widget size options
enum WidgetSize {
  small, // 2x2 cells Android, compact iOS
  medium, // 4x2 cells Android, medium iOS
  large, // 4x4 cells Android, large iOS
}

/// Entity representing user preferences for widget behavior and appearance
class WidgetConfigEntity extends Equatable {
  final WidgetSize size;
  final Duration refreshInterval;
  final bool showAmounts;
  final bool enableBackgroundRefresh;

  const WidgetConfigEntity({
    this.size = WidgetSize.medium,
    this.refreshInterval = const Duration(minutes: 30),
    this.showAmounts = true,
    this.enableBackgroundRefresh = true,
  });

  /// Validate refresh interval is within allowed bounds
  bool get isValidRefreshInterval {
    final minutes = refreshInterval.inMinutes;
    return minutes >= 15 && minutes <= 60;
  }

  @override
  List<Object?> get props => [
        size,
        refreshInterval,
        showAmounts,
        enableBackgroundRefresh,
      ];
}
