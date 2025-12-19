# Quickstart Guide: Family Expense Tracker

**Date**: 2025-12-19
**Feature**: 001-family-expense-tracker

## Prerequisites

- Flutter SDK 3.x installed
- Android Studio with Android SDK (API 26+)
- Supabase account (free tier)
- Google Cloud account (for Vision API)

## Project Setup

### 1. Create Flutter Project

```bash
flutter create --org com.example family_expense_tracker
cd family_expense_tracker
```

### 2. Add Dependencies

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Backend
  supabase_flutter: ^2.0.0

  # Local Storage
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0

  # Camera & Images
  camera: ^0.10.5
  image_picker: ^1.0.0
  image_cropper: ^5.0.0

  # Charts
  fl_chart: ^0.65.0

  # UI Helpers
  intl: ^0.18.0
  go_router: ^12.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
  drift_dev: ^2.14.0
  mockito: ^5.4.0
  integration_test:
    sdk: flutter
```

### 3. Supabase Setup

1. Create new Supabase project at https://supabase.com
2. Run database migrations from `data-model.md`
3. Enable Row Level Security policies
4. Create Storage bucket `receipts` (public: false)
5. Note your project URL and anon key

### 4. Environment Configuration

Create `lib/core/config/env.dart`:

```dart
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
  static const gcpVisionApiKey = String.fromEnvironment(
    'GCP_VISION_KEY',
    defaultValue: '', // Should be in Edge Function
  );
}
```

### 5. Initialize Supabase

In `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const MyApp());
}
```

## Running the App

### Development

```bash
# Run on Android emulator
flutter run

# Run with environment variables
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=xxx
```

### Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

---

## Integration Test Scenarios

### User Story 1: Authentication

```dart
// test/integration/auth_test.dart
void main() {
  testWidgets('US1: User can register and login', (tester) async {
    // Given: App is launched
    await tester.pumpWidget(const MyApp());

    // When: User fills registration form
    await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password_field')), 'Password123!');
    await tester.enterText(find.byKey(Key('name_field')), 'Test User');
    await tester.tap(find.byKey(Key('register_button')));
    await tester.pumpAndSettle();

    // Then: User is logged in and sees home screen
    expect(find.text('Benvenuto, Test User'), findsOneWidget);
  });

  testWidgets('US1: User can logout', (tester) async {
    // Given: User is logged in
    // When: User taps logout
    // Then: User sees login screen
  });
}
```

### User Story 2: Group Management

```dart
// test/integration/groups_test.dart
void main() {
  testWidgets('US2: User can create family group', (tester) async {
    // Given: User is logged in without a group
    // When: User creates group "Famiglia Rossi"
    // Then: Group is created and user is admin
  });

  testWidgets('US2: User can join group with invite code', (tester) async {
    // Given: Valid invite code exists
    // When: User enters code
    // Then: User joins group and sees members
  });
}
```

### User Story 3: Receipt Scanning

```dart
// test/integration/scanner_test.dart
void main() {
  testWidgets('US3: Receipt data is extracted', (tester) async {
    // Given: User is in their group
    // When: User scans a receipt
    // Then: Amount, date, merchant are pre-filled
  });

  testWidgets('US3: User can edit extracted data', (tester) async {
    // Given: Receipt has been scanned
    // When: User edits the amount
    // Then: Expense is saved with edited amount
  });

  testWidgets('US3: Manual entry works', (tester) async {
    // Given: User taps manual entry
    // When: User fills expense form
    // Then: Expense is saved
  });
}
```

### User Story 4: Dashboard

```dart
// test/integration/dashboard_test.dart
void main() {
  testWidgets('US4: Personal expenses shown', (tester) async {
    // Given: User has recorded expenses
    // When: User views personal dashboard
    // Then: Only their expenses are totaled
  });

  testWidgets('US4: Group expenses with filter', (tester) async {
    // Given: Group has expenses from multiple members
    // When: User filters by week
    // Then: Only this week's expenses shown
  });

  testWidgets('US4: Category breakdown displayed', (tester) async {
    // Given: Expenses in multiple categories
    // When: Dashboard loads
    // Then: Pie chart shows category distribution
  });
}
```

---

## Supabase Edge Function: Receipt Scanner

Create `supabase/functions/scan-receipt/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const VISION_API_KEY = Deno.env.get("GCP_VISION_API_KEY");
const VISION_API_URL = "https://vision.googleapis.com/v1/images:annotate";

