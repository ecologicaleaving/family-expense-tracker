import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to apply the reimbursement tracking migration
/// Run with: dart run scripts/apply_migration.dart
Future<void> main() async {
  print('🚀 Applying reimbursement tracking migration...\n');

  // Read environment variables or use default for local dev
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
      'https://bkcpjplhikgxuonwwgxm.supabase.co';
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrY3BqcGxoaWtneHVvbnd3Z3htIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU1Njc1NTAsImV4cCI6MjA1MTE0MzU1MH0.K5C9BxT2qpP9mNvXqzz2xNf5hRQC4O_YnKqXqzJ5Zj4';

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    final supabase = Supabase.instance.client;
    print('✅ Connected to Supabase\n');

    // Read migration SQL
    final migrationSql = await File('supabase/migrations/20260116_add_reimbursement_tracking.sql').readAsString();

    print('📝 Executing migration SQL...\n');

    // Execute migration
    await supabase.rpc('exec_sql', params: {'sql': migrationSql});

    print('✅ Migration applied successfully!\n');
    print('📊 Changes made:');
    print('   - Added reimbursement_status column (TEXT)');
    print('   - Added reimbursed_at column (TIMESTAMPTZ)');
    print('   - Added check constraints');
    print('   - Added indexes for performance');
    print('   - Updated existing expenses with default values\n');

  } catch (e) {
    print('❌ Migration failed:');
    print('   Error: $e\n');
    print('💡 Alternative: Apply migration manually via Supabase Dashboard:');
    print('   1. Go to https://supabase.com/dashboard/project/_/sql');
    print('   2. Copy the SQL from: supabase/migrations/20260116_add_reimbursement_tracking.sql');
    print('   3. Paste and run in the SQL Editor\n');
    exit(1);
  }
}
