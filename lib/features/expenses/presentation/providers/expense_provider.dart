import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';

/// Provider for expense remote data source
final expenseRemoteDataSourceProvider = Provider<ExpenseRemoteDataSource>((ref) {
  return ExpenseRemoteDataSourceImpl(
    supabaseClient: Supabase.instance.client,
  );
});

/// Provider for expense repository
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(
    remoteDataSource: ref.watch(expenseRemoteDataSourceProvider),
  );
});

/// Expense list state status
enum ExpenseListStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Expense list state class
class ExpenseListState {
  const ExpenseListState({
    this.status = ExpenseListStatus.initial,
    this.expenses = const [],
    this.hasMore = true,
    this.errorMessage,
    this.filterCategory,
    this.filterStartDate,
    this.filterEndDate,
    this.filterCreatedBy,
  });

  final ExpenseListStatus status;
  final List<ExpenseEntity> expenses;
  final bool hasMore;
  final String? errorMessage;
  final ExpenseCategory? filterCategory;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterCreatedBy;

  ExpenseListState copyWith({
    ExpenseListStatus? status,
    List<ExpenseEntity>? expenses,
    bool? hasMore,
    String? errorMessage,
    ExpenseCategory? filterCategory,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? filterCreatedBy,
  }) {
    return ExpenseListState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      filterCategory: filterCategory ?? this.filterCategory,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      filterCreatedBy: filterCreatedBy ?? this.filterCreatedBy,
    );
  }

  bool get isLoading => status == ExpenseListStatus.loading;
  bool get hasError => status == ExpenseListStatus.error;
  bool get isEmpty => expenses.isEmpty && status == ExpenseListStatus.loaded;
  bool get hasFilters =>
      filterCategory != null ||
      filterStartDate != null ||
      filterEndDate != null ||
      filterCreatedBy != null;
}

/// Expense list notifier
class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  ExpenseListNotifier(this._expenseRepository) : super(const ExpenseListState());

  final ExpenseRepository _expenseRepository;
  static const int _pageSize = 20;

  /// Load expenses
  Future<void> loadExpenses({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      status: ExpenseListStatus.loading,
      errorMessage: null,
      expenses: refresh ? [] : state.expenses,
    );

    final result = await _expenseRepository.getExpenses(
      startDate: state.filterStartDate,
      endDate: state.filterEndDate,
      category: state.filterCategory?.value,
      createdBy: state.filterCreatedBy,
      limit: _pageSize,
      offset: refresh ? 0 : state.expenses.length,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: ExpenseListStatus.error,
          errorMessage: failure.message,
        );
      },
      (expenses) {
        state = state.copyWith(
          status: ExpenseListStatus.loaded,
          expenses: refresh ? expenses : [...state.expenses, ...expenses],
          hasMore: expenses.length >= _pageSize,
        );
      },
    );
  }

  /// Load more expenses (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadExpenses();
  }

  /// Refresh expenses
  Future<void> refresh() async {
    await loadExpenses(refresh: true);
  }

  /// Set category filter
  void setFilterCategory(ExpenseCategory? category) {
    state = state.copyWith(filterCategory: category);
    loadExpenses(refresh: true);
  }

  /// Set date range filter
  void setFilterDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      filterStartDate: start,
      filterEndDate: end,
    );
    loadExpenses(refresh: true);
  }

  /// Set created by filter
  void setFilterCreatedBy(String? userId) {
    state = state.copyWith(filterCreatedBy: userId);
    loadExpenses(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    state = const ExpenseListState();
    loadExpenses(refresh: true);
  }

  /// Add expense to list (after creation)
  void addExpense(ExpenseEntity expense) {
    state = state.copyWith(
      expenses: [expense, ...state.expenses],
    );
  }

  /// Update expense in list
  void updateExpenseInList(ExpenseEntity expense) {
    state = state.copyWith(
      expenses: state.expenses.map((e) => e.id == expense.id ? expense : e).toList(),
    );
  }

  /// Remove expense from list
  void removeExpenseFromList(String expenseId) {
    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != expenseId).toList(),
    );
  }
}

