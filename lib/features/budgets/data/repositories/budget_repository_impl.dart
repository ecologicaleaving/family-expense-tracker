import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/budget_composition_entity.dart';
import '../../domain/entities/budget_stats_entity.dart';
import '../../domain/entities/group_budget_entity.dart';
import '../../domain/entities/personal_budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_datasource.dart';

/// Implementation of [BudgetRepository] using remote data source.
class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({required this.remoteDataSource});

  final BudgetRemoteDataSource remoteDataSource;

  // ========== Group Budget Operations ==========

  @override
  Future<Either<Failure, GroupBudgetEntity>> setGroupBudget({
    required String groupId,
    required int amount,
    required int month,
    required int year,
  }) async {
    try {
      final budget = await remoteDataSource.setGroupBudget(
        groupId: groupId,
        amount: amount,
        month: month,
        year: year,
      );
      return Right(budget.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupBudgetEntity?>> getGroupBudget({
    required String groupId,
    required int month,
    required int year,
  }) async {
    try {
      final budget = await remoteDataSource.getGroupBudget(
        groupId: groupId,
        month: month,
        year: year,
      );
      return Right(budget?.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BudgetStatsEntity>> getGroupBudgetStats({
    required String groupId,
    required int month,
    required int year,
  }) async {
    try {
      final stats = await remoteDataSource.getGroupBudgetStats(
        groupId: groupId,
        month: month,
        year: year,
      );
      return Right(stats.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupBudgetEntity>>> getGroupBudgetHistory({
    required String groupId,
    int? limit,
  }) async {
    try {
      final budgets = await remoteDataSource.getGroupBudgetHistory(
        groupId: groupId,
        limit: limit,
      );
      return Right(budgets.map((b) => b.toEntity()).toList());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ========== Personal Budget Operations ==========

  @override
  Future<Either<Failure, PersonalBudgetEntity>> setPersonalBudget({
    required String userId,
    required int amount,
    required int month,
    required int year,
  }) async {
    try {
      final budget = await remoteDataSource.setPersonalBudget(
        userId: userId,
        amount: amount,
        month: month,
        year: year,
      );
      return Right(budget.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PersonalBudgetEntity?>> getPersonalBudget({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final budget = await remoteDataSource.getPersonalBudget(
        userId: userId,
        month: month,
        year: year,
      );
      return Right(budget?.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BudgetStatsEntity>> getPersonalBudgetStats({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final stats = await remoteDataSource.getPersonalBudgetStats(
        userId: userId,
        month: month,
        year: year,
      );
      return Right(stats.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PersonalBudgetEntity>>> getPersonalBudgetHistory({
    required String userId,
    int? limit,
  }) async {
    try {
      final budgets = await remoteDataSource.getPersonalBudgetHistory(
        userId: userId,
        limit: limit,
      );
      return Right(budgets.map((b) => b.toEntity()).toList());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ========== Category Budget Operations (Feature 004 - T030) ==========

  @override
  Future<Either<Failure, List>> getCategoryBudgets({
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final budgets = await remoteDataSource.getCategoryBudgets(
        groupId: groupId,
        year: year,
        month: month,
      );
      return Right(budgets);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getCategoryBudget({
    required String categoryId,
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final budget = await remoteDataSource.getCategoryBudget(
        categoryId: categoryId,
        groupId: groupId,
        year: year,
        month: month,
      );
      return Right(budget);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> createCategoryBudget({
    required String categoryId,
    required String groupId,
    required int amount,
    required int month,
    required int year,
    bool isGroupBudget = true,
  }) async {
    try {
      final budget = await remoteDataSource.createCategoryBudget(
        categoryId: categoryId,
        groupId: groupId,
        amount: amount,
        month: month,
        year: year,
        isGroupBudget: isGroupBudget,
      );
      return Right(budget);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> updateCategoryBudget({
    required String budgetId,
    required int amount,
  }) async {
    try {
      final budget = await remoteDataSource.updateCategoryBudget(
        budgetId: budgetId,
        amount: amount,
      );
      return Right(budget);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategoryBudget(String budgetId) async {
    try {
      await remoteDataSource.deleteCategoryBudget(budgetId);
      return const Right(unit);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getCategoryBudgetStats({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  }) async {
    try {
      final stats = await remoteDataSource.getCategoryBudgetStats(
        groupId: groupId,
        categoryId: categoryId,
        year: year,
        month: month,
      );
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> getOverallGroupBudgetStats({
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final stats = await remoteDataSource.getOverallGroupBudgetStats(
        groupId: groupId,
        year: year,
        month: month,
      );
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ========== Percentage Budget Operations (Feature 004 Extension) ==========

  @override
  Future<Either<Failure, List>> getGroupMembersWithPercentages({
    required String groupId,
    required String categoryId,
    required int year,
    required int month,
  }) async {
    try {
      final members = await remoteDataSource.getGroupMembersWithPercentages(
        groupId: groupId,
        categoryId: categoryId,
        year: year,
        month: month,
      );
      return Right(members);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> calculatePercentageBudget({
    required int groupBudgetAmount,
    required double percentage,
  }) async {
    try {
      final amount = await remoteDataSource.calculatePercentageBudget(
        groupBudgetAmount: groupBudgetAmount,
        percentage: percentage,
      );
      return Right(amount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List>> getBudgetChangeNotifications({
    required String groupId,
    required int year,
    required int month,
    String? userId,
  }) async {
    try {
      final notifications = await remoteDataSource.getBudgetChangeNotifications(
        groupId: groupId,
        year: year,
        month: month,
        userId: userId,
      );
      return Right(notifications);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, dynamic>> setPersonalPercentageBudget({
    required String categoryId,
    required String groupId,
    required String userId,
    required double percentage,
    required int month,
    required int year,
  }) async {
    try {
      final budget = await remoteDataSource.setPersonalPercentageBudget(
        categoryId: categoryId,
        groupId: groupId,
        userId: userId,
        percentage: percentage,
        month: month,
        year: year,
      );
      return Right(budget);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double?>> getPreviousMonthPercentage({
    required String categoryId,
    required String groupId,
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final percentage = await remoteDataSource.getPreviousMonthPercentage(
        categoryId: categoryId,
        groupId: groupId,
        userId: userId,
        year: year,
        month: month,
      );
      return Right(percentage);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List>> getPercentageHistory({
    required String categoryId,
    required String groupId,
    required String userId,
    int? limit,
  }) async {
    try {
      final history = await remoteDataSource.getPercentageHistory(
        categoryId: categoryId,
        groupId: groupId,
        userId: userId,
        limit: limit,
      );
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ========== Unified Budget Composition (New System) ==========

  @override
  Future<Either<Failure, BudgetComposition>> getBudgetComposition({
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      final composition = await remoteDataSource.getBudgetComposition(
        groupId: groupId,
        year: year,
        month: month,
      );
      return Right(composition);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Errore nel caricamento budget: ${e.toString()}'));
    }
  }
}
