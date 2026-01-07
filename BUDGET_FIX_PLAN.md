# PIANO DI FIX PER IL SISTEMA BUDGET

## ANALISI COMPLETA DEL PROBLEMA

### 1. VERITÀ DEL DATABASE (fonte: migrations)

| Tabella | Colonna | Tipo | Unità | Migrazione |
|---------|---------|------|-------|------------|
| `expenses` | `amount` | **DECIMAL(10,2)** | **EURO** | 001_initial_schema.sql:47 |
| `group_budgets` | `amount` | **INTEGER** | **CENTS** | 011_create_group_budgets_table.sql:12 |
| `personal_budgets` | `amount` | **INTEGER** | **CENTS** | 012_create_personal_budgets_table.sql:12 |
| `category_budgets` | `amount` | **INTEGER** | **CENTS** | 026_category_budgets_table.sql:10 (commento esplicito) |

**CRITICO:** Migration 026 (riga 10) dice esplicitamente: `-- Stored in cents to avoid floating-point errors`

### 2. BUGS IDENTIFICATI

#### BUG #1: unified_budget_stats_provider.dart (PRINCIPALE)
**File:** `lib/features/budgets/presentation/providers/unified_budget_stats_provider.dart`
**Righe:** 113-122

```dart
// CODICE ATTUALE (SBAGLIATO):
int spentAmountCents = 0;
for (final expense in expenseData) {
  final amountEur = (expense['amount'] as num).toDouble();
  spentAmountCents += (amountEur * 100).toInt(); // ❌ Già in euro, converte in cents
}
int spentAmount = spentAmountCents;

// POI confronta con budgetAmount che è già in CENTS dal database!
final percentageUsed = budgetAmount > 0
    ? BudgetCalculator.calculatePercentageUsed(budgetAmount, spentAmount)
    : 0.0;
```

**PROBLEMA:**
- `budgetAmount` letto dal database = già in CENTS (es. 50000 = 500€)
- `expense['amount']` letto dal database = in EURO (es. 44.50)
- Il codice moltiplica per 100 → 4450 cents
- Ma poi confronta CENTS con... aspetta, cosa si aspetta BudgetCalculator?

#### BUG #2: BudgetCalculator non gestisce CENTS
**File:** `lib/core/utils/budget_calculator.dart`
**Commenti:** Righe 59-78 dicono "Budget amount in **whole euros**"

```dart
/// [budgetAmount] - Budget amount in whole euros  ← SBAGLIATO!
/// [spentAmount] - Spent amount in whole euros   ← SBAGLIATO!
static double calculatePercentageUsed(int budgetAmount, int spentAmount) {
  if (budgetAmount <= 0) return 0.0;
  final percentage = (spentAmount / budgetAmount) * 100;
  return double.parse(percentage.toStringAsFixed(2));
}
```

**Se i budget sono in CENTS:**
- budgetAmount = 50000 cents (500€)
- spentAmount (dopo il *100) = 4450 cents (44.50€)
- Percentuale = (4450 / 50000) * 100 = 8.9% ✅ CORRETTO!

**Quindi il calcolo FUNZIONA SE entrambi sono in cents!**

#### BUG #3: budget_provider.dart usa un sistema DIVERSO
**File:** `lib/features/budgets/presentation/providers/budget_provider.dart`
**Righe:** 263-269

```dart
// Questo provider USA ExpenseEntity.amount (double in euro)
final groupExpenses = currentMonthExpenses
    .where((e) => e.isGroupExpense)
    .map((e) => e.amount)  // ← double in EURO
    .toList();

final groupSpent = BudgetCalculator.calculateSpentAmount(groupExpenses);
// Questo restituisce INT in EURO INTERI (rounded up)
```

**BudgetCalculator.calculateSpentAmount:**
```dart
static int calculateSpentAmount(List<double> expenseAmounts) {
  final total = expenseAmounts.fold<double>(0.0, (sum, amount) => sum + amount);
  return total.ceil(); // ← Arrotonda a EURO INTERO
}
```

**PROBLEMA:** `budget_provider` usa EURO INTERI, non CENTS!

