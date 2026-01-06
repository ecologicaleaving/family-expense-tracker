import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/budget_composition_entity.dart';
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

  // ========== Category Budget Operations (Feature 004) ==========

  /// Get all category budgets for a specific group and month.
  Future<Either<Failure, List>> getCategoryBudgets({
    required String groupId,
    required int year,
    required int month,
  });

  /// Get a single category budget.
  Future<Either<Failure, dynamic>> getCategoryBudget({
    required String categoryId,
    required String groupId,
    required int year,
    required int month,
  });

  /// Create a new category budget.
  Future<Either<Failure, dynamic>> createCategoryBudget({
    required String categoryId,
    required String groupId,
    required int amount,
    required int month,
    required int year,
    bool isGroupBudget = true, // True for group expenses, false for personal expenses
  });

  /// Update an existing category budget amount.
  Future<Either<Failure, dynamic>> updateCategoryBudget({
    required String budgetId,
    required int amount,
  });

  /// Delete a category budget.
  Future<Either<Failure, Unit>> deleteCategoryBudget(String budgetId);

  /// Get budget statistics for a specific category and month (via RPC).
  Future<Either<Failure, dynamic>> getCategoryBudgetStats({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  });

  /// Get overall group budget statistics for dashboard (via RPC).
  Future<Either<Failure, dynamic>> getOverallGroupBudgetStats({
    required String groupId,
    required int year,
    required int month,
  });

  // ========== Percentage Budget Operations (Feature 004 Extension) ==========

  /// Get group members with their percentage budget contributions
  Future<Either<Failure, List>> getGroupMembersWithPercentages({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  });

  /// Calculate percentage budget amount
  Future<Either<Failure, int>> calculatePercentageBudget({
    required int groupBudgetAmount,
    required double percentage,
  });

  /// Get budget change notifications for user
  Future<Either<Failure, List>> getBudgetChangeNotifications({
    required String groupId,
    required int year,
    required int month,
    String? userId,
  });

  /// Set personal percentage budget
  Future<Either<Failure, dynamic>> setPersonalPercentageBudget({
    required String categoryId,
    required String groupId,
    required String userId,
    required double percentage,
    required int month,
    required int year,
  });

  /// Get percentage from previous month
  Future<Either<Failure, double?>> getPreviousMonthPercentage({
    required String categoryId,
    required String groupId,
    required String userId,
    required int year,
    required int month,
  });

  /// Get percentage history for a user/category
  Future<Either<Failure, List>> getPercentageHistory({
    required String categoryId,
    required String groupId,
    required String userId,
    int? limit,
  });

  // ========== Unified Budget Composition (New System) ==========

  /// Get complete budget composition for a group in a specific month
  ///
  /// Returns a unified view of:
  /// - Group budget (total monthly budget)
  /// - All category budgets with member contributions
  /// - Aggregate spending statistics
  /// - Validation issues
  ///
  /// This is the main method used by the new unified budget system.
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.getBudgetComposition(
  ///   groupId: 'group123',
  ///   year: 2026,
  ///   month: 1,
  /// );
  /// result.fold(
  ///   (failure) => handleError(failure),
  ///   (composition) => displayBudget(composition),
  /// );
  /// ```
  Future<Either<Failure, BudgetComposition>> getBudgetComposition({
    required String groupId,
    required int year,
    required int month,
  });
}
