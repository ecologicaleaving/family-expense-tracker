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

      // 2. Calculate all user expenses (personal + group) for current month
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Query all expenses created by user (both personal and group) for current month
      final allExpensesResult = await supabase
          .from('expenses')
          .select('amount')
          .eq('created_by', userId)
          .gte('date', startOfMonth.toIso8601String().split('T')[0])
          .lte('date', endOfMonth.toIso8601String().split('T')[0]) as List;

      // Calculate total expenses (personal + group)
      double totalExpenses = 0.0;
      for (final expense in allExpensesResult) {
        totalExpenses += (expense['amount'] as num).toDouble();
      }

      // 3. Get total income from income sources
      final incomeSourcesResult = await supabase
          .from('income_sources')
          .select('amount')
          .eq('user_id', userId) as List;

      // Calculate total income (amount is stored in cents)
      double totalIncome = 0.0;
      for (final source in incomeSourcesResult) {
        final amountCents = source['amount'] as int;
        totalIncome += amountCents / 100.0; // Convert cents to euros
      }

      // If no income sources, use default value to avoid division by zero
      if (totalIncome == 0) {
        totalIncome = 1000.0; // Default fallback
      }

      // 4. Get current theme
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isDarkMode = brightness == Brightness.dark;

      // 5. Build widget data entity
      final widgetData = WidgetDataEntity(
        spent: totalExpenses, // All expenses (personal + group)
        limit: totalIncome, // Total income
        month: DateFormat('MMMM yyyy', 'it').format(DateTime.now()),
        currency: '€',
        isDarkMode: isDarkMode,
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
