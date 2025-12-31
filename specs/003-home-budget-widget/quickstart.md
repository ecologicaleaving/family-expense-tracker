# Quickstart Guide: Home Screen Budget Widget

**Feature**: 003-home-budget-widget
**Date**: 2025-12-31
**Purpose**: Step-by-step setup and testing guide for developers

---

## Prerequisites

### Required Tools

- **Flutter SDK**: 3.0+ (verify: `flutter --version`)
- **Android Studio**: Latest stable (for Android development)
- **Xcode**: 15+ (for iOS development, macOS only)
- **Android SDK**: API 24+ (already configured in project)
- **iOS Deployment Target**: 14.0+ (required for WidgetKit)

### Existing Project Setup

This feature extends the existing Fin app. Ensure you have:
- ✅ Project cloned and dependencies installed (`flutter pub get`)
- ✅ Supabase backend configured (`.env` file present)
- ✅ Existing features working (auth, expenses, dashboard)

---

## Phase 1: Add Dependencies

### 1. Update `pubspec.yaml`

Add the `home_widget` package:

```yaml
dependencies:
  # ... existing dependencies ...

  # Widget support
  home_widget: ^0.6.0
```

Run:
```bash
flutter pub get
```

---

## Phase 2: Android Setup

### 1. Create Widget Provider

**File**: `android/app/src/main/kotlin/com/family/expense_tracker/widget/BudgetWidgetProvider.kt`

```kotlin
package com.family.expense_tracker.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.family.expense_tracker.R

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
        val views = RemoteViews(context.packageName, R.layout.widget_budget_medium)

        // Read data from SharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val spent = prefs.getFloat("flutter.spent", 0f).toDouble()
        val limit = prefs.getFloat("flutter.limit", 800f).toDouble()
        val month = prefs.getString("flutter.month", "Budget") ?: "Budget"
        val percentage = prefs.getFloat("flutter.percentage", 0f).toInt()

        // Update UI
        views.setTextViewText(R.id.text_month, month)
        views.setTextViewText(R.id.text_spent, "€${"%.2f".format(spent)}")
        views.setTextViewText(R.id.text_limit, "/ €${"%.0f".format(limit)}")
        views.setTextViewText(R.id.text_percentage, "$percentage%")
        views.setProgressBar(R.id.progress_bar, 100, percentage, false)

        // Set deep links
        views.setOnClickPendingIntent(R.id.button_scan, createIntent(context, "/scan-receipt"))
        views.setOnClickPendingIntent(R.id.button_manual, createIntent(context, "/add-expense"))
        views.setOnClickPendingIntent(R.id.budget_container, createIntent(context, "/dashboard"))

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun createIntent(context: Context, path: String): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("finapp://$path"))
        return PendingIntent.getActivity(
            context,
            path.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
```

### 2. Create Widget Layout

**File**: `android/app/src/main/res/layout/widget_budget_medium.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/widget_background">

    <!-- Header -->
    <TextView
        android:id="@+id/text_month"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Dicembre 2025"
        android:textSize="12sp"
        android:textColor="?android:textColorSecondary" />

    <!-- Budget Display (tappable to dashboard) -->
    <LinearLayout
        android:id="@+id/budget_container"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:layout_marginTop="8dp"
        android:clickable="true"
        android:focusable="true">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal">

            <TextView
                android:id="@+id/text_spent"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="€450.00"
                android:textSize="24sp"
                android:textStyle="bold"
                android:textColor="?android:textColorPrimary" />

            <TextView
                android:id="@+id/text_limit"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="/ €800"
                android:textSize="16sp"
                android:layout_marginStart="4dp"
                android:layout_gravity="bottom"
                android:textColor="?android:textColorSecondary" />
        </LinearLayout>

        <ProgressBar
            android:id="@+id/progress_bar"
            style="@android:style/Widget.ProgressBar.Horizontal"
            android:layout_width="match_parent"
            android:layout_height="8dp"
            android:layout_marginTop="4dp"
            android:max="100"
            android:progress="56" />

        <TextView
            android:id="@+id/text_percentage"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="56%"
            android:textSize="12sp"
            android:layout_marginTop="2dp"
            android:textColor="?android:textColorSecondary" />
    </LinearLayout>

    <Space
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />

    <!-- Action Buttons -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal">

        <Button
            android:id="@+id/button_scan"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Scansiona"
            android:textSize="12sp"
            android:layout_marginEnd="8dp"
            style="@style/Widget.Material3.Button" />

        <Button
            android:id="@+id/button_manual"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Manuale"
            android:textSize="12sp"
            style="@style/Widget.Material3.Button" />
    </LinearLayout>

</LinearLayout>
```

