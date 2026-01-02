import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/expense_category_entity.dart';

/// Abstract category repository interface.
///
/// Defines the contract for category operations (CRUD + bulk operations).
/// Implementations should handle the actual communication with the backend (Supabase).
abstract class CategoryRepository {
  // ========== Category CRUD Operations ==========

  /// Get all categories for a group.
  ///
  /// Returns list of categories with optional expense counts.
  Future<Either<Failure, List<ExpenseCategoryEntity>>> getCategories({
    required String groupId,
    bool includeExpenseCount = false,
  });

  /// Get a single category by ID.
  Future<Either<Failure, ExpenseCategoryEntity>> getCategory({
    required String categoryId,
  });

  /// Create a new custom category.
  ///
  /// Only administrators can create categories.
  /// Returns the created category with its generated ID.
  Future<Either<Failure, ExpenseCategoryEntity>> createCategory({
    required String groupId,
    required String name,
  });

  /// Update a category name.
  ///
  /// Only administrators can update categories.
  /// Default categories cannot be renamed.
  Future<Either<Failure, ExpenseCategoryEntity>> updateCategory({
    required String categoryId,
    required String name,
  });

  /// Delete a category.
  ///
  /// Only administrators can delete categories.
  /// Default categories cannot be deleted.
  /// Must reassign all expenses to another category first.
  Future<Either<Failure, Unit>> deleteCategory({
    required String categoryId,
  });

  // ========== Bulk Operations ==========

  /// Batch update expenses to new category.
  ///
  /// Used when deleting a category - reassigns all expenses to a new category.
  /// Supports bulk reassignment of 500+ expenses efficiently.
  Future<Either<Failure, int>> batchUpdateExpenseCategory({
    required String groupId,
    required String oldCategoryId,
    required String newCategoryId,
  });

  /// Get expense count for a category.
  ///
  /// Returns the number of expenses using this category.
  Future<Either<Failure, int>> getCategoryExpenseCount({
    required String categoryId,
  });

  // ========== Validation ==========

  /// Check if a category name already exists in the group.
  ///
  /// Used for validation before creating or renaming categories.
  Future<Either<Failure, bool>> categoryNameExists({
    required String groupId,
    required String name,
    String? excludeCategoryId,
  });
}