#### BUG #4: Documentazione Entity CONTRADDITTORIA

**GroupBudgetEntity** (line 24):
```dart
/// Budget amount in whole euros (no cents)  ← Dice EURO
final int amount;
```

**UnifiedBudgetStatsEntity** (line 62):
```dart
final int totalBudgeted; // in cents  ← Dice CENTS
final int totalSpent; // in cents
```

**BudgetStatsEntity** (line 21):
```dart
/// Budget amount in whole euros  ← Dice EURO
final int? budgetAmount;
```

**CategoryBudgetEntity** (line 13):
```dart
final int amount; // Budget amount in cents (EUR) - for FIXED type or fallback  ← Dice CENTS
```

### 3. WIDGET DISPLAY - Chi fa /100?

#### BudgetHeroCard (CORRETTO per CENTS):
```dart
// Righe 20-21
final int totalBudgeted; // in cents
final int totalSpent; // in cents

// Riga 96-97 - DIVIDE PER 100
'€${(remaining / 100).toStringAsFixed(2)}'
```

#### UnifiedCategoryCard (CORRETTO per CENTS):
```dart
// Riga 43 - DIVIDE PER 100
_amountController.text = (widget.category.budgetAmount / 100).toStringAsFixed(2);

// Riga 59 - MOLTIPLICA PER 100
final cents = (euros * 100).toInt();

// Riga 338 - DIVIDE PER 100
'€${(widget.category.spentAmount / 100).toStringAsFixed(0)}'
```

#### BudgetProgressBar (NON divide per 100):
```dart
// NO COMMENT sulle unità!
final int budgetAmount;
final int spentAmount;

// Passa direttamente a BudgetCalculator.formatAmount()
```

#### BudgetCalculator.formatAmount (si aspetta EURO, non CENTS):
```dart
/// [amount] - Amount in whole euros  ← commento
static String formatAmount(int amount) {
  // NON divide per 100
  return '€${_formatter.format(amount)}';
}
```

### 4. SISTEMA MISTO ATTUALE

**NUOVO SISTEMA (Unified Budget Dashboard):**
- Usa CENTS ovunque
- Widgets dividono per 100 per display
- ✅ Consistente

**VECCHIO SISTEMA (budget_provider + GroupBudgetCard):**
- Usa EURO INTERI
- Widgets NON dividono per 100
- ✅ Consistente (ma sistema diverso!)

**PROBLEMA:** I due sistemi convivono e il database ha CENTS ma alcuni provider pensano siano EURO!

---

## PIANO DI FIX

### OPZIONE A: STANDARDIZZA TUTTO SU CENTS (RACCOMANDATO)

#### Pro:
- Segue le migration (category_budgets già in cents)
- Evita floating point errors
- Più preciso
- Unified dashboard già usa cents

#### Contro:
- Richiede fix di TUTTI i provider e entity
- Richiede update della documentazione

### OPZIONE B: STANDARDIZZA TUTTO SU EURO INTERI

#### Pro:
- budget_provider già usa euro
- GroupBudgetEntity/PersonalBudgetEntity già documentati come euro

#### Contro:
- Contraddice migration 026
- Perde precisione (no cents)
- Richiede migrazione database

---

## FIX RACCOMANDATO: OPZIONE A (CENTS OVUNQUE)

### STEP 1: Fix unified_budget_stats_provider.dart

```dart
// PRIMA (SBAGLIATO):
int spentAmountCents = 0;
for (final expense in expenseData) {
  final amountEur = (expense['amount'] as num).toDouble();
  spentAmountCents += (amountEur * 100).toInt();
}
int spentAmount = spentAmountCents;

// DOPO (CORRETTO):
int spentAmountCents = 0;
for (final expense in expenseData) {
  final amountEur = (expense['amount'] as num).toDouble(); // DECIMAL in euro
  spentAmountCents += (amountEur * 100).round(); // Converti euro → cents
}
// budgetAmount è già in CENTS dal DB, quindi OK confrontare
final percentageUsed = budgetAmount > 0
    ? BudgetCalculator.calculatePercentageUsed(budgetAmount, spentAmountCents)
    : 0.0;
```