### 3. Create Widget Background

**File**: `android/app/src/main/res/drawable/widget_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="?android:colorBackground" />
    <corners android:radius="16dp" />
</shape>
```

### 4. Define Widget Metadata

**File**: `android/app/src/main/res/xml/budget_widget_info.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:resizeMode="horizontal|vertical"
    android:initialLayout="@layout/widget_budget_medium"
    android:description="Visualizza budget mensile e aggiungi spese"
    android:widgetCategory="home_screen"
    android:updatePeriodMillis="0" />
```

### 5. Register Widget in Manifest

**File**: `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:

```xml
<!-- Widget Provider -->
<receiver
    android:name=".widget.BudgetWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/budget_widget_info" />
</receiver>
```

### 6. Add Deep Link Support

In the same `AndroidManifest.xml`, inside `<activity android:name=".MainActivity">`:

```xml
<!-- Deep Links -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="finapp" />
</intent-filter>
```

---

## Phase 3: iOS Setup

### 1. Add Widget Extension in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. **File** → **New** → **Target**
3. Select **Widget Extension**
4. Name: `BudgetWidgetExtension`
5. Language: **Swift**
6. Uncheck "Include Configuration Intent"
7. Click **Finish**
8. Activate the scheme when prompted

### 2. Configure App Groups

**For Runner (main app)**:
1. Select **Runner** target
2. **Signing & Capabilities** tab
3. Click **+ Capability** → **App Groups**
4. Click **+** and create: `group.com.family.financetracker`
5. Enable the checkbox

**For BudgetWidgetExtension**:
1. Select **BudgetWidgetExtension** target
2. Repeat steps 2-5 above with **same App Group ID**

### 3. Create Widget Provider

**File**: `ios/BudgetWidgetExtension/BudgetWidget.swift`

Replace default content with:

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
        .description("Visualizza budget e aggiungi spese")
        .supportedFamilies([.systemMedium])
    }
}

struct BudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: Date(), spent: 450, limit: 800, month: "Dicembre 2025", percentage: 56)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> ()) {
        let entry = loadData() ?? placeholder(in: context)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadData() ?? placeholder(in: context)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    func loadData() -> BudgetEntry? {
        let sharedDefaults = UserDefaults(suiteName: "group.com.family.financetracker")
        guard let spent = sharedDefaults?.double(forKey: "flutter.spent"),
              let limit = sharedDefaults?.double(forKey: "flutter.limit"),
              let month = sharedDefaults?.string(forKey: "flutter.month"),
              let percentage = sharedDefaults?.double(forKey: "flutter.percentage") else {
            return nil
        }
        return BudgetEntry(date: Date(), spent: spent, limit: limit, month: month, percentage: percentage)
    }
}

struct BudgetEntry: TimelineEntry {
    let date: Date
    let spent: Double
    let limit: Double
    let month: String
    let percentage: Double
}

struct BudgetWidgetView: View {
    var entry: BudgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.month)
                .font(.caption)
                .foregroundColor(.secondary)

            Link(destination: URL(string: "finapp://dashboard")!) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("€\(entry.spent, specifier: "%.2f")")
                            .font(.title2)
                            .bold()
                        Text("/ €\(entry.limit, specifier: "%.0f")")
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: entry.percentage, total: 100)
                    Text("\(Int(entry.percentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack {
                Link(destination: URL(string: "finapp://scan-receipt")!) {
                    Text("Scansiona")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Link(destination: URL(string: "finapp://add-expense")!) {
                    Text("Manuale")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
```

### 4. Configure Deep Links in Flutter App

**File**: `ios/Runner/Info.plist`

Add:

```xml
<key>FlutterDeepLinkingEnabled</key>
<true/>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>finapp</string>
        </array>
    </dict>
</array>
```

---

## Phase 4: Flutter Integration

### 1. Create Widget Repository

**File**: `lib/features/widget/domain/repositories/widget_repository.dart`

```dart
abstract class WidgetRepository {
  Future<Either<Failure, void>> updateWidget();
}
```

**File**: `lib/features/widget/data/repositories/widget_repository_impl.dart`

