import 'package:supabase_flutter/supabase_flutter.dart';
import 'encryption_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();

  SupabaseClient get client => _client;

  // Auth
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Sync Logic - Upload message with encryption
  Future<void> uploadMessage(
    Map<String, dynamic> message, {
    bool encrypt = true,
  }) async {
    if (currentUser == null) return;

    try {
      // Encrypt message body before upload
      final bodyToUpload = encrypt && message['body'] != null
          ? _encryptionService.encryptMessage(message['body'])
          : message['body'];

      await _client.from('messages_backup').insert({
        'user_id': currentUser!.id,
        'sms_id':
            message['id']?.toString() ??
            '${message['date']}_${message['address']}',
        'sender': message['type'] == 2 ? 'me' : (message['address'] ?? ''),
        'receiver': message['type'] == 2 ? (message['address'] ?? '') : 'me',
        'body': bodyToUpload,
        'timestamp': message['date'] ?? DateTime.now().millisecondsSinceEpoch,
        'read': message['read'] == 1,
        'type': message['type'] ?? 1,
      });
      // TODO: Update local DB to mark as synced
    } catch (e) {
      // Silently fail or add to retry queue
      // Will be handled by sync queue service
    }
  }

  // Realtime Subscription
  RealtimeChannel? _messageChannel;

  void subscribeToNewMessages(void Function(Map<String, dynamic>) onMessage) {
    _messageChannel = _client.channel('public:messages_backup');
    _messageChannel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'messages_backup',
        filter: 'user_id=eq.${currentUser?.id ?? ''}',
      ),
      (payload, [ref]) {
        onMessage(payload['new']);
      },
    ).subscribe();
  }

  void unsubscribeFromMessages() {
    if (_messageChannel != null) {
      _client.removeChannel(_messageChannel!);
      _messageChannel = null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages({int? since}) async {
    if (currentUser == null) return [];

    try {
      var query = _client
          .from('messages_backup')
          .select()
          .eq('user_id', currentUser!.id);

      // Incremental sync: only fetch messages after timestamp
      if (since != null) {
        query = query.gt('timestamp', since);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
}
