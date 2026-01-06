/// Custom exception for budget-related errors
///
/// Use this exception to provide clear, user-friendly error messages
/// for budget operations.
///
/// Example usage:
/// ```dart
/// if (amount <= 0) {
///   throw BudgetException(
///     'L\'importo deve essere positivo',
///     code: 'INVALID_AMOUNT',
///   );
/// }
/// ```
class BudgetException implements Exception {
  /// Human-readable error message (can be shown to user)
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  /// Original error that caused this exception (for debugging)
  final dynamic originalError;

  /// Stack trace of original error (for debugging)
  final StackTrace? originalStackTrace;

  const BudgetException(
    this.message, {
    this.code,
    this.originalError,
    this.originalStackTrace,
  });

  /// Creates a BudgetException by wrapping another error
  ///
  /// Useful for converting database errors to user-friendly messages.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await database.insert(...);
  /// } on PostgrestException catch (e, st) {
  ///   throw BudgetException.wrap(
  ///     'Errore nel salvataggio del budget',
  ///     originalError: e,
  ///     stackTrace: st,
  ///     code: 'DATABASE_ERROR',
  ///   );
  /// }
  /// ```
  factory BudgetException.wrap(
    String message, {
    required dynamic originalError,
    StackTrace? stackTrace,
    String? code,
  }) {
    return BudgetException(
      message,
      code: code,
      originalError: originalError,
      originalStackTrace: stackTrace,
    );
  }

  /// Exception for invalid budget amounts
  factory BudgetException.invalidAmount(String details) {
    return BudgetException(
      'Importo non valido: $details',
      code: 'INVALID_AMOUNT',
    );
  }

  /// Exception for budget validation failures
  factory BudgetException.validationFailed(String reason) {
    return BudgetException(
      'Validazione budget fallita: $reason',
      code: 'VALIDATION_FAILED',
    );
  }

  /// Exception for over-allocation (category budgets > group budget)
  factory BudgetException.overAllocation({
    required int categoryTotal,
    required int groupBudget,
  }) {
    return BudgetException(
      'Le categorie superano il budget gruppo: €${categoryTotal ~/ 100} > €${groupBudget ~/ 100}',
      code: 'OVER_ALLOCATION',
    );
  }

  /// Exception for invalid percentages
  factory BudgetException.invalidPercentage(double percentage) {
    return BudgetException(
      'Percentuale non valida: ${percentage.toStringAsFixed(1)}% (deve essere 0-100)',
      code: 'INVALID_PERCENTAGE',
    );
  }

  /// Exception for percentage overflow (sum > 100%)
  factory BudgetException.percentageOverflow({
    required String categoryName,
    required double totalPercentage,
  }) {
    return BudgetException(
      'Categoria "$categoryName": somma percentuali ${totalPercentage.toStringAsFixed(1)}% > 100%',
      code: 'PERCENTAGE_OVERFLOW',
    );
  }

  /// Exception for missing required budget
  factory BudgetException.missingBudget(String budgetType) {
    return BudgetException(
      'Budget $budgetType non impostato',
      code: 'MISSING_BUDGET',
    );
  }

  /// Exception for database errors
  factory BudgetException.databaseError(String operation, dynamic error) {
    return BudgetException(
      'Errore database durante $operation',
      code: 'DATABASE_ERROR',
      originalError: error,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('BudgetException: $message');
    if (code != null) {
      buffer.write(' [code: $code]');
    }
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetException &&
        other.message == message &&
        other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}
