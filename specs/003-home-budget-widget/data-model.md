# Data Model: Home Screen Budget Widget

**Feature**: 003-home-budget-widget
**Date**: 2025-12-31
**Purpose**: Define data structures and state management for widget feature

---

## Overview

The widget feature introduces new data models for managing widget state, configuration, and synchronization between the Flutter app and native widget implementations. These models follow the existing clean architecture pattern with entities, models, and repositories.

---

## Core Entities

### 1. WidgetDataEntity

**Purpose**: Represents the current state of the widget displayed on the home screen

**Location**: `lib/features/widget/domain/entities/widget_data_entity.dart`

**Fields**:

| Field | Type | Description | Validation Rules |
|-------|------|-------------|------------------|
| `spent` | `double` | Total amount spent in current month | >= 0, required |
| `limit` | `double` | Monthly budget limit | > 0, required |
| `percentage` | `double` | Percentage of budget used (calculated) | 0-100+ (can exceed 100) |
| `month` | `String` | Current month name (e.g., "Dicembre 2025") | required, format: "MMMM yyyy" |
| `currency` | `String` | Currency symbol (e.g., "€") | required, default: "€" |
| `isDarkMode` | `bool` | Current theme mode | required |
| `lastUpdated` | `DateTime` | Timestamp of last data update | required |
| `groupId` | `String` | ID of the family group | required, UUID format |
| `groupName` | `String` | Name of the family group | optional |

**Relationships**:
- Belongs to one `UserGroup` (via `groupId`)
- Derived from multiple `ExpenseEntity` records (aggregated)

**State Transitions**:
1. **Initial**: First widget installation, no data → shows "Budget non configurato"
2. **Normal**: Budget < 80% → green progress bar
3. **Warning**: Budget 80-99% → orange progress bar
4. **Critical**: Budget >= 100% → red progress bar
5. **Stale**: `lastUpdated` > 5 minutes ago → shows "Dati non aggiornati" indicator
6. **Offline**: No connection → shows last cached data with offline indicator

**Calculated Fields**:
```dart
double get percentage => (spent / limit) * 100;
String get formattedSpent => '€${spent.toStringAsFixed(2)}';
String get formattedLimit => '€${limit.toStringAsFixed(2)}';
String get displayText => '$formattedSpent / $formattedLimit (${percentage.toStringAsFixed(0)}%)';
bool get isWarning => percentage >= 80 && percentage < 100;
bool get isCritical => percentage >= 100;
bool get isStale => DateTime.now().difference(lastUpdated).inMinutes > 5;
```

---

### 2. WidgetConfigEntity

**Purpose**: Stores user preferences for widget behavior and appearance

**Location**: `lib/features/widget/domain/entities/widget_config_entity.dart`

**Fields**:

| Field | Type | Description | Validation Rules |
|-------|------|-------------|------------------|
| `size` | `WidgetSize` | Selected widget size | required, enum |
| `refreshInterval` | `Duration` | Update frequency | 15-60 minutes, default: 30 min |
| `showAmounts` | `bool` | Show actual amounts vs only percentage | required, default: true |
| `enableBackgroundRefresh` | `bool` | Allow background updates | required, default: true |

**Enum: WidgetSize**:
```dart
enum WidgetSize {
  small,  // 2x2 cells Android, compact iOS
  medium, // 4x2 cells Android, medium iOS
  large,  // 4x4 cells Android, large iOS
}
```

**Validation Rules**:
- `refreshInterval` must be >= 15 minutes (Android WorkManager minimum)
- `refreshInterval` must be <= 60 minutes (to balance battery vs freshness)
- All fields have sensible defaults to ensure widget works out-of-box

---

## Data Models (Data Layer)

### 1. WidgetDataModel

**Purpose**: Serializable version of WidgetDataEntity for persistence and API communication

**Location**: `lib/features/widget/data/models/widget_data_model.dart`

**JSON Schema**:
```json
{
  "spent": 450.50,
  "limit": 800.00,
  "month": "Dicembre 2025",
  "currency": "€",
  "isDarkMode": false,
  "lastUpdated": "2025-12-31T14:30:00.000Z",
  "groupId": "123e4567-e89b-12d3-a456-426614174000",
  "groupName": "Famiglia Rossi"
}
```

**Serialization**:
```dart
class WidgetDataModel extends WidgetDataEntity {
  const WidgetDataModel({
    required double spent,
    required double limit,
    required String month,
    required String currency,
    required bool isDarkMode,
    required DateTime lastUpdated,
    required String groupId,
    String? groupName,
  }) : super(
    spent: spent,
    limit: limit,
    month: month,
    currency: currency,
    isDarkMode: isDarkMode,
    lastUpdated: lastUpdated,
    groupId: groupId,
    groupName: groupName,
  );

  factory WidgetDataModel.fromJson(Map<String, dynamic> json) {
    return WidgetDataModel(
      spent: (json['spent'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
      month: json['month'] as String,
      currency: json['currency'] as String? ?? '€',
      isDarkMode: json['isDarkMode'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spent': spent,
      'limit': limit,
      'month': month,
      'currency': currency,
      'isDarkMode': isDarkMode,
      'lastUpdated': lastUpdated.toIso8601String(),
      'groupId': groupId,
      'groupName': groupName,
    };
  }

  factory WidgetDataModel.fromEntity(WidgetDataEntity entity) {
    return WidgetDataModel(
      spent: entity.spent,
      limit: entity.limit,
      month: entity.month,
      currency: entity.currency,
      isDarkMode: entity.isDarkMode,
      lastUpdated: entity.lastUpdated,
      groupId: entity.groupId,
      groupName: entity.groupName,
    );
  }
}
```

