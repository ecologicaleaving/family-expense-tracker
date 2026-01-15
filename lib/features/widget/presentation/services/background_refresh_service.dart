import 'package:flutter/services.dart';

/// Service for managing background widget refresh
class BackgroundRefreshService {
  static const MethodChannel _channel = MethodChannel('com.ecologicaleaving.fin/widget');

  /// Setup listener for widget lifecycle events
  static void setupWidgetListener(Function() onWidgetEnabled) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetEnabled') {
        print('BackgroundRefreshService: Widget enabled event received');
        onWidgetEnabled();
      }
    });
  }

  /// Register periodic background refresh (30-minute intervals)
  static Future<void> registerBackgroundRefresh() async {
    try {
      print('BackgroundRefreshService: Registering background refresh');
      await _channel.invokeMethod('registerBackgroundRefresh');
      print('BackgroundRefreshService: Background refresh registered successfully');
    } on PlatformException catch (e) {
      print('Failed to register background refresh: ${e.message}');
    }
  }

  /// Cancel background refresh
  static Future<void> cancelBackgroundRefresh() async {
    try {
      print('BackgroundRefreshService: Cancelling background refresh');
      await _channel.invokeMethod('cancelBackgroundRefresh');
      print('BackgroundRefreshService: Background refresh cancelled successfully');
    } on PlatformException catch (e) {
      print('Failed to cancel background refresh: ${e.message}');
    }
  }
}
