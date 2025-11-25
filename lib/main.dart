import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/onboarding/welcome_screen.dart';
import 'services/database_service.dart';
import 'services/sms_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'providers/message_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConstants.sentryDsn;

      // Performance Monitoring Configuration
      options.tracesSampleRate = AppConstants.tracesSampleRate;
      options.enableAutoPerformanceTracing =
          AppConstants.enablePerformanceTracking;

      // Enable breadcrumbs for better context
      options.enableUserInteractionBreadcrumbs = true;
      options.enableAppLifecycleBreadcrumbs = true;

      // Set environment
      options.environment = const bool.fromEnvironment('dart.vm.product')
          ? 'production'
          : 'development';

      // Add release version
      options.release = 'smschat@1.0.0+1';

      // Configure what to send
      options.sendDefaultPii = false; // Don't send personally identifiable info
      options.attachStacktrace = true;
    },
    appRunner: () async {
      // Initialize Supabase
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );

      // Initialize Database
      await DatabaseService().database;

      // Initialize Notifications
      await NotificationService().init();

      // Initialize Background Service
      await BackgroundService.init();
      await BackgroundService.registerPeriodicTask();

      // Start listening to SMS
      final smsService = SmsService();
      smsService.listenToIncomingSms();

      // Start Cloud Sync if logged in
      if (Supabase.instance.client.auth.currentUser != null) {
        smsService.startSync();
      }

      runApp(const MyApp());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: MaterialApp(
        title: 'SMSChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const WelcomeScreen(),
      ),
    );
  }
}