---

### 2. WidgetConfigModel

**Purpose**: Serializable version of WidgetConfigEntity

**Location**: `lib/features/widget/data/models/widget_config_model.dart`

**JSON Schema**:
```json
{
  "size": "medium",
  "refreshInterval": 1800000,
  "showAmounts": true,
  "enableBackgroundRefresh": true
}
```

**Note**: `refreshInterval` stored as milliseconds for consistency with platform APIs

---

## Repository Interfaces

### 1. WidgetRepository

**Purpose**: Abstract interface for widget data operations

**Location**: `lib/features/widget/domain/repositories/widget_repository.dart`

**Methods**:

```dart
abstract class WidgetRepository {
  /// Fetch current budget data and prepare widget update
  Future<Either<Failure, WidgetDataEntity>> getWidgetData();

  /// Save widget data to local storage for native widget access
  Future<Either<Failure, void>> saveWidgetData(WidgetDataEntity data);

  /// Trigger native widget refresh
  Future<Either<Failure, void>> updateWidget();

  /// Get widget configuration
  Future<Either<Failure, WidgetConfigEntity>> getWidgetConfig();

  /// Save widget configuration
  Future<Either<Failure, void>> saveWidgetConfig(WidgetConfigEntity config);

  /// Register background refresh job (Android WorkManager / iOS Timeline)
  Future<Either<Failure, void>> registerBackgroundRefresh();

  /// Cancel background refresh job
  Future<Either<Failure, void>> cancelBackgroundRefresh();
}
```

**Error Handling**:
- Returns `Either<Failure, T>` using dartz package (existing pattern)
- Failure types: `NetworkFailure`, `CacheFailure`, `ServerFailure`, `WidgetNotInstalledFailure`

---

### 2. WidgetRepositoryImpl

**Purpose**: Concrete implementation of WidgetRepository

**Location**: `lib/features/widget/data/repositories/widget_repository_impl.dart`

**Dependencies**:
- `WidgetLocalDataSource` - local storage operations
- `DashboardRepository` - fetch budget stats
- `AuthRepository` - get current user/group
- `HomeWidgetPlugin` - native widget bridge

**Implementation Strategy**:
```dart
@override
Future<Either<Failure, WidgetDataEntity>> getWidgetData() async {
  try {
    // 1. Get current user and active group
    final user = await authRepository.getCurrentUser();
    final groupId = user.activeGroupId;

    // 2. Fetch dashboard stats for current month
    final stats = await dashboardRepository.getStatsForMonth(
      DateTime.now(),
      groupId,
    );

    // 3. Get current theme
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    // 4. Build widget data entity
    final widgetData = WidgetDataEntity(
      spent: stats.totalSpent,
      limit: stats.monthlyBudget,
      month: DateFormat('MMMM yyyy', 'it').format(DateTime.now()),
      currency: '€',
      isDarkMode: isDarkMode,
      lastUpdated: DateTime.now(),
      groupId: groupId,
      groupName: stats.groupName,
    );

    return Right(widgetData);
  } on ServerException {
    return Left(ServerFailure());
  } on NetworkException {
    return Left(NetworkFailure());
  } catch (e) {
    return Left(UnknownFailure());
  }
}
```

---

## Data Sources

### 1. WidgetLocalDataSource

**Purpose**: Handle local storage operations for widget data

**Location**: `lib/features/widget/data/datasources/widget_local_datasource.dart`

**Methods**:

```dart
abstract class WidgetLocalDataSource {
  /// Save widget data to SharedPreferences
  Future<void> saveWidgetData(WidgetDataModel data);

  /// Load cached widget data
  Future<WidgetDataModel?> getCachedWidgetData();

  /// Save widget configuration
  Future<void> saveWidgetConfig(WidgetConfigModel config);

  /// Load widget configuration
  Future<WidgetConfigModel?> getWidgetConfig();

  /// Update native widget via home_widget plugin
  Future<void> updateNativeWidget(WidgetDataModel data);
}
```