/// Provider for expense list state
final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, ExpenseListState>((ref) {
  // Refresh when auth changes
  ref.watch(authProvider);
  return ExpenseListNotifier(ref.watch(expenseRepositoryProvider));
});

/// Expense form state
enum ExpenseFormStatus {
  initial,
  submitting,
  success,
  error,
}

/// Expense form state class
class ExpenseFormState {
  const ExpenseFormState({
    this.status = ExpenseFormStatus.initial,
    this.expense,
    this.errorMessage,
  });

  final ExpenseFormStatus status;
  final ExpenseEntity? expense;
  final String? errorMessage;

  ExpenseFormState copyWith({
    ExpenseFormStatus? status,
    ExpenseEntity? expense,
    String? errorMessage,
  }) {
    return ExpenseFormState(
      status: status ?? this.status,
      expense: expense ?? this.expense,
      errorMessage: errorMessage,
    );
  }

  bool get isSubmitting => status == ExpenseFormStatus.submitting;
  bool get isSuccess => status == ExpenseFormStatus.success;
  bool get hasError => status == ExpenseFormStatus.error;
}

/// Expense form notifier
class ExpenseFormNotifier extends StateNotifier<ExpenseFormState> {
  ExpenseFormNotifier(this._expenseRepository) : super(const ExpenseFormState());

  final ExpenseRepository _expenseRepository;

  /// Create a new expense
  Future<ExpenseEntity?> createExpense({
    required double amount,
    required DateTime date,
    required ExpenseCategory category,
    String? merchant,
    String? notes,
    Uint8List? receiptImage,
  }) async {
    state = state.copyWith(status: ExpenseFormStatus.submitting, errorMessage: null);

    final result = await _expenseRepository.createExpense(
      amount: amount,
      date: date,
      category: category.value,
      merchant: merchant,
      notes: notes,
      receiptImage: receiptImage,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ExpenseFormStatus.error,
          errorMessage: failure.message,
        );
        return null;
      },
      (expense) {
        state = state.copyWith(
          status: ExpenseFormStatus.success,
          expense: expense,
        );
        return expense;
      },
    );
  }

  /// Update an existing expense
  Future<ExpenseEntity?> updateExpense({
    required String expenseId,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? merchant,
    String? notes,
  }) async {
    state = state.copyWith(status: ExpenseFormStatus.submitting, errorMessage: null);

    final result = await _expenseRepository.updateExpense(
      expenseId: expenseId,
      amount: amount,
      date: date,
      category: category?.value,
      merchant: merchant,
      notes: notes,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ExpenseFormStatus.error,
          errorMessage: failure.message,
        );
        return null;
      },
      (expense) {
        state = state.copyWith(
          status: ExpenseFormStatus.success,
          expense: expense,
        );
        return expense;
      },
    );
  }

  /// Delete an expense
  Future<bool> deleteExpense({required String expenseId}) async {
    state = state.copyWith(status: ExpenseFormStatus.submitting, errorMessage: null);

    final result = await _expenseRepository.deleteExpense(expenseId: expenseId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ExpenseFormStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: ExpenseFormStatus.success);
        return true;
      },
    );
  }

  /// Reset form state
  void reset() {
    state = const ExpenseFormState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for expense form state
final expenseFormProvider =
    StateNotifierProvider<ExpenseFormNotifier, ExpenseFormState>((ref) {
  return ExpenseFormNotifier(ref.watch(expenseRepositoryProvider));
});

/// Provider for a single expense
final expenseProvider = FutureProvider.family<ExpenseEntity?, String>((ref, expenseId) async {
  final repository = ref.watch(expenseRepositoryProvider);
  final result = await repository.getExpense(expenseId: expenseId);
  return result.fold((_) => null, (expense) => expense);
});
