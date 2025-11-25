class AppConstants {
  static const String appName = 'SMSChat';
  static const String supabaseUrl = 'https://oizpvbhqevegxjqimpne.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_wVu-vyC2NKBaJ0Ujv3xeDw_eSmLfezR';

  // Sentry DSN - configured for performance tracking
  static const String sentryDsn =
      'https://9612a5eeb16eb5382335ab884bae2eb9@o4510427909128192.ingest.de.sentry.io/4510427913453648';

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