**Implementation**:
```dart
class WidgetLocalDataSourceImpl implements WidgetLocalDataSource {
  final SharedPreferences sharedPreferences;
  final MethodChannel? platformChannel; // For iOS App Group access

  static const String _widgetDataKey = 'widget_data';
  static const String _widgetConfigKey = 'widget_config';

  @override
  Future<void> saveWidgetData(WidgetDataModel data) async {
    final jsonString = jsonEncode(data.toJson());

    // Save to Flutter SharedPreferences
    await sharedPreferences.setString(_widgetDataKey, jsonString);

    // iOS: Also save to App Group UserDefaults via MethodChannel
    if (Platform.isIOS && platformChannel != null) {
      await platformChannel!.invokeMethod('saveWidgetData', {
        'data': jsonString,
      });
    }
  }

  @override
  Future<void> updateNativeWidget(WidgetDataModel data) async {
    // Save each field individually for native widget access
    await HomeWidget.saveWidgetData('spent', data.spent);
    await HomeWidget.saveWidgetData('limit', data.limit);
    await HomeWidget.saveWidgetData('month', data.month);
    await HomeWidget.saveWidgetData('percentage', data.percentage);
    await HomeWidget.saveWidgetData('isDarkMode', data.isDarkMode);
    await HomeWidget.saveWidgetData('lastUpdated', data.lastUpdated.millisecondsSinceEpoch);
    await HomeWidget.saveWidgetData('groupName', data.groupName ?? '');

    // Trigger widget update
    await HomeWidget.updateWidget(
      androidName: 'BudgetWidgetProvider',
      iOSName: 'BudgetWidget',
    );
  }
}
```

---

## Data Flow Diagram

```
[User adds expense in app]
         ↓
[ExpenseRepository saves to Supabase]
         ↓
[ExpenseProvider notifies listeners]
         ↓
[WidgetUpdateService triggered]
         ↓
[WidgetRepository.getWidgetData()]
         ↓
[Fetches stats from DashboardRepository]
         ↓
[Builds WidgetDataEntity]
         ↓
[WidgetRepository.saveWidgetData()]
         ↓
[WidgetLocalDataSource.saveWidgetData()]
         ├→ [Flutter SharedPreferences]
         └→ [iOS App Group UserDefaults (via MethodChannel)]
         ↓
[WidgetLocalDataSource.updateNativeWidget()]
         ├→ [Android: Broadcasts intent to BudgetWidgetProvider]
         └→ [iOS: Requests WidgetKit timeline reload]
         ↓
[Native widget renders updated data]
```

---

## Database Schema (No changes required)

The widget feature uses existing database tables via Supabase:
- `expenses` - for calculating total spent
- `family_groups` - for budget limits and group info
- `profiles` - for user authentication

**No new tables needed** - all data is aggregated from existing sources.

---

## Local Storage Keys

| Key | Type | Purpose | Platform |
|-----|------|---------|----------|
| `widget_data` | JSON string | Complete widget state | Both |
| `widget_config` | JSON string | User widget preferences | Both |
| `flutter.spent` | double | Current spent amount | Android (HomeWidget) |
| `flutter.limit` | double | Budget limit | Android (HomeWidget) |
| `flutter.month` | string | Month name | Android (HomeWidget) |
| `flutter.percentage` | double | Budget percentage | Android (HomeWidget) |
| `flutter.isDarkMode` | bool | Theme mode | Android (HomeWidget) |
| `flutter.lastUpdated` | int | Update timestamp (ms) | Android (HomeWidget) |
| `flutter.groupName` | string | Family group name | Android (HomeWidget) |

**iOS Note**: iOS widget reads from shared App Group container, not standard UserDefaults.

---

## Validation & Error Handling

### Data Validation Rules

**WidgetDataEntity**:
- `spent >= 0` - Cannot have negative spending
- `limit > 0` - Budget must be positive
- `month` matches format `"MMMM yyyy"` - Ensures consistent display
- `currency.length <= 3` - Standard currency symbols
- `groupId` is valid UUID - Prevents orphaned data

**WidgetConfigEntity**:
- `refreshInterval.inMinutes >= 15` - Android WorkManager minimum
- `refreshInterval.inMinutes <= 60` - Battery preservation

### Error States

| Error | Cause | UI Response |
|-------|-------|-------------|
| `WidgetNotInstalledFailure` | Widget not added to home screen | Log warning, skip update |
| `NetworkFailure` | No internet connection | Show cached data + "Dati non aggiornati" |
| `ServerFailure` | Supabase error | Show cached data + retry indicator |
| `CacheFailure` | SharedPreferences error | Show "Budget non configurato" prompt |
| `AuthFailure` | User logged out | Show "Accedi per visualizzare budget" |

---

## Performance Considerations

### Data Size
- **WidgetDataModel JSON**: ~200 bytes
- **WidgetConfigModel JSON**: ~100 bytes
- **Total storage**: <1 KB per user
- **Memory impact**: Negligible (<5MB RAM target easily met)

### Update Frequency
- **Triggered updates**: Immediate after expense add (<1 second)
- **Background updates**: Every 15-30 minutes
- **Daily updates**: 48-96 per day (well within iOS 40-70 limit)

### Caching Strategy
- **Cache duration**: Indefinite (until next update)
- **Staleness threshold**: 5 minutes
- **Offline behavior**: Always show last cached data with indicator

---

**Data Model Complete**: Ready for contract generation (Phase 1)
**Next Step**: Generate API contracts (deep link URLs, native platform interfaces)
