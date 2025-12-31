# Widget Update Interface Contract

**Feature**: 003-home-budget-widget
**Date**: 2025-12-31
**Purpose**: Define the interface between Flutter app and native widget platforms

---

## Overview

This contract specifies how the Flutter application communicates widget data to native Android and iOS widgets, and how native widgets trigger updates.

---

## Flutter → Native Data Flow

### Shared Data Keys

**Standard Keys** (used by both platforms):

| Key | Type | Description | Example |
|-----|------|-------------|---------|
| `spent` | double | Total amount spent in current month | `450.50` |
| `limit` | double | Monthly budget limit | `800.00` |
| `month` | string | Current month display | `"Dicembre 2025"` |
| `percentage` | double | Budget percentage (0-100+) | `56.31` |
| `currency` | string | Currency symbol | `"€"` |
| `isDarkMode` | boolean | Current theme mode | `false` |
| `lastUpdated` | long | Timestamp in milliseconds since epoch | `1735653000000` |
| `groupName` | string | Family group name (optional) | `"Famiglia Rossi"` |

### Flutter Implementation

**Using home_widget Plugin**:

```dart
import 'package:home_widget/home_widget.dart';

Future<void> updateWidget(WidgetDataEntity data) async {
  // Save each field
  await HomeWidget.saveWidgetData<double>('spent', data.spent);
  await HomeWidget.saveWidgetData<double>('limit', data.limit);
  await HomeWidget.saveWidgetData<String>('month', data.month);
  await HomeWidget.saveWidgetData<double>('percentage', data.percentage);
  await HomeWidget.saveWidgetData<String>('currency', data.currency);
  await HomeWidget.saveWidgetData<bool>('isDarkMode', data.isDarkMode);
  await HomeWidget.saveWidgetData<int>('lastUpdated', data.lastUpdated.millisecondsSinceEpoch);
  await HomeWidget.saveWidgetData<String>('groupName', data.groupName ?? '');

  // Trigger widget refresh
  await HomeWidget.updateWidget(
    androidName: 'BudgetWidgetProvider',
    iOSName: 'BudgetWidget',
  );
}
```

---

## Android Widget Interface

### Provider Class

**File**: `android/app/src/main/kotlin/com/family/expense_tracker/widget/BudgetWidgetProvider.kt`

**Contract**:

```kotlin
class BudgetWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Read data from SharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val spent = prefs.getFloat("flutter.spent", 0f).toDouble()
        val limit = prefs.getFloat("flutter.limit", 1000f).toDouble()
        val month = prefs.getString("flutter.month", "") ?: ""
        val percentage = prefs.getFloat("flutter.percentage", 0f).toDouble()
        val currency = prefs.getString("flutter.currency", "€") ?: "€"
        val isDarkMode = prefs.getBoolean("flutter.isDarkMode", false)
        val lastUpdated = prefs.getLong("flutter.lastUpdated", 0L)
        val groupName = prefs.getString("flutter.groupName", "") ?: ""

        // Determine widget size
        val widgetOptions = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val widgetSize = getWidgetSize(widgetOptions)

        // Select appropriate layout
        val layoutId = when (widgetSize) {
            WidgetSize.SMALL -> R.layout.widget_budget_small
            WidgetSize.MEDIUM -> R.layout.widget_budget_medium
            WidgetSize.LARGE -> R.layout.widget_budget_large
        }

        // Build RemoteViews
        val views = RemoteViews(context.packageName, layoutId)

        // Update UI elements
        views.setTextViewText(R.id.text_spent, formatAmount(spent, currency))
        views.setTextViewText(R.id.text_limit, formatAmount(limit, currency))
        views.setTextViewText(R.id.text_month, month)
        views.setTextViewText(R.id.text_percentage, "${percentage.toInt()}%")
        views.setProgressBar(R.id.progress_bar, 100, percentage.toInt(), false)

        // Apply theme colors
        applyTheme(views, isDarkMode, percentage)

        // Set deep link intents
        views.setOnClickPendingIntent(
            R.id.button_scan,
            createDeepLinkIntent(context, "/scan-receipt")
        )
        views.setOnClickPendingIntent(
            R.id.button_manual,
            createDeepLinkIntent(context, "/add-expense")
        )
        views.setOnClickPendingIntent(
            R.id.budget_container,
            createDeepLinkIntent(context, "/dashboard")
        )

        // Update widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun applyTheme(views: RemoteViews, isDarkMode: Boolean, percentage: Double) {
        val backgroundColor = if (isDarkMode) {
            ContextCompat.getColor(context, R.color.widget_bg_dark)
        } else {
            ContextCompat.getColor(context, R.color.widget_bg_light)
        }

        val progressColor = when {
            percentage >= 100 -> ContextCompat.getColor(context, R.color.budget_critical)
            percentage >= 80 -> ContextCompat.getColor(context, R.color.budget_warning)
            else -> ContextCompat.getColor(context, R.color.budget_normal)
        }

        views.setInt(R.id.widget_root, "setBackgroundColor", backgroundColor)
        views.setProgressBar(R.id.progress_bar, 100, percentage.toInt(), false)
        // Note: Progress bar color set via XML drawable
    }

    enum class WidgetSize {
        SMALL, MEDIUM, LARGE
    }

    private fun getWidgetSize(options: Bundle): WidgetSize {
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        return when {
            width < 200 -> WidgetSize.SMALL
            width < 300 -> WidgetSize.MEDIUM
            else -> WidgetSize.LARGE
        }
    }
}
```

