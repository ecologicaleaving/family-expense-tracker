# Research: Home Screen Budget Widget

**Feature**: 003-home-budget-widget
**Date**: 2025-12-31
**Purpose**: Technical research for implementing native Android/iOS home screen widgets in Flutter app

---

## 1. home_widget Package Evaluation

### Decision
Use **home_widget ^0.6.0** as the primary package for cross-platform home screen widget implementation.

### Rationale
The home_widget package provides a unified API for both Android App Widgets and iOS WidgetKit, eliminating the need to manage separate platform implementations. It's officially recommended in Google's Flutter codelabs and has demonstrated active maintenance with recent updates in 2025.

### Platform Support Status
- **Android**: Full support via Android App Widget Framework using XML layouts and Kotlin
- **iOS**: Full support via WidgetKit (iOS 14+)
- **Compatibility**: Works with Flutter 3.0+ (verified as of 2025)

### Known Limitations
- **No Native Flutter UI**: Cannot render Flutter widgets directly in home screen widgets - must use platform-native UI frameworks (XML/Jetpack Compose for Android, SwiftUI for iOS)
- **Platform-Specific Tools Required**: Still requires Xcode for iOS widgets and Android Studio for Android widgets
- **Separate Extension Required**: iOS widgets require a separate Widget Extension target in Xcode

### Alternatives Considered
- **flutter_widgetkit**: iOS-only solution. Rejected because it doesn't provide Android support.
- **Manual Native Implementation**: Building separate Android and iOS widgets without a Flutter bridge. Rejected due to code duplication and maintenance overhead.

---

## 2. Deep Linking Patterns in Flutter

### Decision
Implement **go_router** (existing dependency) with HTTPS-based deep links (App Links/Universal Links) for production, with custom URL scheme as fallback for development.

### Rationale
go_router is already used in the project and provides URL-based navigation that aligns perfectly with deep linking. HTTPS links are secure and professional.

### URL Scheme Strategy
- **Production**: HTTPS links (`https://fin.app/scan-receipt`, `https://fin.app/add-expense`)
  - Secure and cannot be hijacked by other apps
  - Falls back to website when app not installed
- **Development**: Custom URL scheme (`finapp://scan-receipt`)
  - Quick to set up without domain verification
  - Useful for testing

### Platform-Specific Configuration

**Android (`AndroidManifest.xml`):**
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="fin.app" />
    <data android:scheme="finapp" />
</intent-filter>
```

**iOS (`Info.plist`):**
```xml
<key>FlutterDeepLinkingEnabled</key>
<true/>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>fin.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>finapp</string>
        </array>
    </dict>
