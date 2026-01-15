import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/income_source_entity.dart';
import '../../domain/usecases/add_income_source_usecase.dart';
import '../../domain/usecases/update_savings_goal_usecase.dart';
import 'budget_repository_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Use case providers
final updateSavingsGoalUseCaseProvider =
    Provider<UpdateSavingsGoalUseCase>((ref) {
  return UpdateSavingsGoalUseCase(
    ref.watch(budgetRepositoryProvider),
  );
});

/// Provider for watching income sources list
///
/// Provides real-time stream of income sources for the current user
/// Updates automatically when income sources are added/removed/updated
final incomeSourcesProvider = StreamProvider.autoDispose<List<IncomeSourceEntity>>((ref) {
  // Get current user ID from auth
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  print('🔍 [incomeSourcesProvider] Loading income sources for userId: $userId');

  if (userId == null) {
    print('❌ [incomeSourcesProvider] userId is null!');
    return Stream.value([]);
  }

  // Watch income sources from repository
  final stream = ref.watch(budgetRepositoryProvider).watchIncomeSources(userId);

  return stream.map((sources) {
    print('✅ [incomeSourcesProvider] Loaded ${sources.length} income sources');
    for (final source in sources) {
      print('   - ${source.type}: ${source.amount} cents');
    }
    return sources;
  });
});

/// Provider for total income calculation
///
/// Automatically recomputes when income sources change
/// Returns total of all income sources in cents
final totalIncomeProvider = Provider.autoDispose<AsyncValue<int>>((ref) {
  final incomeSourcesAsync = ref.watch(incomeSourcesProvider);

  return incomeSourcesAsync.when(
    data: (sources) {
      final total = sources.fold<int>(0, (sum, source) => sum + source.amount);
      return AsyncValue.data(total);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for checking if user has any income sources
final hasIncomeSourcesProvider = Provider.autoDispose<bool>((ref) {
  final incomeSourcesAsync = ref.watch(incomeSourcesProvider);

  return incomeSourcesAsync.when(
    data: (sources) => sources.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for getting income sources by type
///
/// Useful for displaying income sources grouped by type
final incomeSourcesByTypeProvider =
    Provider.autoDispose<Map<IncomeType, List<IncomeSourceEntity>>>((ref) {
  final incomeSourcesAsync = ref.watch(incomeSourcesProvider);

  return incomeSourcesAsync.when(
    data: (sources) {
      final Map<IncomeType, List<IncomeSourceEntity>> grouped = {};

      for (final source in sources) {
        if (!grouped.containsKey(source.type)) {
          grouped[source.type] = [];
        }
        grouped[source.type]!.add(source);
      }

      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Provider for income sources count
final incomeSourcesCountProvider = Provider.autoDispose<int>((ref) {
  final incomeSourcesAsync = ref.watch(incomeSourcesProvider);

  return incomeSourcesAsync.when(
    data: (sources) => sources.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
