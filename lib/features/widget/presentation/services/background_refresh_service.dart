import 'package:flutter/services.dart';

/// Service for managing background widget refresh
class BackgroundRefreshService {
  static const MethodChannel _channel = MethodChannel('com.family.financetracker/widget');

  /// Register periodic background refresh (15-minute intervals)
  static Future<void> registerBackgroundRefresh() async {
    try {
      await _channel.invokeMethod('registerBackgroundRefresh');
    } on PlatformException catch (e) {
      print('Failed to register background refresh: ${e.message}');
    }
  }

  /// Cancel background refresh
  static Future<void> cancelBackgroundRefresh() async {
    try {
      await _channel.invokeMethod('cancelBackgroundRefresh');
    } on PlatformException catch (e) {
      print('Failed to cancel background refresh: ${e.message}');
    }
  }
}
