/// Environment configuration for Supabase and external services.
///
/// Values are loaded from compile-time environment variables:
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co
/// flutter run --dart-define=SUPABASE_ANON_KEY=xxx
/// ```
class Env {
  Env._();

  /// Supabase project URL
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  /// Supabase anonymous/public key
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  /// Google Cloud Vision API key (should be in Edge Function, not client)
  /// Only used for development/testing
  static const gcpVisionApiKey = String.fromEnvironment(
    'GCP_VISION_KEY',
    defaultValue: '',
  );

  /// Whether we're running in development mode
  static bool get isDevelopment =>
      supabaseUrl == 'YOUR_SUPABASE_URL' || supabaseUrl.contains('localhost');

  /// Validate that required environment variables are set
  static void validate() {
    if (supabaseUrl == 'YOUR_SUPABASE_URL') {
      throw Exception(
        'SUPABASE_URL not configured. '
        'Run with --dart-define=SUPABASE_URL=your_url',
      );
    }
    if (supabaseAnonKey == 'YOUR_SUPABASE_ANON_KEY') {
      throw Exception(
        'SUPABASE_ANON_KEY not configured. '
        'Run with --dart-define=SUPABASE_ANON_KEY=your_key',
      );
    }
  }
}
