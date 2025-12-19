import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../models/dashboard_stats_model.dart';

/// Remote data source for dashboard statistics.
/// Calls the dashboard-stats Edge Function.
abstract class DashboardRemoteDataSource {
  /// Fetches dashboard statistics from the Edge Function.
  Future<DashboardStatsModel> getStats({
    required String groupId,
    required DashboardPeriod period,
    String? userId,
  });
}

/// Implementation of [DashboardRemoteDataSource] using Supabase Edge Functions.
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  @override
  Future<DashboardStatsModel> getStats({
    required String groupId,
    required DashboardPeriod period,
    String? userId,
  }) async {
    try {
      final body = <String, dynamic>{
        'group_id': groupId,
        'period': period.apiValue,
      };

      if (userId != null) {
        body['user_id'] = userId;
      }

      final response = await _supabaseClient.functions.invoke(
        'dashboard-stats',
        body: body,
      );

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error'] as String? ?? 'Failed to fetch dashboard stats';
        throw ServerException(errorMessage);
      }

      final data = response.data as Map<String, dynamic>;
      return DashboardStatsModel.fromJson(data, period);
    } on FunctionException catch (e) {
      throw ServerException(
        e.details?.toString() ?? 'Edge function error',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch dashboard stats: $e');
    }
  }
}
