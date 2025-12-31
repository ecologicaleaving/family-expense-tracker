import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/widget_config_entity.dart';
import '../entities/widget_data_entity.dart';

/// Abstract interface for widget data operations
abstract class WidgetRepository {
  /// Fetch current budget data and prepare widget update
  Future<Either<Failure, WidgetDataEntity>> getWidgetData();

  /// Save widget data to local storage for native widget access
  Future<Either<Failure, void>> saveWidgetData(WidgetDataEntity data);

  /// Trigger native widget refresh
  Future<Either<Failure, void>> updateWidget();

  /// Get widget configuration
  Future<Either<Failure, WidgetConfigEntity>> getWidgetConfig();

  /// Save widget configuration
  Future<Either<Failure, void>> saveWidgetConfig(WidgetConfigEntity config);

  /// Register background refresh job (Android WorkManager / iOS Timeline)
  Future<Either<Failure, void>> registerBackgroundRefresh();

  /// Cancel background refresh job
  Future<Either<Failure, void>> cancelBackgroundRefresh();
}
