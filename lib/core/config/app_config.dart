import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'MandiRoznamcha';
  static const String appUrduName = 'منڈی روزنامچہ';
  static const String appTagline = 'منڈی کا ڈیجیٹل کھاتہ و بکری نظام';
  static const String appEnglishTagline = 'Pakistan\'s Digital Mandi & Wholesale OS';

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://placeholder.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key';

  static String get environment =>
      const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static const double creditAlertThreshold = 50000;
}
