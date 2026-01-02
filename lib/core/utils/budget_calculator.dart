/// Utility class for budget-related calculations
///
/// Handles budget math including percentage calculations, rounding,
/// and budget status determination
class BudgetCalculator {
  /// Calculate spent amount from expense amounts (rounded up to whole euros)
  ///
  /// [expenseAmounts] - List of expense amounts (may include cents)
  ///
  /// Returns total spent amount rounded up to nearest whole euro
  static int calculateSpentAmount(List<double> expenseAmounts) {
    if (expenseAmounts.isEmpty) return 0;

    // Sum all expenses and round up to whole euro
    final total = expenseAmounts.fold<double>(
      0.0,
      (sum, amount) => sum + amount,
    );

    return total.ceil();
  }

  /// Calculate remaining budget amount
  ///
  /// [budgetAmount] - Budget amount in whole euros
  /// [spentAmount] - Spent amount in whole euros
  ///
  /// Returns remaining amount (can be negative if over budget)
  static int calculateRemainingAmount(int budgetAmount, int spentAmount) {
    return budgetAmount - spentAmount;
  }

  /// Calculate budget usage percentage
  ///
  /// [budgetAmount] - Budget amount in whole euros
  /// [spentAmount] - Spent amount in whole euros
  ///
  /// Returns percentage used (0-100+), or 0 if budget is 0
  static double calculatePercentageUsed(int budgetAmount, int spentAmount) {
    if (budgetAmount <= 0) return 0.0;

    final percentage = (spentAmount / budgetAmount) * 100;
    return double.parse(percentage.toStringAsFixed(2));
  }

  /// Check if budget is over (spent >= budget)
  ///
  /// [budgetAmount] - Budget amount in whole euros
  /// [spentAmount] - Spent amount in whole euros
  ///
  /// Returns true if spent amount equals or exceeds budget
  static bool isOverBudget(int budgetAmount, int spentAmount) {
    return spentAmount >= budgetAmount;
  }

  /// Check if budget is near limit (>= 80% used)
  ///
  /// [budgetAmount] - Budget amount in whole euros
  /// [spentAmount] - Spent amount in whole euros
  ///
  /// Returns true if 80% or more of budget is used
  static bool isNearLimit(int budgetAmount, int spentAmount) {
    if (budgetAmount <= 0) return false;

    final percentageUsed = calculatePercentageUsed(budgetAmount, spentAmount);
    return percentageUsed >= 80.0;
  }

  /// Get budget status as a string
  ///
  /// [budgetAmount] - Budget amount in whole euros
  /// [spentAmount] - Spent amount in whole euros
  ///
  /// Returns one of: 'healthy', 'warning', 'over_budget'
  static String getBudgetStatus(int budgetAmount, int spentAmount) {
    if (isOverBudget(budgetAmount, spentAmount)) {
      return 'over_budget';
    } else if (isNearLimit(budgetAmount, spentAmount)) {
      return 'warning';
    } else {
      return 'healthy';
    }
  }

  /// Format budget amount for display
  ///
  /// [amount] - Amount in whole euros
  ///
  /// Returns formatted string (e.g., "€1,234")
  static String formatAmount(int amount) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;

    // Format with thousands separator
    final formatted = absAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return '${isNegative ? '-' : ''}€$formatted';
  }

  /// Calculate average daily spending rate
  ///
  /// [spentAmount] - Total spent in whole euros
  /// [daysPassed] - Number of days passed in budget period
  ///
  /// Returns average daily spending (can include cents)
  static double calculateDailyRate(int spentAmount, int daysPassed) {
    if (daysPassed <= 0) return 0.0;
    return spentAmount / daysPassed;
  }

  /// Project remaining budget until end of month
  ///
  /// [budgetAmount] - Budget amount in whole euros
  /// [spentAmount] - Spent amount in whole euros
  /// [daysPassed] - Days passed in current month
  /// [daysInMonth] - Total days in the month
  ///
  /// Returns projected remaining amount at month end (can be negative)
  static int projectMonthEnd(
    int budgetAmount,
    int spentAmount,
    int daysPassed,
    int daysInMonth,
  ) {
    if (daysPassed <= 0 || daysInMonth <= 0) return budgetAmount - spentAmount;

    final dailyRate = calculateDailyRate(spentAmount, daysPassed);
    final daysRemaining = daysInMonth - daysPassed;
    final projectedSpending = spentAmount + (dailyRate * daysRemaining);

    return budgetAmount - projectedSpending.ceil();
  }

  /// Validate budget amount
  ///
  /// [amount] - Budget amount to validate
  ///
  /// Returns error message if invalid, null if valid
  static String? validateBudgetAmount(int? amount) {
    if (amount == null) {
      return 'Budget amount is required';
    }

    if (amount < 0) {
      return 'Budget amount cannot be negative';
    }

    if (amount > 1000000) {
      return 'Budget amount cannot exceed €1,000,000';
    }

    return null; // Valid
  }

  /// Round expense amount up to whole euro
  ///
  /// [amount] - Expense amount (may include cents)
  ///
  /// Returns amount rounded up to nearest whole euro
  static int roundUpToWholeEuro(double amount) {
    return amount.ceil();
  }
}
