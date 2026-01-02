import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/budget_stats_entity.dart';
import '../entities/group_budget_entity.dart';
import '../entities/personal_budget_entity.dart';

/// Abstract budget repository interface.
///
/// Defines the contract for budget operations (both group and personal).
/// Implementations should handle the actual communication with the backend (Supabase).
abstract class BudgetRepository {
  // ========== Group Budget Operations ==========

  /// Set or update a group budget for a specific month/year.
  ///
  /// Only group administrators can perform this operation.
  /// Returns the created/updated group budget.
  Future<Either<Failure, GroupBudgetEntity>> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  });

  /// Get group budget for a specific month/year.
  ///
  /// Returns null if no budget is set for the specified period.
  Future<Either<Failure, GroupBudgetEntity?>> getGroupBudget({
    required String groupId,
    required int month,
    required int year,
  });

  /// Get group budget statistics for a specific month/year.
  ///
  /// Calculates spent amount, remaining amount, percentage used, etc.
  /// Works even if no budget is set (shows spending without budget comparison).
  Future<Either<Failure, BudgetStatsEntity>> getGroupBudgetStats({
    required String groupId,
    required int month,
    required int year,
  });

  /// Get historical group budgets for a group.
  ///
  /// Returns list of past budgets ordered by year/month descending.
  /// Optionally limit the number of results.
  Future<Either<Failure, List<GroupBudgetEntity>>> getGroupBudgetHistory({
    required String groupId,
    int? limit,
  });

  // ========== Personal Budget Operations ==========

  /// Set or update a personal budget for a specific month/year.
  ///
  /// Returns the created/updated personal budget.
  Future<Either<Failure, PersonalBudgetEntity>> setPersonalBudget({
    required String userId,
    required int amount,
    required int month,
    required int year,
  });

  /// Get personal budget for a specific month/year.
  ///
  /// Returns null if no budget is set for the specified period.
  Future<Either<Failure, PersonalBudgetEntity?>> getPersonalBudget({
    required String userId,
    required int month,
    required int year,
  });

  /// Get personal budget statistics for a specific month/year.
  ///
  /// Calculates spent amount from both personal expenses AND user's group expenses.
  /// Works even if no budget is set (shows spending without budget comparison).
  Future<Either<Failure, BudgetStatsEntity>> getPersonalBudgetStats({
    required String userId,
    required int month,
    required int year,
  });

  /// Get historical personal budgets for a user.
  ///
  /// Returns list of past budgets ordered by year/month descending.
  /// Optionally limit the number of results.
  Future<Either<Failure, List<PersonalBudgetEntity>>> getPersonalBudgetHistory({
    required String userId,
    int? limit,
  });
}
