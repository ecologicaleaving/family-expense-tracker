import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/offline_database.dart';
import 'category_cache_datasource.dart';

/// Provider for the offline database instance
final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  return OfflineDatabase();
});

/// Provider for category cache datasource
final categoryCacheDataSourceProvider =
    Provider<CategoryCacheDataSource>((ref) {
  final database = ref.watch(offlineDatabaseProvider);
  return CategoryCacheDataSourceImpl(database: database);
});
