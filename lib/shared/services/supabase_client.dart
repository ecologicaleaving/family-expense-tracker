import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper for Supabase client access.
///
/// Provides convenient access to Supabase services throughout the app.
class SupabaseClientService {
  SupabaseClientService._();

  static final SupabaseClientService _instance = SupabaseClientService._();
  static SupabaseClientService get instance => _instance;

  /// Get the Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Get the auth client
  GoTrueClient get auth => client.auth;

  /// Get the current session
  Session? get currentSession => auth.currentSession;

  /// Get the current user
  User? get currentUser => auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get the current user's ID
  String? get currentUserId => currentUser?.id;

  /// Get the database client for a specific table
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Get the storage client for a specific bucket
  StorageFileApi storage(String bucket) => client.storage.from(bucket);

  /// Get the functions client
  FunctionsClient get functions => client.functions;

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;

  /// Sign out the current user
  Future<void> signOut() async {
    await auth.signOut();
  }
}

/// Convenience getter for the Supabase client service
SupabaseClientService get supabase => SupabaseClientService.instance;
