import 'package:telephony/telephony.dart';
import 'database_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony _telephony = Telephony.instance;
  final DatabaseService _dbService = DatabaseService();
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();

  // Initialize and request permissions
  Future<bool> requestPermissions() async {
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    return permissionsGranted ?? false;
  }

  // Read all SMS from device and sync to local DB
  Future<void> syncSmsToLocalDb() async {
    List<SmsMessage> messages = await _telephony.getInboxSms(
      columns: [
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
        SmsColumn.DATE_SENT,
        SmsColumn.READ,
        SmsColumn.TYPE,
        SmsColumn.THREAD_ID,
      ],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    // Use batch insert for better performance
    List<Map<String, dynamic>> messagesToInsert = [];

    for (var msg in messages) {
      final messageMap = {
        'address': msg.address,
        'body': msg.body,
        'date': msg.date,
        'date_sent': msg.dateSent,
        'read': msg.read == true ? 1 : 0,
        'type': msg.type?.index ?? 1, // 1 = Received
        'thread_id': msg.threadId,
        'is_synced': 0,
      };

      messagesToInsert.add(messageMap);

      // Update conversation snippet
      await _dbService.updateConversation({
        'thread_id': msg.threadId,
        'address': msg.address,
        'snippet': msg.body,
        'date': msg.date,
        'unread_count': 0,
      });
    }

    // Batch insert all messages at once
    if (messagesToInsert.isNotEmpty) {
      await _dbService.batchInsertMessages(messagesToInsert);
    }

    // Upload to cloud sync if logged in
    if (_supabaseService.currentUser != null) {
      // Upload unsynced messages in the background
      final unsyncedMessages = await _dbService.getUnsyncedMessages();
      for (var msg in unsyncedMessages.take(50)) {
        // Limit to 50 per batch
        await _supabaseService.uploadMessage(msg, encrypt: true);
      }
    }
  }

  // Send SMS
  Future<void> sendSms(String address, String body) async {
    await _telephony.sendSms(
      to: address,
      message: body,
      statusListener: (SendStatus status) {
        if (status == SendStatus.SENT) {
          final messageMap = {
            'address': address,
            'body': body,
            'date': DateTime.now().millisecondsSinceEpoch,
            'date_sent': DateTime.now().millisecondsSinceEpoch,
            'read': 1,
            'type': 2, // 2 = Sent
            'thread_id': null,
            'is_synced': 0,
          };

          // Save to local DB
          _dbService.insertMessage(messageMap);

          // Sync to Cloud
          if (_supabaseService.currentUser != null) {
            _supabaseService.uploadMessage(messageMap);
          }
        }
      },
    );
  }

  // Listen for incoming SMS
  void listenToIncomingSms() {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final messageMap = {
          'address': message.address,
          'body': message.body,
          'date': message.date,
          'date_sent': message.dateSent,
          'read': 0,
          'type': 1, // Received
          'thread_id': message.threadId,
          'is_synced': 0,
        };

        // Check for duplicates before inserting
        if (await _dbService.messageExists(messageMap)) {
          return; // Skip duplicate message
        }

        // Handle foreground message
        await _dbService.insertMessage(messageMap);

        // Update conversation
        await _dbService.updateConversation({
          'thread_id': message.threadId,
          'address': message.address,
          'snippet': message.body,
          'date': message.date,
          'unread_count': 1,
        });

        // Show Notification
        _notificationService.showNotification(
          (message.date ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000,
          message.address ?? 'New Message',
          message.body ?? '',
        );

        // Sync to Cloud
        if (_supabaseService.currentUser != null) {
          _supabaseService.uploadMessage(messageMap);
        }
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  // Sync Engine: Start
  Future<void> startSync() async {
    if (_supabaseService.currentUser == null) return;

    // 1. Upload pending messages (Placeholder)
    // await _uploadPendingMessages();

    // 2. Start Realtime Listener
    _supabaseService.subscribeToNewMessages((payload) async {
      // Check if message exists locally to avoid duplicates
      // For now, just insert as received/restored
      await _dbService.insertMessage({
        'address': payload['address'],
        'body': payload['body'],
        'date': payload['date'],
        'date_sent': payload['date'],
        'read': 1,
        'type': payload['type'],
        'thread_id': null,
        'is_synced': 1,
      });

      // Show notification if it's a new received message from another device
      if (payload['type'] == 1) {
        // Assuming 1 is received
        _notificationService.showNotification(
          (payload['date'] ?? DateTime.now().millisecondsSinceEpoch) ~/ 1000,
          payload['address'] ?? 'Synced Message',
          payload['body'] ?? '',
        );
      }
    });
  }

  // Sync Engine: Stop
  Future<void> stopSync() async {
    _supabaseService.unsubscribeFromMessages();
  }

  // Restore from Cloud
  Future<void> restoreFromCloud() async {
    final cloudMessages = await _supabaseService.fetchMessages();

    for (var msg in cloudMessages) {
      await _dbService.insertMessage({
        'address': msg['address'],
        'body': msg['body'],
        'date': msg['date'],
        'date_sent': msg['date'],
        'read': 1,
        'type': msg['type'],
        'thread_id': null,
        'is_synced': 1,
      });
    }
  }
}

// Top-level function for background handling
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  // Initialize DB service in background isolate if needed
  final dbService = DatabaseService();
  final messageMap = {
    'address': message.address,
    'body': message.body,
    'date': message.date,
    'date_sent': message.dateSent,
    'read': 0,
    'type': 1,
    'thread_id': message.threadId,
    'is_synced': 0,
  };

  // Check for duplicates before inserting
  if (!(await dbService.messageExists(messageMap))) {
    await dbService.insertMessage(messageMap);
  }
}
