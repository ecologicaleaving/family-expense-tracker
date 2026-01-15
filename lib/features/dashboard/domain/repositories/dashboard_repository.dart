import '../entities/dashboard_stats_entity.dart';

/// Abstract repository interface for dashboard statistics.
abstract class DashboardRepository {
  /// Fetches dashboard statistics for a group.
  ///
  /// [groupId] - The ID of the family group
  /// [period] - The time period for statistics (week, month, year)
  /// [userId] - Optional user ID to filter by specific member
  /// [offset] - Time offset (0 = current, -1 = previous period, etc.)
  ///
  /// Returns [DashboardStats] with aggregated expense data.
  /// Throws [DashboardException] on failure.
  Future<DashboardStats> getStats({
    required String groupId,
    required DashboardPeriod period,
    String? userId,
    int offset = 0,
  });

  /// Fetches cached dashboard statistics if available.
  ///
  /// Returns null if no cached data exists or cache is expired.
  Future<DashboardStats?> getCachedStats({
    required String groupId,
    required DashboardPeriod period,
    String? userId,
    int offset = 0,
  });

  /// Caches dashboard statistics locally.
  Future<void> cacheStats(DashboardStats stats, {String? userId});

  /// Clears all cached dashboard statistics.
  Future<void> clearCache();
}
