import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Thin wrapper around the Supabase singleton. The anon key is public —
/// Row Level Security enforces authorization (see 03_Security_Access.md).
class SupabaseService {
  static final SupabaseService instance = SupabaseService._();

  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  Future<bool> isConnected() async {
    return true;
  }
}
