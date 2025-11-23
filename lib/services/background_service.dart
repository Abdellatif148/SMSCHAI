import 'package:workmanager/workmanager.dart';
import 'sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

const String syncTask = "syncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case syncTask:
        // Background sync task

        // Initialize Supabase (Required in background isolate)
        try {
          await Supabase.initialize(
            url: AppConstants.supabaseUrl,
            anonKey: AppConstants.supabaseAnonKey,
          );

          await SyncService().init();

          // Perform Sync
          // 1. Upload pending (requires DB access, might need to init DB service too)
          // 2. Download new messages
          // For now, we'll just fetch and decrypt as a proof of concept
          await SyncService().fetchAndDecryptMessages();
        } catch (e) {
          return Future.value(false);
        }
        break;
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      syncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
