import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/widget_config_model.dart';
import '../models/widget_data_model.dart';
import 'widget_local_datasource.dart';

/// Implementation of WidgetLocalDataSource using SharedPreferences and home_widget plugin
class WidgetLocalDataSourceImpl implements WidgetLocalDataSource {
  final SharedPreferences sharedPreferences;
  final MethodChannel? platformChannel;

  static const String _widgetDataKey = 'widget_data';
  static const String _widgetConfigKey = 'widget_config';
  static const String _appGroupSuiteName = 'group.com.family.financetracker';

  WidgetLocalDataSourceImpl({
    required this.sharedPreferences,
    this.platformChannel,
  });

  @override
  Future<void> saveWidgetData(WidgetDataModel data) async {
    final jsonString = data.toJsonString();

    // Save to Flutter SharedPreferences
    await sharedPreferences.setString(_widgetDataKey, jsonString);

    // iOS: Also save to App Group UserDefaults via MethodChannel
    if (Platform.isIOS && platformChannel != null) {
      try {
        await platformChannel!.invokeMethod('saveWidgetData', {
          'data': jsonString,
        });
      } catch (e) {
        // Log error but don't throw - this is a non-critical operation
        print('Failed to save to iOS App Group: $e');
      }
    }
  }

  @override
  Future<WidgetDataModel?> getCachedWidgetData() async {
    final jsonString = sharedPreferences.getString(_widgetDataKey);
    if (jsonString == null) return null;

    try {
      return WidgetDataModel.fromJsonString(jsonString);
    } catch (e) {
      print('Failed to parse cached widget data: $e');
      return null;
    }
  }

  @override
  Future<void> saveWidgetConfig(WidgetConfigModel config) async {
    final jsonString = config.toJsonString();
    await sharedPreferences.setString(_widgetConfigKey, jsonString);
  }

  @override
  Future<WidgetConfigModel?> getWidgetConfig() async {
    final jsonString = sharedPreferences.getString(_widgetConfigKey);
    if (jsonString == null) return null;

    try {
      return WidgetConfigModel.fromJsonString(jsonString);
    } catch (e) {
      print('Failed to parse widget config: $e');
      return null;
    }
  }

  @override
  Future<void> updateNativeWidget(WidgetDataModel data) async {
    // Save each field individually for native widget access
    await HomeWidget.saveWidgetData<double>('spent', data.spent);
    await HomeWidget.saveWidgetData<double>('limit', data.limit);
    await HomeWidget.saveWidgetData<String>('month', data.month);
    await HomeWidget.saveWidgetData<double>('percentage', data.percentage);
    await HomeWidget.saveWidgetData<String>('currency', data.currency);
    await HomeWidget.saveWidgetData<bool>('isDarkMode', data.isDarkMode);
    await HomeWidget.saveWidgetData<int>(
      'lastUpdated',
      data.lastUpdated.millisecondsSinceEpoch,
    );
    await HomeWidget.saveWidgetData<String>('groupName', data.groupName ?? '');

    // Trigger widget update
    await HomeWidget.updateWidget(
      androidName: 'BudgetWidgetProvider',
      iOSName: 'BudgetWidget',
    );
  }
}
