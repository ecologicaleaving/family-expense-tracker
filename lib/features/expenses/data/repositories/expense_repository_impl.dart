import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

/// Implementation of [ExpenseRepository] using remote data source.
class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({required this.remoteDataSource});

  final ExpenseRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? createdBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final expenses = await remoteDataSource.getExpenses(
        startDate: startDate,
        endDate: endDate,
        category: category,
        createdBy: createdBy,
        limit: limit,
        offset: offset,
      );
      return Right(expenses.map((e) => e.toEntity()).toList());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on GroupException catch (e) {
      return Left(GroupFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> getExpense({
    required String expenseId,
  }) async {
    try {
      final expense = await remoteDataSource.getExpense(expenseId: expenseId);
      return Right(expense.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> createExpense({
    required double amount,
    required DateTime date,
    required String category,
    String? merchant,
    String? notes,
    Uint8List? receiptImage,
  }) async {
    try {
      // Create the expense first
      var expense = await remoteDataSource.createExpense(
        amount: amount,
        date: date,
        category: category,
        merchant: merchant,
        notes: notes,
      );

      // Upload receipt if provided
      if (receiptImage != null) {
        final receiptPath = await remoteDataSource.uploadReceiptImage(
          expenseId: expense.id,
          imageData: receiptImage,
        );
        expense = expense.copyWith(receiptUrl: receiptPath);
      }

      return Right(expense.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on GroupException catch (e) {
      return Left(GroupFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> updateExpense({
    required String expenseId,
    double? amount,
    DateTime? date,
    String? category,
    String? merchant,
    String? notes,
  }) async {
    try {
      final expense = await remoteDataSource.updateExpense(
        expenseId: expenseId,
        amount: amount,
        date: date,
        category: category,
        merchant: merchant,
        notes: notes,
      );
      return Right(expense.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteExpense({
    required String expenseId,
  }) async {
    try {
      await remoteDataSource.deleteExpense(expenseId: expenseId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadReceiptImage({
    required String expenseId,
    required Uint8List imageData,
  }) async {
    try {
      final path = await remoteDataSource.uploadReceiptImage(
        expenseId: expenseId,
        imageData: imageData,
      );
      return Right(path);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getReceiptUrl({
    required String receiptPath,
  }) async {
    try {
      final url = await remoteDataSource.getReceiptUrl(receiptPath: receiptPath);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpensesSummary>> getExpensesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final expenses = await remoteDataSource.getExpenses(
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate totals
      double totalAmount = 0;
      final byCategory = <String, double>{};
      final byMember = <String, _MemberAccumulator>{};

      for (final expense in expenses) {
        totalAmount += expense.amount;

        // By category
        final categoryKey = expense.category.value;
        byCategory[categoryKey] = (byCategory[categoryKey] ?? 0) + expense.amount;

        // By member
        if (!byMember.containsKey(expense.createdBy)) {
          byMember[expense.createdBy] = _MemberAccumulator(
            displayName: expense.createdByName ?? 'Utente',
          );
        }
        byMember[expense.createdBy]!.totalAmount += expense.amount;
        byMember[expense.createdBy]!.expenseCount++;
      }

      return Right(ExpensesSummary(
        totalAmount: totalAmount,
        expenseCount: expenses.length,
        byCategory: byCategory,
        byMember: byMember.map((key, value) => MapEntry(
          key,
          MemberExpenses(
            userId: key,
            displayName: value.displayName,
            totalAmount: value.totalAmount,
            expenseCount: value.expenseCount,
          ),
        )),
      ));
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on GroupException catch (e) {
      return Left(GroupFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class _MemberAccumulator {
  _MemberAccumulator({required this.displayName});

  final String displayName;
  double totalAmount = 0;
  int expenseCount = 0;
}