serve(async (req) => {
  try {
    const formData = await req.formData();
    const imageFile = formData.get("image") as File;

    if (!imageFile) {
      return new Response(
        JSON.stringify({ success: false, error: "No image provided" }),
        { status: 400 }
      );
    }

    // Convert to base64
    const buffer = await imageFile.arrayBuffer();
    const base64Image = btoa(String.fromCharCode(...new Uint8Array(buffer)));

    // Call Vision API
    const visionResponse = await fetch(`${VISION_API_URL}?key=${VISION_API_KEY}`, {
      method: "POST",
      body: JSON.stringify({
        requests: [{
          image: { content: base64Image },
          features: [{ type: "TEXT_DETECTION" }]
        }]
      })
    });

    const visionData = await visionResponse.json();
    const text = visionData.responses[0]?.fullTextAnnotation?.text || "";

    // Extract data from Italian receipts
    const extracted = extractReceiptData(text);

    // Upload image to storage
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const fileName = `${crypto.randomUUID()}.jpg`;
    await supabase.storage.from("receipts").upload(fileName, imageFile);
    const { data: { publicUrl } } = supabase.storage.from("receipts").getPublicUrl(fileName);

    return new Response(
      JSON.stringify({
        success: true,
        data: extracted,
        image_url: publicUrl,
        raw_text: text
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500 }
    );
  }
});

function extractReceiptData(text: string) {
  // Italian receipt patterns
  const amountPatterns = [
    /TOTALE\s*[€]?\s*(\d+[.,]\d{2})/i,
    /IMPORTO\s*[€]?\s*(\d+[.,]\d{2})/i,
    /TOTAL[E]?\s*[€]?\s*(\d+[.,]\d{2})/i,
    /€\s*(\d+[.,]\d{2})/
  ];

  const datePatterns = [
    /(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4})/,
    /(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{2})/
  ];

  let amount = null;
  let date = null;
  let merchant = null;
  let confidence = { amount: 0, date: 0, merchant: 0 };

  // Extract amount
  for (const pattern of amountPatterns) {
    const match = text.match(pattern);
    if (match) {
      amount = parseFloat(match[1].replace(",", "."));
      confidence.amount = 0.85;
      break;
    }
  }

  // Extract date
  for (const pattern of datePatterns) {
    const match = text.match(pattern);
    if (match) {
      date = normalizeDate(match[1]);
      confidence.date = 0.80;
      break;
    }
  }

  // Extract merchant (usually first line)
  const lines = text.split("\n").filter(l => l.trim().length > 2);
  if (lines.length > 0) {
    merchant = lines[0].trim().substring(0, 100);
    confidence.merchant = 0.70;
  }

  return { amount, date, merchant, confidence };
}

function normalizeDate(dateStr: string): string {
  // Convert DD/MM/YY or DD/MM/YYYY to YYYY-MM-DD
  const parts = dateStr.split(/[\/\-\.]/);
  if (parts.length === 3) {
    let year = parts[2];
    if (year.length === 2) {
      year = "20" + year;
    }
    return `${year}-${parts[1].padStart(2, "0")}-${parts[0].padStart(2, "0")}`;
  }
  return dateStr;
}
```

Deploy:
```bash
supabase functions deploy scan-receipt
supabase secrets set GCP_VISION_API_KEY=your_key
```

---

## Development Workflow

1. **Start with US1 (Auth)** - Get registration/login working
2. **Add US2 (Groups)** - Group creation and invites
3. **Implement US3 (Scanner)** - Camera + OCR integration
4. **Build US4 (Dashboard)** - Charts and filtering

Each user story can be developed and tested independently, enabling incremental delivery.
