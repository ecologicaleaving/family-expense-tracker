import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/datasources/widget_local_datasource.dart';
import '../../data/datasources/widget_local_datasource_impl.dart';
import '../../data/repositories/widget_repository_impl.dart';
import '../../domain/entities/widget_config_entity.dart';
import '../../domain/entities/widget_data_entity.dart';
import '../../domain/repositories/widget_repository.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for widget local data source
final widgetLocalDataSourceProvider = Provider<WidgetLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WidgetLocalDataSourceImpl(
    sharedPreferences: prefs,
    platformChannel: null, // TODO: Initialize for iOS
  );
});

/// Provider for widget repository
final widgetRepositoryProvider = Provider<WidgetRepository>((ref) {
  return WidgetRepositoryImpl(
    localDataSource: ref.watch(widgetLocalDataSourceProvider),
    dashboardRepository: ref.watch(dashboardRepositoryProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Widget update state status
enum WidgetUpdateStatus {
  initial,
  updating,
  success,
  error,
}

/// Widget update state class
class WidgetUpdateState {
  const WidgetUpdateState({
    this.status = WidgetUpdateStatus.initial,
    this.data,
    this.errorMessage,
  });

  final WidgetUpdateStatus status;
  final WidgetDataEntity? data;
  final String? errorMessage;

  WidgetUpdateState copyWith({
    WidgetUpdateStatus? status,
    WidgetDataEntity? data,
    String? errorMessage,
  }) {
    return WidgetUpdateState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  bool get isUpdating => status == WidgetUpdateStatus.updating;
  bool get hasError => status == WidgetUpdateStatus.error;
  bool get hasData => data != null;
}

/// Widget update notifier
class WidgetUpdateNotifier extends StateNotifier<WidgetUpdateState> {
  WidgetUpdateNotifier(this._widgetRepository) : super(const WidgetUpdateState());

  final WidgetRepository _widgetRepository;

  /// Update widget with latest data
  Future<void> updateWidget() async {
    if (!mounted) return;

    state = state.copyWith(
      status: WidgetUpdateStatus.updating,
      errorMessage: null,
    );

    final result = await _widgetRepository.updateWidget();

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          status: WidgetUpdateStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) async {
        // Get the updated data to store in state
        final dataResult = await _widgetRepository.getWidgetData();
        if (!mounted) return;

        dataResult.fold(
          (failure) {
            state = state.copyWith(
              status: WidgetUpdateStatus.error,
              errorMessage: failure.message,
            );
          },
          (data) {
            state = state.copyWith(
              status: WidgetUpdateStatus.success,
              data: data,
            );
          },
        );
      },
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset state
  void reset() {
    state = const WidgetUpdateState();
  }
}

/// Provider for widget update state
final widgetUpdateProvider =
    StateNotifierProvider<WidgetUpdateNotifier, WidgetUpdateState>((ref) {
  // Refresh when auth changes
  ref.watch(authProvider);
  return WidgetUpdateNotifier(ref.watch(widgetRepositoryProvider));
});

/// Widget configuration state status
enum WidgetConfigStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
}

/// Widget configuration state class
class WidgetConfigState {
  const WidgetConfigState({
    this.status = WidgetConfigStatus.initial,
    this.config,
    this.errorMessage,
  });

  final WidgetConfigStatus status;
  final WidgetConfigEntity? config;
  final String? errorMessage;

  WidgetConfigState copyWith({
    WidgetConfigStatus? status,
    WidgetConfigEntity? config,
    String? errorMessage,
  }) {
    return WidgetConfigState(
      status: status ?? this.status,
      config: config ?? this.config,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == WidgetConfigStatus.loading;
  bool get isSaving => status == WidgetConfigStatus.saving;
  bool get hasError => status == WidgetConfigStatus.error;
  bool get hasConfig => config != null;
}

/// Widget configuration notifier
class WidgetConfigNotifier extends StateNotifier<WidgetConfigState> {
  WidgetConfigNotifier(this._widgetRepository) : super(const WidgetConfigState());

  final WidgetRepository _widgetRepository;

  /// Load widget configuration
  Future<void> loadConfig() async {
    if (!mounted) return;
    if (state.isLoading) return;

    state = state.copyWith(
      status: WidgetConfigStatus.loading,
      errorMessage: null,
    );

    final result = await _widgetRepository.getWidgetConfig();

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          status: WidgetConfigStatus.error,
          errorMessage: failure.message,
        );
      },
      (config) {
        state = state.copyWith(
          status: WidgetConfigStatus.loaded,
          config: config,
        );
      },
    );
  }

  /// Save widget configuration
  Future<void> saveConfig(WidgetConfigEntity config) async {
    if (!mounted) return;

    state = state.copyWith(
      status: WidgetConfigStatus.saving,
      errorMessage: null,
    );

    final result = await _widgetRepository.saveWidgetConfig(config);

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          status: WidgetConfigStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          status: WidgetConfigStatus.loaded,
          config: config,
        );
      },
    );
  }

  /// Update widget size
  Future<void> updateSize(WidgetSize size) async {
    if (state.config == null) return;
    await saveConfig(WidgetConfigEntity(
      size: size,
      refreshInterval: state.config!.refreshInterval,
      showAmounts: state.config!.showAmounts,
      enableBackgroundRefresh: state.config!.enableBackgroundRefresh,
    ));
  }

  /// Update refresh interval
  Future<void> updateRefreshInterval(Duration interval) async {
    if (state.config == null) return;
    await saveConfig(WidgetConfigEntity(
      size: state.config!.size,
      refreshInterval: interval,
      showAmounts: state.config!.showAmounts,
      enableBackgroundRefresh: state.config!.enableBackgroundRefresh,
    ));
  }

  /// Toggle show amounts
  Future<void> toggleShowAmounts() async {
    if (state.config == null) return;
    await saveConfig(WidgetConfigEntity(
      size: state.config!.size,
      refreshInterval: state.config!.refreshInterval,
      showAmounts: !state.config!.showAmounts,
      enableBackgroundRefresh: state.config!.enableBackgroundRefresh,
    ));
  }

  /// Toggle background refresh
  Future<void> toggleBackgroundRefresh() async {
    if (state.config == null) return;
    final newValue = !state.config!.enableBackgroundRefresh;

    await saveConfig(WidgetConfigEntity(
      size: state.config!.size,
      refreshInterval: state.config!.refreshInterval,
      showAmounts: state.config!.showAmounts,
      enableBackgroundRefresh: newValue,
    ));

    // Register or cancel background refresh based on new value
    if (newValue) {
      await _widgetRepository.registerBackgroundRefresh();
    } else {
      await _widgetRepository.cancelBackgroundRefresh();
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for widget configuration state
final widgetConfigProvider =
    StateNotifierProvider<WidgetConfigNotifier, WidgetConfigState>((ref) {
  final notifier = WidgetConfigNotifier(ref.watch(widgetRepositoryProvider));
  // Auto-load config on creation
  Future.microtask(() => notifier.loadConfig());
  return notifier;
});

/// Convenience provider for current widget data
final currentWidgetDataProvider = FutureProvider<WidgetDataEntity?>((ref) async {
  final repository = ref.watch(widgetRepositoryProvider);
  final result = await repository.getWidgetData();
  return result.fold((_) => null, (data) => data);
});

/// Convenience provider for widget configuration
final currentWidgetConfigProvider = Provider<WidgetConfigEntity?>((ref) {
  return ref.watch(widgetConfigProvider).config;
});