### Background Update Worker

**File**: `android/app/src/main/kotlin/com/family/expense_tracker/widget/WidgetUpdateWorker.kt`

**Contract**:

```kotlin
class WidgetUpdateWorker(
    context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    override fun doWork(): Result {
        return try {
            // Trigger widget update
            val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
            intent.component = ComponentName(applicationContext, BudgetWidgetProvider::class.java)
            applicationContext.sendBroadcast(intent)

            Result.success()
        } catch (e: Exception) {
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }
}
```

### Widget Metadata

**File**: `android/app/src/main/res/xml/budget_widget_info.xml`

**Contract**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:maxResizeWidth="360dp"
    android:maxResizeHeight="360dp"
    android:resizeMode="horizontal|vertical"
    android:initialLayout="@layout/widget_budget_medium"
    android:configure="com.family.expense_tracker.widget.BudgetWidgetConfigActivity"
    android:previewImage="@drawable/widget_preview"
    android:description="@string/widget_description"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="0">
    <!-- updatePeriodMillis="0" because we use WorkManager for updates -->
</appwidget-provider>
```

---

## iOS Widget Interface

### Widget Provider

**File**: `ios/BudgetWidgetExtension/BudgetWidget.swift`

**Contract**:

```swift
import WidgetKit
import SwiftUI

struct BudgetWidget: Widget {
    let kind: String = "BudgetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("Budget Mensile")
        .description("Visualizza il tuo budget mensile e aggiungi spese rapidamente")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct BudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(
            date: Date(),
            spent: 450.0,
            limit: 800.0,
            month: "Dicembre 2025",
            percentage: 56.25,
            currency: "€",
            isDarkMode: false,
            groupName: "Famiglia"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> ()) {
        let entry = loadWidgetData() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> ()) {
        var entries: [BudgetEntry] = []

        // Load current data
        let currentData = loadWidgetData() ?? placeholder(in: context)

        // Generate hourly entries for next 24 hours
        let currentDate = Date()
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = BudgetEntry(
                date: entryDate,
                spent: currentData.spent,
                limit: currentData.limit,
                month: currentData.month,
                percentage: currentData.percentage,
                currency: currentData.currency,
                isDarkMode: currentData.isDarkMode,
                groupName: currentData.groupName
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func loadWidgetData() -> BudgetEntry? {
        // Read from App Group shared container
        let sharedDefaults = UserDefaults(suiteName: "group.com.family.financetracker")

        guard let spent = sharedDefaults?.double(forKey: "flutter.spent"),
              let limit = sharedDefaults?.double(forKey: "flutter.limit"),
              let month = sharedDefaults?.string(forKey: "flutter.month"),
              let percentage = sharedDefaults?.double(forKey: "flutter.percentage") else {
            return nil
        }

        let currency = sharedDefaults?.string(forKey: "flutter.currency") ?? "€"
        let isDarkMode = sharedDefaults?.bool(forKey: "flutter.isDarkMode") ?? false
        let groupName = sharedDefaults?.string(forKey: "flutter.groupName") ?? ""

        return BudgetEntry(
            date: Date(),
            spent: spent,
            limit: limit,
            month: month,
            percentage: percentage,
            currency: currency,
            isDarkMode: isDarkMode,
            groupName: groupName
        )
    }
}

struct BudgetEntry: TimelineEntry {
    let date: Date
    let spent: Double
    let limit: Double
    let month: String
    let percentage: Double
    let currency: String
    let isDarkMode: Bool
    let groupName: String
}
```

### Widget View

**File**: `ios/BudgetWidgetExtension/BudgetWidgetView.swift`

**Contract**:

```swift
struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    var entry: BudgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, colorScheme: colorScheme)
        case .systemMedium:
            MediumWidgetView(entry: entry, colorScheme: colorScheme)
        case .systemLarge:
            LargeWidgetView(entry: entry, colorScheme: colorScheme)
        @unknown default:
            MediumWidgetView(entry: entry, colorScheme: colorScheme)
        }
    }
}

