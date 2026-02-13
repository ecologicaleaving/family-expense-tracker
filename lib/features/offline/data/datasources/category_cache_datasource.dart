import 'package:drift/drift.dart';

import '../local/offline_database.dart';
import '../../../categories/domain/entities/expense_category_entity.dart';

/// Local data source for caching expense categories
abstract class CategoryCacheDataSource {
  /// Cache categories for a group
  Future<void> cacheCategories(
    String groupId,
    List<ExpenseCategoryEntity> categories,
  );

  /// Get cached categories for a group
  Future<List<ExpenseCategoryEntity>> getCachedCategories(String groupId);

  /// Clear cached categories for a group
  Future<void> clearCache(String groupId);

  /// Clear all cached categories
  Future<void> clearAllCache();
}

/// Implementation of CategoryCacheDataSource using Drift
class CategoryCacheDataSourceImpl implements CategoryCacheDataSource {
  final OfflineDatabase _db;

  CategoryCacheDataSourceImpl({required OfflineDatabase database})
      : _db = database;

  @override
  Future<void> cacheCategories(
    String groupId,
    List<ExpenseCategoryEntity> categories,
  ) async {
    // Clear existing cache for this group
    await (_db.delete(_db.cachedCategories)
          ..where((tbl) => tbl.groupId.equals(groupId)))
        .go();

    // Insert new categories
    final now = DateTime.now();
    for (final category in categories) {
      final companion = CachedCategoriesCompanion.insert(
        id: category.id,
        name: category.name,
        groupId: category.groupId,
        isDefault: category.isDefault,
        createdBy: Value(category.createdBy),
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        sortOrder: Value(category.sortOrder ?? 0),
        isActive: Value(category.isActive),
        cachedAt: now,
      );
      await _db.into(_db.cachedCategories).insert(
            companion,
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  @override
  Future<List<ExpenseCategoryEntity>> getCachedCategories(
    String groupId,
  ) async {
    final cached = await (_db.select(_db.cachedCategories)
          ..where((tbl) => tbl.groupId.equals(groupId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.sortOrder),
            (tbl) => OrderingTerm.desc(tbl.isDefault),
            (tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();

    return cached
        .map((c) => ExpenseCategoryEntity(
              id: c.id,
              name: c.name,
              groupId: c.groupId,
              isDefault: c.isDefault,
              createdBy: c.createdBy,
              createdAt: c.createdAt,
              updatedAt: c.updatedAt,
              sortOrder: c.sortOrder,
              isActive: c.isActive,
            ))
        .toList();
  }

  @override
  Future<void> clearCache(String groupId) async {
    await (_db.delete(_db.cachedCategories)
          ..where((tbl) => tbl.groupId.equals(groupId)))
        .go();
  }

  @override
  Future<void> clearAllCache() async {
    await _db.delete(_db.cachedCategories).go();
  }
}