</array>
```

### Handling Deep Links Across App States

**Cold Start (App Not Running):**
- Use `getInitialLink()` to retrieve the deep link that launched the app
- Implement in `main()` using `WidgetsBinding.instance.addPostFrameCallback()`

**Warm Start (App Running/Background):**
- Use `uriLinkStream.listen()` to handle incoming links
- Subscribe to stream in app initialization

**Best Practices:**
- Wrap deep link processing in try-catch blocks
- Implement error handling for invalid routes
- Use go_router's redirect functionality for authentication checks

### Alternatives Considered
- **uni_links**: Previously popular but now superseded by app_links package. Rejected for being outdated.
- **Firebase Dynamic Links**: Over-engineered for simple deep linking needs. Rejected due to unnecessary complexity.

---

## 3. Widget Background Refresh Strategies

### Decision
Use **Android WorkManager** for Android widgets and **iOS WidgetKit Timeline API** for iOS widgets, with conservative update frequencies (15-30 minutes minimum).

### Rationale
WorkManager provides reliable periodic updates on Android with flexible scheduling, while WidgetKit's timeline approach is the only official way to refresh iOS widgets. Both platforms impose system-level restrictions to preserve battery life.

### Android WorkManager Implementation

**Update Frequency:**
- **Minimum**: 15 minutes (WorkManager MIN_PERIODIC_INTERVAL_MILLIS)
- **Recommended**: 15-30 minutes for balance between freshness and battery
- **Configuration**: Set `updatePeriodMillis="0"` in appwidget XML to disable legacy updates

**Retry Logic:**
- **Default Backoff**: Exponential (BackoffPolicy.EXPONENTIAL)
- **Retry Intervals**: 30s → 60s → 120s → 240s (up to 5 hours max)
- **Custom Retry**: Check `runAttemptCount` and return `Result.retry()` for temporary failures

**Example:**
```kotlin
val updateRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
    15, TimeUnit.MINUTES
).setBackoffCriteria(
    BackoffPolicy.EXPONENTIAL,
    WorkRequest.MIN_BACKOFF_MILLIS,
    TimeUnit.MILLISECONDS
).build()
```

### iOS WidgetKit Timeline Implementation

**Update Frequency:**
- **System Limit**: 40-70 refreshes per day (roughly 15-60 minutes)
- **Recommended**: Provide 24-hour timeline with hourly entries, let system optimize refresh

**Timeline Strategy:**
```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    var entries: [SimpleEntry] = []

    // Generate hourly entries for next 24 hours
    for hourOffset in 0..<24 {
        let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: Date())!
        let entry = SimpleEntry(date: entryDate, data: fetchData())
        entries.append(entry)
    }

    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
}
```

### Battery Optimization Guidelines
- **Minimize Wake-Ups**: Batch updates when possible
- **Network Efficiency**: Use compressed payloads, cache aggressively
- **Conditional Updates**: Only refresh when data actually changed

### Alternatives Considered
- **AlarmManager (Android)**: Deprecated for background work, less reliable than WorkManager. Rejected.
- **Background Fetch (iOS)**: Not suitable for widget updates. Rejected.
- **Push Notifications for Updates**: Adds server complexity. Rejected for simple periodic updates.

---

## 4. Widget Data Persistence

### Decision
Use **shared_preferences** plugin (existing dependency) with platform-native storage (SharedPreferences on Android, UserDefaults with App Groups on iOS) for widget state persistence.

### Rationale
The shared_preferences plugin provides a unified API that wraps native storage mechanisms. For iOS, App Groups enable data sharing between the main app and widget extension.

### Data Storage Architecture

**Android Implementation:**
- **Storage**: SharedPreferences in `FlutterSharedPreferences.xml`
- **Key Prefix**: All keys automatically prefixed with `"flutter."`
- **Access**: Direct access from both app and widget code

**iOS Implementation:**
- **Storage**: UserDefaults with App Group suite name
- **App Groups Required**: Mandatory for sharing data between main app and widget extension
- **Suite Name**: Must match App Group ID (e.g., `"group.com.family.financetracker"`)

### iOS App Groups Setup

**1. Configure in Xcode:**
- Navigate to Signing & Capabilities for both Runner and Widget Extension targets
- Add App Groups capability
- Create App Group (e.g., `group.com.family.financetracker`)
- Ensure both targets use the same App Group ID

**2. Flutter Implementation (via MethodChannel):**
```dart
static const platform = MethodChannel('widget_data');

Future<void> saveWidgetData(Map<String, dynamic> data) async {
  await platform.invokeMethod('saveWidgetData', {
    'data': jsonEncode(data),
  });
}
```

**3. Native iOS Implementation:**
```swift
let sharedDefaults = UserDefaults(suiteName: "group.com.family.financetracker")
sharedDefaults?.set(jsonString, forKey: "widget_data")
```

### Data Serialization Format

**Recommendation: JSON**
- **Portability**: Works across Dart and native code
- **Human-Readable**: Easier debugging
- **Built-in Support**: Both platforms have robust JSON parsing

**Example:**
```dart
class WidgetData {
  final double spent;
  final double limit;
  final String month;
  final bool isDarkMode;
  final DateTime lastUpdated;

