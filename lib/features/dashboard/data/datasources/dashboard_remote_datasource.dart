import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../models/dashboard_stats_model.dart';

/// Remote data source for dashboard statistics.
/// Calculates stats from expenses table.
abstract class DashboardRemoteDataSource {
  /// Fetches dashboard statistics by querying expenses directly.
  Future<DashboardStatsModel> getStats({
    required String groupId,
    required DashboardPeriod period,
    String? userId,
  });
}

/// Implementation of [DashboardRemoteDataSource] using direct Supabase queries.
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
      // Calculate date range
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day);
      late DateTime startDate;

      switch (period) {
        case DashboardPeriod.week:
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case DashboardPeriod.month:
          startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          break;
        case DashboardPeriod.year:
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
      }

      // Build query - simple select without joins to avoid RLS issues
      var query = _supabaseClient
          .from('expenses')
          .select('id, amount, category, date, paid_by')
          .eq('group_id', groupId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if (userId != null) {
        query = query.eq('paid_by', userId);
      }

      final expenses = await query;

      // Fetch member names separately
      final memberIds = expenses.map((e) => e['paid_by'] as String).toSet().toList();
      final memberNames = <String, String>{};

      if (memberIds.isNotEmpty) {
        try {
          final profiles = await _supabaseClient
              .from('profiles')
              .select('id, display_name')
              .inFilter('id', memberIds);

          for (final profile in profiles) {
            memberNames[profile['id'] as String] =
                profile['display_name'] as String? ?? 'Utente';
          }
        } catch (_) {
          // Ignore errors fetching names, use default
        }
      }

      // Calculate stats from expenses
      double totalAmount = 0;
      final categoryTotals = <String, Map<String, dynamic>>{};
      final memberTotals = <String, Map<String, dynamic>>{};
      final trendData = <String, Map<String, dynamic>>{};

      for (final expense in expenses) {
        final amount = (expense['amount'] as num).toDouble();
        final category = expense['category'] as String? ?? 'altro';
        final date = expense['date'] as String;
        final paidBy = expense['paid_by'] as String;
        final displayName = memberNames[paidBy] ?? 'Utente';

        totalAmount += amount;

        // Category breakdown
        if (!categoryTotals.containsKey(category)) {
          categoryTotals[category] = {'total': 0.0, 'count': 0};
        }
        categoryTotals[category]!['total'] =
            (categoryTotals[category]!['total'] as double) + amount;
        categoryTotals[category]!['count'] =
            (categoryTotals[category]!['count'] as int) + 1;

        // Member breakdown
        if (!memberTotals.containsKey(paidBy)) {
          memberTotals[paidBy] = {
            'display_name': displayName,
            'total': 0.0,
            'count': 0
          };
        }
        memberTotals[paidBy]!['total'] =
            (memberTotals[paidBy]!['total'] as double) + amount;
        memberTotals[paidBy]!['count'] =
            (memberTotals[paidBy]!['count'] as int) + 1;

        // Trend data
        final trendKey = period == DashboardPeriod.year
            ? date.substring(0, 7) // YYYY-MM for year view
            : date; // YYYY-MM-DD for week/month view
        if (!trendData.containsKey(trendKey)) {
          trendData[trendKey] = {'total': 0.0, 'count': 0};
        }
        trendData[trendKey]!['total'] =
            (trendData[trendKey]!['total'] as double) + amount;
        trendData[trendKey]!['count'] =
            (trendData[trendKey]!['count'] as int) + 1;
      }

      final expenseCount = expenses.length;
      final averageExpense = expenseCount > 0 ? totalAmount / expenseCount : 0.0;

      // Build category breakdown list
      final byCategory = categoryTotals.entries.map((e) {
        final percentage =
            totalAmount > 0 ? (e.value['total'] as double) / totalAmount * 100 : 0.0;
        return CategoryBreakdownModel(
          category: e.key,
          total: e.value['total'] as double,
          count: e.value['count'] as int,
          percentage: double.parse(percentage.toStringAsFixed(1)),
        );
      }).toList()
        ..sort((a, b) => b.total.compareTo(a.total));

      // Build member breakdown list
      final byMember = memberTotals.entries.map((e) {
        final percentage =
            totalAmount > 0 ? (e.value['total'] as double) / totalAmount * 100 : 0.0;
        return MemberBreakdownModel(
          userId: e.key,
          displayName: e.value['display_name'] as String,
          total: e.value['total'] as double,
          count: e.value['count'] as int,
          percentage: double.parse(percentage.toStringAsFixed(1)),
        );
      }).toList()
        ..sort((a, b) => b.total.compareTo(a.total));

      // Build trend list
      final trend = trendData.entries.map((e) {
        final dateStr = period == DashboardPeriod.year
            ? '${e.key}-01' // Add day for parsing
            : e.key;
        return TrendDataPointModel(
          date: DateTime.parse(dateStr),
          total: e.value['total'] as double,
          count: e.value['count'] as int,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return DashboardStatsModel(
        period: period,
        startDate: startDate,
        endDate: endDate,
        totalAmount: totalAmount,
        expenseCount: expenseCount,
        averageExpense: double.parse(averageExpense.toStringAsFixed(2)),
        byCategory: byCategory,
        byMember: byMember,
        trend: trend,
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch dashboard stats: $e');
    }
  }
}
