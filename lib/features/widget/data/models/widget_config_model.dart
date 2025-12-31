import 'dart:convert';
import '../../domain/entities/widget_config_entity.dart';

/// Serializable version of WidgetConfigEntity
class WidgetConfigModel extends WidgetConfigEntity {
  const WidgetConfigModel({
    WidgetSize size = WidgetSize.medium,
    Duration refreshInterval = const Duration(minutes: 30),
    bool showAmounts = true,
    bool enableBackgroundRefresh = true,
  }) : super(
          size: size,
          refreshInterval: refreshInterval,
          showAmounts: showAmounts,
          enableBackgroundRefresh: enableBackgroundRefresh,
        );

  /// Create model from entity
  factory WidgetConfigModel.fromEntity(WidgetConfigEntity entity) {
    return WidgetConfigModel(
      size: entity.size,
      refreshInterval: entity.refreshInterval,
      showAmounts: entity.showAmounts,
      enableBackgroundRefresh: entity.enableBackgroundRefresh,
    );
  }

  /// Create model from JSON
  factory WidgetConfigModel.fromJson(Map<String, dynamic> json) {
    return WidgetConfigModel(
      size: WidgetSize.values.firstWhere(
        (e) => e.toString() == 'WidgetSize.${json['size']}',
        orElse: () => WidgetSize.medium,
      ),
      refreshInterval:
          Duration(milliseconds: json['refreshInterval'] as int? ?? 1800000),
      showAmounts: json['showAmounts'] as bool? ?? true,
      enableBackgroundRefresh:
          json['enableBackgroundRefresh'] as bool? ?? true,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'size': size.name,
      'refreshInterval': refreshInterval.inMilliseconds,
      'showAmounts': showAmounts,
      'enableBackgroundRefresh': enableBackgroundRefresh,
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create model from JSON string
  factory WidgetConfigModel.fromJsonString(String jsonString) {
    return WidgetConfigModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
