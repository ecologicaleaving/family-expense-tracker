import 'dart:convert';
import '../../domain/entities/widget_data_entity.dart';

/// Serializable version of WidgetDataEntity for persistence and API communication
class WidgetDataModel extends WidgetDataEntity {
  const WidgetDataModel({
    required double spent,
    required double limit,
    required String month,
    String currency = '€',
    required bool isDarkMode,
    required DateTime lastUpdated,
    required String groupId,
    String? groupName,
  }) : super(
          spent: spent,
          limit: limit,
          month: month,
          currency: currency,
          isDarkMode: isDarkMode,
          lastUpdated: lastUpdated,
          groupId: groupId,
          groupName: groupName,
        );

  /// Create model from entity
  factory WidgetDataModel.fromEntity(WidgetDataEntity entity) {
    return WidgetDataModel(
      spent: entity.spent,
      limit: entity.limit,
      month: entity.month,
      currency: entity.currency,
      isDarkMode: entity.isDarkMode,
      lastUpdated: entity.lastUpdated,
      groupId: entity.groupId,
      groupName: entity.groupName,
    );
  }

  /// Create model from JSON
  factory WidgetDataModel.fromJson(Map<String, dynamic> json) {
    return WidgetDataModel(
      spent: (json['spent'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
      month: json['month'] as String,
      currency: (json['currency'] as String?) ?? '€',
      isDarkMode: json['isDarkMode'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String?,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'spent': spent,
      'limit': limit,
      'month': month,
      'currency': currency,
      'isDarkMode': isDarkMode,
      'lastUpdated': lastUpdated.toIso8601String(),
      'groupId': groupId,
      'groupName': groupName,
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create model from JSON string
  factory WidgetDataModel.fromJsonString(String jsonString) {
    return WidgetDataModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
