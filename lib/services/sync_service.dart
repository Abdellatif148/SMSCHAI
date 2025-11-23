import 'package:supabase_flutter/supabase_flutter.dart';

import 'encryption_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();

  // Initialize Sync Service
  Future<void> init() async {
    await _encryptionService.init();
    await _registerDevice();
  }

  // Register Device
  Future<void> _registerDevice() async {
    if (_client.auth.currentUser == null) return;

    try {
      // Device registration logic commented out - can be enabled when devices table is created
      /*
      String deviceName = 'Unknown Device';
      String deviceId = 'unknown';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      }

      await _client.from('devices').upsert({
        'user_id': _client.auth.currentUser!.id,
        'device_id': deviceId,
        'device_name': deviceName,
        'last_sync': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');
      */
    } catch (e) {
      // Silently fail device registration
    }
  }

  // Upload Message (Encrypted)
  Future<void> uploadMessage(
    Map<String, dynamic> message, {
    bool encryptBody = true,
  }) async {
    if (_client.auth.currentUser == null) return;

    try {
      // Ensure encryption service is initialized
      if (!_encryptionService.isInitialized) {
        await _encryptionService.init();
      }

      final bodyToUpload = encryptBody
          ? _encryptionService.encryptMessage(message['body'])
          : message['body'];

      await _client.from('messages_backup').insert({
        'user_id': _client.auth.currentUser!.id,
        'sms_id':
            message['id']?.toString() ??
            '${message['date']}_${message['address']}',
        'sender': message['type'] == 2 ? 'me' : (message['address'] ?? ''),
        'receiver': message['type'] == 2 ? (message['address'] ?? '') : 'me',
        'body': bodyToUpload,
        'timestamp': message['date'] ?? DateTime.now().millisecondsSinceEpoch,
        'read': message['read'] == 1,
        'type': message['type'] ?? 1,
        'is_encrypted': encryptBody,
      });
    } catch (e) {
      // Silently fail upload - will be handled by retry queue
    }
  }

  // Download Messages (Decrypt)
  Future<List<Map<String, dynamic>>> fetchAndDecryptMessages({
    int? since,
  }) async {
    if (_client.auth.currentUser == null) return [];

    try {
      // Ensure encryption service is initialized
      if (!_encryptionService.isInitialized) {
        await _encryptionService.init();
      }

      var query = _client
          .from('messages_backup')
          .select()
          .eq('user_id', _client.auth.currentUser!.id);

      // Incremental sync: only fetch messages after timestamp
      if (since != null) {
        query = query.gt('timestamp', since);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(100);

      final List<Map<String, dynamic>> decryptedMessages = [];

      for (var msg in response) {
        String body = msg['body'];
        if (msg['is_encrypted'] == true) {
          body = _encryptionService.decryptMessage(body);
        }

        decryptedMessages.add({
          'address': msg['sender'] == 'me' ? msg['receiver'] : msg['sender'],
          'body': body,
          'date': msg['timestamp'],
          'type': msg['type'],
          'read': msg['read'] == true ? 1 : 0,
          'is_synced': 1,
        });
      }
      return decryptedMessages;
    } catch (e) {
      return [];
    }
  }
}
