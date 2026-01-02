import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';

/// Implementation of [CategoryRepository] using remote data source.
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({required this.remoteDataSource});

  final CategoryRemoteDataSource remoteDataSource;

  // ========== Category CRUD Operations ==========

  @override
  Future<Either<Failure, List<ExpenseCategoryEntity>>> getCategories({
    required String groupId,
    bool includeExpenseCount = false,
  }) async {
    try {
      final categories = await remoteDataSource.getCategories(
        groupId: groupId,
        includeExpenseCount: includeExpenseCount,
      );
      return Right(categories.map((c) => c.toEntity()).toList());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseCategoryEntity>> getCategory({
    required String categoryId,
  }) async {
    try {
      final category = await remoteDataSource.getCategory(
        categoryId: categoryId,
      );
      return Right(category.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseCategoryEntity>> createCategory({
    required String groupId,
    required String name,
  }) async {
    // Validate category name
    final validationError = _validateCategoryName(name);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    try {
      // Check if name already exists
      final exists = await remoteDataSource.categoryNameExists(
        groupId: groupId,
        name: name,
      );

      if (exists) {
        return const Left(
          ValidationFailure('A category with this name already exists'),
        );
      }

      final category = await remoteDataSource.createCategory(
        groupId: groupId,
        name: name,
      );
      return Right(category.toEntity());
    } on AppAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseCategoryEntity>> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    // Validate category name
    final validationError = _validateCategoryName(name);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    try {
      // Get the category to check permissions and get group_id
      final categoryResult = await getCategory(categoryId: categoryId);

      return await categoryResult.fold(
        (failure) => Left(failure),
        (category) async {
          // Check if name already exists (excluding current category)
          final exists = await remoteDataSource.categoryNameExists(
            groupId: category.groupId,
            name: name,
            excludeCategoryId: categoryId,
          );

          if (exists) {
            return const Left(
              ValidationFailure('A category with this name already exists'),
            );
          }

          // Check if it's a default category
          if (category.isDefault) {
            return const Left(
              PermissionFailure('Default categories cannot be renamed'),
            );
          }

          final updated = await remoteDataSource.updateCategory(
            categoryId: categoryId,
            name: name,
          );
          return Right(updated.toEntity());
        },
      );
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory({
    required String categoryId,
  }) async {
    try {
      // Get the category to check if it can be deleted
      final categoryResult = await getCategory(categoryId: categoryId);

      return await categoryResult.fold(
        (failure) => Left(failure),
        (category) async {
          // Check if it's a default category
          if (category.isDefault) {
            return const Left(
              PermissionFailure('Default categories cannot be deleted'),
            );
          }

          // Check if it has expenses
          final expenseCount = await remoteDataSource.getCategoryExpenseCount(
            categoryId: categoryId,
          );

          if (expenseCount > 0) {
            return const Left(
              ValidationFailure(
                'Cannot delete category with existing expenses. '
                'Please reassign all expenses to another category first.',
              ),
            );
          }

          await remoteDataSource.deleteCategory(categoryId: categoryId);
          return const Right(unit);
        },
      );
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ========== Bulk Operations ==========

  @override
  Future<Either<Failure, int>> batchUpdateExpenseCategory({
    required String groupId,
    required String oldCategoryId,
    required String newCategoryId,
  }) async {
    try {
      final count = await remoteDataSource.batchUpdateExpenseCategory(
        groupId: groupId,
        oldCategoryId: oldCategoryId,
        newCategoryId: newCategoryId,
      );
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getCategoryExpenseCount({
    required String categoryId,
  }) async {
    try {
      final count = await remoteDataSource.getCategoryExpenseCount(
        categoryId: categoryId,
      );
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ========== Validation ==========

  @override
  Future<Either<Failure, bool>> categoryNameExists({
    required String groupId,
    required String name,
    String? excludeCategoryId,
  }) async {
    try {
      final exists = await remoteDataSource.categoryNameExists(
        groupId: groupId,
        name: name,
        excludeCategoryId: excludeCategoryId,
      );
      return Right(exists);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Validate category name.
  ///
  /// Returns error message if invalid, null if valid.
  String? _validateCategoryName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'Category name cannot be empty';
    }

    if (trimmed.length < 1) {
      return 'Category name must be at least 1 character';
    }

    if (trimmed.length > 50) {
      return 'Category name must be at most 50 characters';
    }

    return null;
  }
}
