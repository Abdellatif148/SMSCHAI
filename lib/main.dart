import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
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