```dart
import 'package:home_widget/home_widget.dart';

class WidgetRepositoryImpl implements WidgetRepository {
  @override
  Future<Either<Failure, void>> updateWidget() async {
    try {
      // Get current budget data
      final stats = await _dashboardRepository.getStats();

      // Save to widget storage
      await HomeWidget.saveWidgetData('spent', stats.totalSpent);
      await HomeWidget.saveWidgetData('limit', stats.monthlyBudget);
      await HomeWidget.saveWidgetData('month', _formatMonth(DateTime.now()));
      await HomeWidget.saveWidgetData('percentage', (stats.totalSpent / stats.monthlyBudget) * 100);

      // Trigger update
      await HomeWidget.updateWidget(
        androidName: 'BudgetWidgetProvider',
        iOSName: 'BudgetWidget',
      );

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure());
    }
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy', 'it').format(date);
  }
}
```

### 2. Create Widget Update Service

**File**: `lib/features/widget/presentation/services/widget_update_service.dart`

```dart
class WidgetUpdateService {
  final WidgetRepository _repository;

  WidgetUpdateService(this._repository);

  Future<void> triggerUpdate() async {
    await _repository.updateWidget();
  }
}
```

### 3. Integrate with Expense Provider

**File**: `lib/features/expenses/presentation/providers/expense_provider.dart`

Add widget update trigger:

```dart
@riverpod
class ExpenseForm extends _$ExpenseForm {
  Future<ExpenseEntity?> createExpense(...) async {
    final expense = await _repository.createExpense(...);

    if (expense != null) {
      // Refresh dashboard
      ref.read(dashboardProvider.notifier).refresh();

      // Update widget
      ref.read(widgetUpdateServiceProvider).triggerUpdate();
    }

    return expense;
  }
}
```

---

## Phase 5: Testing

### Android Testing

#### 1. Install App
```bash
flutter run -d <android-device>
```

#### 2. Add Widget to Home Screen
1. Long-press on home screen
2. Tap "Widgets"
3. Find "Fin" app widgets
4. Drag "Budget Mensile" widget to home screen

#### 3. Test Deep Links
```bash
# Test scanner link
adb shell am start -a android.intent.action.VIEW -d "finapp://scan-receipt"

# Test manual entry link
adb shell am start -a android.intent.action.VIEW -d "finapp://add-expense"

# Test dashboard link
adb shell am start -a android.intent.action.VIEW -d "finapp://dashboard"
```

#### 4. Test Widget Update
1. Add a new expense in the app
2. Go to home screen
3. Widget should update within 1-2 seconds

### iOS Testing

#### 1. Run App
```bash
flutter run -d <ios-device>
```

#### 2. Add Widget to Home Screen
1. Long-press on home screen
2. Tap **+** button (top-left)
3. Search for "Fin"
4. Select "Budget Mensile"
5. Tap "Add Widget"

#### 3. Test Deep Links
1. Create a note with link: `finapp://dashboard`
2. Tap the link
3. App should open to dashboard

#### 4. Test Widget Update
1. Add expense in app
2. Go to home screen
3. Wait up to 30 seconds for widget refresh

---

## Troubleshooting

### Android

**Widget not appearing**:
- Check `AndroidManifest.xml` has correct `<receiver>` declaration
- Verify widget layout XML exists and is valid
- Check Logcat for errors: `adb logcat | grep BudgetWidget`

**Widget not updating**:
- Verify SharedPreferences data: `adb shell run-as com.family.expense_tracker cat /data/data/com.family.expense_tracker/shared_prefs/FlutterSharedPreferences.xml`
- Check widget provider is receiving update broadcast

**Deep links not working**:
- Verify `<intent-filter>` in manifest
- Test with: `adb shell am start -a android.intent.action.VIEW -d "finapp://dashboard"`

### iOS

**Widget not appearing**:
- Ensure Widget Extension target is added to Xcode project
- Verify App Groups are configured for both targets
- Check scheme includes Widget Extension

**Widget not updating**:
- Verify App Group suite name matches in Flutter and Swift code
- Check widget data in debug: Add `print()` statements in `loadData()`
- Ensure widget timeline policy is `.atEnd` not `.never`

**Deep links not working**:
- Verify `CFBundleURLTypes` in `Info.plist`
- Test with: `xcrun simctl openurl booted finapp://dashboard`

---

## Next Steps

1. ✅ Basic widget working on both platforms
2. → Add multiple widget sizes (small, medium, large)
3. → Implement theme support (light/dark)
4. → Add background refresh with WorkManager (Android)
5. → Add proper error states (no data, offline, etc.)
6. → Write automated tests

---

**Quickstart Complete**: Widget should now be installable and functional!
**For Implementation Tasks**: See `/speckit.tasks` command to generate task breakdown