**MA ASPETTA!** BudgetCalculator si aspetta cents o euro?

### STEP 2: Verificare TUTTI gli usi di BudgetCalculator

**Verifica chi chiama:**
1. unified_budget_stats_provider → passa CENTS (dopo il fix)
2. budget_provider → passa EURO INTERI

**CONFLITTO!** Due provider passano unità diverse!

### STEP 3: Refactor BudgetCalculator per gestire CENTS

```dart
/// [budgetAmount] - Budget amount in CENTS
/// [spentAmount] - Spent amount in CENTS
static double calculatePercentageUsed(int budgetAmountCents, int spentAmountCents) {
  if (budgetAmountCents <= 0) return 0.0;
  final percentage = (spentAmountCents / budgetAmountCents) * 100;
  return double.parse(percentage.toStringAsFixed(2));
}

/// [amount] - Amount in CENTS
static String formatAmount(int amountCents) {
  final euros = amountCents / 100.0;
  return '€${_formatter.format(euros.toStringAsFixed(2))}';
}
```

### STEP 4: Fix budget_provider.dart per usare CENTS

```dart
// Converti expenses (euro) → cents
final groupExpenses = currentMonthExpenses
    .where((e) => e.isGroupExpense)
    .map((e) => (e.amount * 100).round()) // ← Converti a cents
    .toList();

// Somma cents
final groupSpentCents = groupExpenses.fold<int>(0, (sum, cents) => sum + cents);

// budgetAmount è già in cents dal DB (group_budgets.amount INTEGER = cents)
final groupBudgetAmountCents = state.groupBudget?.amount ?? 0;
```

### STEP 5: Update tutte le Entity docs

- GroupBudgetEntity: "amount in cents" (non "whole euros")
- PersonalBudgetEntity: "amount in cents"
- BudgetStatsEntity: "amount in cents"
- Tutti coerenti con CategoryBudgetEntity

### STEP 6: Verifica widget display

- BudgetProgressBar: aggiungere docs "expects cents"
- BudgetWarningIndicator: verificare se divide per 100
- Tutti i widget che mostrano € devono fare `/100`

---

## TESTING PLAN

### Test 1: Spesa 44.50€, Budget 500€
- Database: expense.amount = 44.50 (DECIMAL)
- Database: category_budget.amount = 50000 (INTEGER cents)
- Provider: spentCents = 4450, budgetCents = 50000
- Calcolo: (4450 / 50000) * 100 = 8.9%
- Display: 44€ / 500€ (arrotonda spesa up)

### Test 2: Spesa 690€, Budget 1000€
- Database: expenses total = 690.00 (DECIMAL)
- Database: category_budget.amount = 100000 (INTEGER cents)
- Provider: spentCents = 69000, budgetCents = 100000
- Calcolo: (69000 / 100000) * 100 = 69%
- Display: 690€ / 1000€

---

## FILE DA MODIFICARE

1. ✅ `unified_budget_stats_provider.dart` - Fix conversione cents
2. ✅ `budget_provider.dart` - Passa cents invece di euro
3. ✅ `budget_calculator.dart` - Update docs + formatAmount
4. ✅ `group_budget_entity.dart` - Update docs
5. ✅ `personal_budget_entity.dart` - Update docs
6. ✅ `budget_stats_entity.dart` - Update docs
7. ✅ `budget_progress_bar.dart` - Update docs + verify display
8. ✅ `budget_warning_indicator.dart` - Verify /100 conversion

---

## PRIORITÀ

**P0 - CRITICO (causa bug display):**
1. unified_budget_stats_provider.dart - Fix NOW

**P1 - ALTO (inconsistenza):**
2. budget_calculator.dart - Update docs
3. BudgetStatsEntity - Fix docs

**P2 - MEDIO (best practice):**
4. budget_provider.dart - Standardize to cents
5. All entity docs - Make consistent

**P3 - BASSO (nice to have):**
6. Widget docs - Clarify units expected
