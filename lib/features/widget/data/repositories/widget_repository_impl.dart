import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../dashboard/domain/entities/dashboard_stats_entity.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../domain/entities/widget_config_entity.dart';
import '../../domain/entities/widget_data_entity.dart';
import '../../domain/repositories/widget_repository.dart';
import '../../presentation/services/background_refresh_service.dart';
import '../datasources/widget_local_datasource.dart';
import '../models/widget_config_model.dart';
import '../models/widget_data_model.dart';

/// Concrete implementation of WidgetRepository
class WidgetRepositoryImpl implements WidgetRepository {
  final WidgetLocalDataSource localDataSource;
  final DashboardRepository dashboardRepository;
  final AuthRepository authRepository;

  WidgetRepositoryImpl({
    required this.localDataSource,
    required this.dashboardRepository,
    required this.authRepository,
  });

  @override
  Future<Either<Failure, WidgetDataEntity>> getWidgetData() async {
    try {
      // 1. Get current user
      final userResult = await authRepository.getCurrentUser();
      if (userResult.isLeft()) {
        return const Left(AuthFailure('User not authenticated'));
      }

      final user = userResult.getOrElse(() => throw Exception('Unexpected'));
      final userId = user.id;
      final groupId = user.groupId;

      if (groupId == null) {
        return const Left(CacheFailure('User not in a group'));
      }

      // 2. Calculate personal expenses (created_by = userId) for current month
      // Feature 001: Widget displays only personal expenses, not all group expenses
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Query personal expenses created by user for current month
      final personalExpensesResult = await supabase
          .from('expenses')
          .select('id, amount')
          .eq('created_by', userId)
          .gte('date', startOfMonth.toIso8601String().split('T')[0])
          .lte('date', endOfMonth.toIso8601String().split('T')[0]) as List;

      // Calculate total amount and count of personal expenses
      double totalAmount = 0.0;
      int expenseCount = personalExpensesResult.length;

      for (final expense in personalExpensesResult) {
        totalAmount += (expense['amount'] as num).toDouble();
      }

      // 3. Get current theme
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isDarkMode = brightness == Brightness.dark;

      // 4. Build widget data entity with new format
      final widgetData = WidgetDataEntity(
        totalAmount: totalAmount, // Sum of personal expenses
        expenseCount: expenseCount, // Number of personal expenses
        month: DateFormat('MMMM yyyy', 'it').format(DateTime.now()),
        currency: '€',
        isDarkMode: isDarkMode,
        hasError: false,
        lastUpdated: DateTime.now(),
        groupId: groupId,
        groupName: null,
      );

      return Right(widgetData);
    } on ServerFailure catch (e) {
      return Left(e);
    } on NetworkFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get widget data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveWidgetData(WidgetDataEntity data) async {
    try {
      final model = WidgetDataModel.fromEntity(data);
      await localDataSource.saveWidgetData(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save widget data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateWidget() async {
    try {
      // 1. Get widget data
      final dataResult = await getWidgetData();
      if (dataResult.isLeft()) {
        return Left(dataResult.fold((l) => l, (r) => throw Exception('Unexpected')));
      }

      final data = dataResult.getOrElse(() => throw Exception('Unexpected'));

      // 2. Save to local storage
      await saveWidgetData(data);

      // 3. Trigger native widget update
      final model = WidgetDataModel.fromEntity(data);
      await localDataSource.updateNativeWidget(model);

      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to update widget: $e'));
    }
  }

  @override
  Future<Either<Failure, WidgetConfigEntity>> getWidgetConfig() async {
    try {
      final config = await localDataSource.getWidgetConfig();
      return Right(config ?? const WidgetConfigModel());
    } catch (e) {
      return Left(CacheFailure('Failed to get widget config: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveWidgetConfig(WidgetConfigEntity config) async {
    try {
      final model = WidgetConfigModel.fromEntity(config);
      await localDataSource.saveWidgetConfig(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save widget config: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> registerBackgroundRefresh() async {
    try {
      await BackgroundRefreshService.registerBackgroundRefresh();
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to register background refresh: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBackgroundRefresh() async {
    try {
      await BackgroundRefreshService.cancelBackgroundRefresh();
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure('Failed to cancel background refresh: $e'));
    }
  }
}
