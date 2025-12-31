import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/widget_repository.dart';
import '../providers/widget_provider.dart';

/// Service for triggering widget updates from various parts of the app
class WidgetUpdateService {
  WidgetUpdateService(this._widgetRepository);

  final WidgetRepository _widgetRepository;

  /// Trigger widget update
  /// This should be called after any expense operation (create, update, delete)
  Future<void> triggerUpdate() async {
    await _widgetRepository.updateWidget();
  }

  /// Register background refresh job
  Future<void> enableBackgroundRefresh() async {
    await _widgetRepository.registerBackgroundRefresh();
  }

  /// Cancel background refresh job
  Future<void> disableBackgroundRefresh() async {
    await _widgetRepository.cancelBackgroundRefresh();
  }
}

/// Provider for widget update service
final widgetUpdateServiceProvider = Provider<WidgetUpdateService>((ref) {
  return WidgetUpdateService(ref.watch(widgetRepositoryProvider));
});