  Map<String, dynamic> toJson() => {
    'spent': spent,
    'limit': limit,
    'month': month,
    'isDarkMode': isDarkMode,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory WidgetData.fromJson(Map<String, dynamic> json) => WidgetData(
    spent: json['spent'],
    limit: json['limit'],
    month: json['month'],
    isDarkMode: json['isDarkMode'],
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}
```

### Alternatives Considered
- **Hive/ObjectBox**: Overkill for simple key-value storage. Rejected for complexity.
- **SQLite**: Too heavy for widget state. Rejected due to overhead.
- **File-based Storage**: Less reliable than UserDefaults/SharedPreferences. Rejected.

---

## 5. Theme Detection and Adaptation

### Decision
Use Flutter's built-in **PlatformDispatcher.platformBrightness** for system theme detection in the Flutter app, and native platform APIs in widget code for real-time theme adaptation.

### Rationale
Flutter's framework provides native system theme detection without dependencies. For widgets, platform-native code can directly access system theme state.

### Flutter App Theme Implementation

```dart
import 'dart:ui' show PlatformDispatcher;

final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
final isDarkMode = brightness == Brightness.dark;

MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system, // Automatically switches
);
```

### Native Widget Theme Detection

**Android Widget (Kotlin):**
```kotlin
val nightModeFlags = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
val isDarkMode = nightModeFlags == Configuration.UI_MODE_NIGHT_YES

val backgroundColor = if (isDarkMode) {
    context.getColor(R.color.widget_bg_dark)
} else {
    context.getColor(R.color.widget_bg_light)
}
```

**iOS Widget (Swift):**
```swift
@Environment(\.colorScheme) var colorScheme

var body: some View {
    ZStack {
        Color(colorScheme == .dark ? .black : .white)
        Text("Widget Content")
            .foregroundColor(colorScheme == .dark ? .white : .black)
    }
}
```

### Dynamic Color Adaptation Strategy

**Recommended: Semantic Colors**
- Define semantic color names (e.g., `widgetBackground`, `widgetText`)
- Use asset catalogs (iOS) and resource qualifiers (Android) for automatic adaptation
- No code changes needed when theme changes

**iOS Asset Catalog:**
```
Assets.xcassets/
  WidgetBackground.colorset/
    Contents.json (defines light and dark variants)
```

**Android Resource Qualifiers:**
```
res/
  values/colors.xml (light theme colors)
  values-night/colors.xml (dark theme colors)
```

### Testing Considerations
- Test on multiple devices with different OS versions
- Verify widget appearance in both light and dark modes
- Test theme switching while widget is visible
- Validate color contrast ratios for accessibility (WCAG AA: 4.5:1)

### Alternatives Considered
- **adaptive_theme package**: Nice-to-have but not essential, existing ThemeMode.system sufficient. Deferred.
- **Manual Theme Management**: Unnecessary complexity. Rejected.
- **Hard-coded Colors**: No theme adaptation. Rejected for poor UX.

---

## Summary of Key Decisions

| Aspect | Technology/Approach | Primary Reason |
|--------|-------------------|----------------|
| **Widget Package** | home_widget ^0.6.0 | Cross-platform API, official recommendation |
| **Deep Linking** | go_router + HTTPS links | Existing dependency, secure, professional |
| **Android Updates** | WorkManager | Reliable, 15-min minimum, exponential backoff |
| **iOS Updates** | WidgetKit Timeline | Official Apple framework, system-optimized |
| **Data Persistence** | shared_preferences + App Groups | Existing dependency, platform-native storage |
| **Theme Detection** | PlatformDispatcher + native APIs | Built-in support, real-time adaptation |

---

**Research Completed**: 2025-12-31
**Next Phase**: Phase 1 - Design & Contracts (data-model.md, contracts/, quickstart.md)
