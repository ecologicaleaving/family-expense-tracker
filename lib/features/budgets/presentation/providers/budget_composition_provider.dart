import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/budget_validator.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../domain/entities/budget_composition_entity.dart';
import '../../domain/entities/budget_validation_issue_entity.dart';
import '../../domain/exceptions/budget_exception.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_repository_provider.dart';

/// Parameters for budget composition provider
class BudgetCompositionParams {
  final String groupId;
  final int year;
  final int month;

  const BudgetCompositionParams({
    required this.groupId,
    required this.year,
    required this.month,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetCompositionParams &&
          runtimeType == other.runtimeType &&
          groupId == other.groupId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => groupId.hashCode ^ year.hashCode ^ month.hashCode;

  @override
  String toString() => 'BudgetCompositionParams(groupId: $groupId, year: $year, month: $month)';
}

/// Provider for budget composition
///
/// This is the main provider for the unified budget system.
/// It manages the complete budget composition including:
/// - Group budget
/// - Category budgets with member contributions
/// - Aggregate statistics
/// - Validation issues
/// - Realtime synchronization
final budgetCompositionProvider = StateNotifierProvider.family<
    BudgetCompositionNotifier,
    AsyncValue<BudgetComposition>,
    BudgetCompositionParams>(
  (ref, params) {
    final repository = ref.watch(budgetRepositoryProvider);
    final supabase = Supabase.instance.client;

    return BudgetCompositionNotifier(
      repository: repository,
      supabaseClient: supabase,
      params: params,
    );
  },
);

/// Convenience provider for current month's budget composition
final currentMonthBudgetCompositionProvider =
    Provider<AsyncValue<BudgetComposition>>((ref) {
  final groupId = ref.watch(currentGroupIdProvider);
  final now = DateTime.now();

  final params = BudgetCompositionParams(
    groupId: groupId,
    year: now.year,
    month: now.month,
  );

  return ref.watch(budgetCompositionProvider(params));
});

/// State notifier for budget composition
class BudgetCompositionNotifier
    extends StateNotifier<AsyncValue<BudgetComposition>> {
  BudgetCompositionNotifier({
    required BudgetRepository repository,
    required SupabaseClient supabaseClient,
    required BudgetCompositionParams params,
  })  : _repository = repository,
        _supabaseClient = supabaseClient,
        _params = params,
        super(const AsyncValue.loading()) {
    _init();
  }

  final BudgetRepository _repository;
  final SupabaseClient _supabaseClient;
  final BudgetCompositionParams _params;

  RealtimeChannel? _groupBudgetChannel;
  RealtimeChannel? _categoryBudgetChannel;

  Future<void> _init() async {
    await loadComposition();
    _setupRealtimeSync();
  }

  /// Load budget composition from repository
  Future<void> loadComposition() async {
    state = const AsyncValue.loading();

    final result = await _repository.getBudgetComposition(
      groupId: _params.groupId,
      year: _params.year,
      month: _params.month,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(
          BudgetException('Errore caricamento budget: ${failure.message}'),
          StackTrace.current,
        );
      },
      (composition) {
        state = AsyncValue.data(composition);
      },
    );
  }

  /// Refresh composition (reload from database)
  Future<void> refresh() async {
    await loadComposition();
  }

  // ========== CRUD Operations ==========

  /// Set or update group budget
  Future<void> setGroupBudget(int amount) async {
    try {
      // Validate amount
      if (!BudgetValidator.isValidAmount(amount)) {
        throw BudgetException.invalidAmount('Importo non valido');
      }

      // Show loading state
      state = const AsyncValue.loading();

      // Call repository
      final result = await _repository.setGroupBudget(
        groupId: _params.groupId,
        amount: amount,
        month: _params.month,
        year: _params.year,
      );

      // Handle result
      await result.fold(
        (failure) async {
          throw BudgetException('Errore salvataggio budget gruppo: ${failure.message}');
        },
        (groupBudget) async {
          // Reload composition to get updated data
          await loadComposition();
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Set or update category budget
  Future<void> setCategoryBudget({
    required String categoryId,
    required int amount,
  }) async {
    try {
      // Validate amount
      if (!BudgetValidator.isValidAmount(amount)) {
        throw BudgetException.invalidAmount('Importo categoria non valido');
      }

      // Get current composition before setting loading state
      final currentComposition = state.value;
      final existingBudget = currentComposition?.categoryBudgets
          .where((cb) => cb.categoryId == categoryId)
          .firstOrNull;

      state = const AsyncValue.loading();

      if (existingBudget != null && existingBudget.groupBudgetId != null) {
        // Update existing
        final result = await _repository.updateCategoryBudget(
          budgetId: existingBudget.groupBudgetId!,
          amount: amount,
        );

        await result.fold(
          (failure) async {
            throw BudgetException('Errore aggiornamento budget categoria: ${failure.message}');
          },
          (_) async {
            await loadComposition();
          },
        );
      } else {
        // Create new
        final result = await _repository.createCategoryBudget(
          categoryId: categoryId,
          groupId: _params.groupId,
          amount: amount,
          month: _params.month,
          year: _params.year,
          isGroupBudget: true,
        );

        await result.fold(
          (failure) async {
            throw BudgetException('Errore creazione budget categoria: ${failure.message}');
          },
          (_) async {
            await loadComposition();
          },
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Set or update member contribution (percentage-based)
  Future<void> setMemberPercentageContribution({
    required String categoryId,
    required String userId,
    required double percentage,
  }) async {
    try {
      // Validate percentage
      if (!BudgetValidator.isValidPercentage(percentage)) {
        throw BudgetException.invalidPercentage(percentage);
      }

      state = const AsyncValue.loading();

      final result = await _repository.setPersonalPercentageBudget(
        categoryId: categoryId,
        groupId: _params.groupId,
        userId: userId,
        percentage: percentage,
        month: _params.month,
        year: _params.year,
      );

      await result.fold(
        (failure) async {
          throw BudgetException('Errore salvataggio contributo: ${failure.message}');
        },
        (_) async {
          await loadComposition();
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Set or update member contribution (fixed amount)
  Future<void> setMemberFixedContribution({
    required String categoryId,
    required String userId,
    required int amount,
  }) async {
    try {
      // Validate amount
      if (!BudgetValidator.isValidAmount(amount)) {
        throw BudgetException.invalidAmount('Importo contributo non valido');
      }

      state = const AsyncValue.loading();

      // Use the createCategoryBudget with isGroupBudget=false for personal budgets
      final result = await _repository.createCategoryBudget(
        categoryId: categoryId,
        groupId: _params.groupId,
        amount: amount,
        month: _params.month,
        year: _params.year,
        isGroupBudget: false,
      );

      await result.fold(
        (failure) async {
          throw BudgetException('Errore salvataggio contributo fisso: ${failure.message}');
        },
        (_) async {
          await loadComposition();
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete category budget
  Future<void> deleteCategoryBudget(String budgetId) async {
    try {
      state = const AsyncValue.loading();

      final result = await _repository.deleteCategoryBudget(budgetId);

      await result.fold(
        (failure) async {
          throw BudgetException('Errore eliminazione budget categoria: ${failure.message}');
        },
        (_) async {
          await loadComposition();
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ========== Validation ==========

  /// Validate current composition
  ///
  /// Returns list of validation issues.
  /// Use this to check for errors before saving.
  List<BudgetValidationIssue> validate() {
    final composition = state.value;
    if (composition == null) return [];

    return BudgetValidator.validateComposition(composition);
  }

  /// Check if current composition has validation errors
  bool hasErrors() {
    final issues = validate();
    return issues.any((issue) => issue.isError);
  }

  /// Check if current composition has validation warnings
  bool hasWarnings() {
    final issues = validate();
    return issues.any((issue) => issue.isWarning);
  }

  // ========== Realtime Sync ==========

  /// Setup realtime synchronization for budget changes
  void _setupRealtimeSync() {
    // Subscribe to group budget changes
    _groupBudgetChannel = _supabaseClient
        .channel('budget-composition-group-${_params.groupId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_budgets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: _params.groupId,
          ),
          callback: (_) => _handleRealtimeChange(),
        )
        .subscribe();

    // Subscribe to category budget changes
    _categoryBudgetChannel = _supabaseClient
        .channel('budget-composition-category-${_params.groupId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'category_budgets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: _params.groupId,
          ),
          callback: (_) => _handleRealtimeChange(),
        )
        .subscribe();
  }

  /// Handle realtime change notification
  Future<void> _handleRealtimeChange() async {
    // Debounce: wait a bit to batch multiple changes
    await Future.delayed(const Duration(milliseconds: 500));

    // Reload composition if still mounted
    if (mounted) {
      await loadComposition();
    }
  }

  @override
  void dispose() {
    _groupBudgetChannel?.unsubscribe();
    _categoryBudgetChannel?.unsubscribe();
    super.dispose();
  }
}
