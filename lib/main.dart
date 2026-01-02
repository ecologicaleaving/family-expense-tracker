import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app/app.dart';
import 'core/config/env.dart';
import 'features/widget/presentation/providers/widget_provider.dart';
import 'shared/services/share_intent_service.dart';

/// Demo mode flag - set via --dart-define=DEMO_MODE=true
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize timezone database
  tz.initializeTimeZones();

  // Get device timezone and set as local
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String deviceTimezone = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(deviceTimezone));
  } catch (e) {
    // Fallback to UTC if device timezone cannot be determined
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  // Initialize Hive for local caching
  await Hive.initFlutter();
  await Hive.openBox<String>('dashboard_cache');

  // Initialize SharedPreferences for widget data persistence
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize share intent service for receiving images from other apps
  await ShareIntentService.initialize();

  if (!kDemoMode) {
    // Validate environment in development
    if (!Env.isDevelopment) {
      Env.validate();
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const FamilyExpenseTrackerApp(),
    ),
  );
}
