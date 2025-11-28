class AppConstants {
  static const String appName = 'SMSChat';

  // Load from --dart-define at compile time
  // These values are safe to be public (protected by Row Level Security)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oizpvbhqevegxjqimpne.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9penB2YmhxZXZlZ3hqcWltcG5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAwNDQxNTEsImV4cCI6MjA0NTYyMDE1MX0.wVu-vyC2NKBaJ0Ujv3xeDw_eSmLfezR52Cz_jYJ3H8I',
  );

  // Sentry configuration
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://9612a5eeb16eb5382335ab884bae2eb9@o4510427909128192.ingest.de.sentry.io/4510427913453648',
  );

  static const String fontName = 'Inter'; // Using Inter as a modern, clean font

  // Performance Monitoring Configuration
  static const bool enablePerformanceTracking = true;
  // Set to 1.0 in development to capture all traces, lower in production (e.g., 0.2)
  static const double tracesSampleRate = 1.0;

  // Performance operation names for consistency
  static const String perfSmsSync = 'sms.sync';
  static const String perfSmsSend = 'sms.send';
  static const String perfSmsMms = 'sms.mms';
  static const String perfDbQuery = 'db.query';
  static const String perfDbInsert = 'db.insert';
  static const String perfNetworkUpload = 'network.upload';
}
