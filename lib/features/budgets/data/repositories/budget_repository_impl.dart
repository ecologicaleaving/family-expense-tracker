import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
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
}
