import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../models/dashboard_stats_model.dart';

/// Remote data source for dashboard statistics.
/// Uses RPC function to calculate stats.
abstract class DashboardRemoteDataSource {
  /// Fetches dashboard statistics from the database RPC function.
  Future<DashboardStatsModel> getStats({
    required String groupId,
    required DashboardPeriod period,
    String? userId,
  });
}

/// Implementation of [DashboardRemoteDataSource] using Supabase RPC.
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
      final params = <String, dynamic>{
        'p_group_id': groupId,
        'p_period': period.apiValue,
      };

      if (userId != null) {
        params['p_user_id'] = userId;
      }

      final response = await _supabaseClient.rpc(
        'get_dashboard_stats',
        params: params,
      );

      if (response == null) {
        throw const ServerException('No data returned from dashboard stats');
      }

      final data = response as Map<String, dynamic>;
      return DashboardStatsModel.fromJson(data, period);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch dashboard stats: $e');
    }
  }
}