struct MediumWidgetView: View {
    let entry: BudgetEntry
    let colorScheme: ColorScheme

    var progressColor: Color {
        switch entry.percentage {
        case 100...:
            return .red
        case 80..<100:
            return .orange
        default:
            return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text(entry.month)
                .font(.caption)
                .foregroundColor(.secondary)

            // Budget display with tap to dashboard
            Link(destination: URL(string: "https://fin.app/dashboard")!) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(entry.currency)\(String(format: "%.2f", entry.spent))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/ \(entry.currency)\(String(format: "%.0f", entry.limit))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: entry.percentage, total: 100)
                        .tint(progressColor)

                    Text("\(Int(entry.percentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                Link(destination: URL(string: "https://fin.app/scan-receipt")!) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Scansiona")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Link(destination: URL(string: "https://fin.app/add-expense")!) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Manuale")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}
```

---

## Update Trigger Mechanism

### Flutter App → Widget Update

**Trigger Points**:
1. User adds new expense (manual or scanner)
2. User edits/deletes expense
3. Budget limit changed in settings
4. Group switched
5. App foreground (refresh stale data)
6. Background refresh timer (15-30 min)

**Implementation**:

```dart
class WidgetUpdateService {
  final WidgetRepository _widgetRepository;

  Future<void> triggerUpdate() async {
    final result = await _widgetRepository.getWidgetData();

    result.fold(
      (failure) => _handleFailure(failure),
      (data) async {
        await _widgetRepository.saveWidgetData(data);
        await _widgetRepository.updateWidget();
      },
    );
  }

  void _handleFailure(Failure failure) {
    // Log error but don't throw - widget update is not critical
    debugPrint('Widget update failed: $failure');
  }
}

// Usage in ExpenseProvider
@riverpod
class ExpenseForm extends _$ExpenseForm {
  Future<ExpenseEntity?> createExpense(...) async {
    final expense = await _repository.createExpense(...);

    if (expense != null) {
      // Trigger widget update
      ref.read(widgetUpdateServiceProvider).triggerUpdate();
    }

    return expense;
  }
}
```

### Background Refresh Registration

**Android (WorkManager)**:

```dart
Future<void> registerAndroidBackgroundRefresh() async {
  if (!Platform.isAndroid) return;

  await HomeWidget.registerBackgroundUpdate(
    androidName: 'BudgetWidgetProvider',
    callback: _backgroundUpdateCallback,
  );
}

@pragma('vm:entry-point')
Future<void> _backgroundUpdateCallback() async {
  // This runs in isolate, minimal work only
  final widgetData = await _fetchWidgetData();
  await _updateWidgetData(widgetData);
}
```

**iOS (Timeline Reload)**:

```dart
Future<void> triggerIOSTimelineReload() async {
  if (!Platform.isIOS) return;

  await HomeWidget.updateWidget(
    iOSName: 'BudgetWidget',
  );
  // iOS WidgetKit automatically calls getTimeline() on widget provider
}
```

---

## Error States & Fallbacks

### Missing Data Handling

**Android**:
```kotlin
val spent = prefs.getFloat("flutter.spent", -1f)
if (spent < 0) {
    // Show "Budget non configurato" message
    views.setViewVisibility(R.id.error_message, View.VISIBLE)
    views.setViewVisibility(R.id.budget_content, View.GONE)
    views.setTextViewText(R.id.error_message, "Budget non configurato")
    return
}
```

**iOS**:
```swift
guard let entry = loadWidgetData() else {
    return Text("Budget non configurato")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

### Stale Data Indicator

**Check last update timestamp**:

```kotlin
val lastUpdated = prefs.getLong("flutter.lastUpdated", 0L)
val now = System.currentTimeMillis()
val minutesSinceUpdate = (now - lastUpdated) / 60000

if (minutesSinceUpdate > 5) {
    views.setViewVisibility(R.id.stale_indicator, View.VISIBLE)
    views.setTextViewText(R.id.stale_text, "Aggiornato $minutesSinceUpdate min fa")
}
```

---

## Performance Requirements

| Operation | Target | Platform |
|-----------|--------|----------|
| Widget render | < 500ms | Both |
| Data read from storage | < 50ms | Both |
| Flutter → Native update | < 100ms | Both |
| Background refresh | < 5s | Both |

**Memory Constraints**:
- Widget process: < 5MB RAM
- Cached data: < 1KB

---

**Contract Complete**: Widget update interface fully specified
**Next**: quickstart.md for setup and testing procedures
