import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'encryption_service.dart';
import 'database_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();
  final DatabaseService _databaseService = DatabaseService();

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

      // Mark message as synced in local database
      if (message['id'] != null && message['id'] is int) {
        await _databaseService.markAsSynced([message['id'] as int]);
      }
    } catch (e) {
      // Silently fail or add to retry queue
      // Will be handled by sync queue service
    }
  }

  // Realtime Subscription
  RealtimeChannel? _messageChannel;

  void subscribeToNewMessages(void Function(Map<String, dynamic>) onMessage) {
    _messageChannel = _client.channel('public:messages_backup');
    _messageChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages_backup',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser?.id ?? '',
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
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

  // Upload file to Supabase Storage with progress tracking
  Future<Map<String, dynamic>> uploadFile(
    String filePath, {
    void Function(double progress)? onProgress,
  }) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to upload files');
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Get file info
      final fileSize = await file.length();
      final fileName = filePath.split('/').last;
      final extension = fileName.split('.').last;

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${currentUser!.id}_$timestamp.$extension';

      // Upload to Supabase Storage
      await _client.storage
          .from('attachments')
          .upload(
            uniqueFileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _getContentType(extension),
            ),
          );

      // Simulate progress (Supabase doesn't provide real-time progress)
      if (onProgress != null) {
        onProgress(1.0);
      }

      // Get public URL
      final url = _client.storage
          .from('attachments')
          .getPublicUrl(uniqueFileName);

      return {
        'url': url,
        'fileName': uniqueFileName,
        'originalName': fileName,
        'size': fileSize,
        'contentType': _getContentType(extension),
      };
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Download file from Supabase Storage
  Future<File> downloadFile(String url, String localPath) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;

      // Download file
      final bytes = await _client.storage
          .from('attachments')
          .download(fileName);

      // Save to local path
      final file = File(localPath);
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Delete file from Supabase Storage
  Future<void> deleteFile(String fileName) async {
    try {
      await _client.storage.from('attachments').remove([fileName]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Helper: Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }

  // Call Edge Function
  Future<dynamic> callFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.functions.invoke(functionName, body: body);

      if (response.status != 200) {
        throw Exception('Function call failed with status: ${response.status}');
      }

      return response.data;
    } catch (e) {
      throw Exception('Failed to call function $functionName: $e');
    }
  }

  // ===== Group Chat Methods =====

  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    String? iconUrl,
    String? description,
  }) async {
    if (currentUser == null) {
      throw Exception('User must be authenticated to create a group');
    }

    try {
      // Create group in Supabase
      final groupId =
          '${currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}';

      await _client.from('groups').insert({
        'id': groupId,
        'name': name,
        'icon_url': iconUrl,
        'owner_id': currentUser!.id,
        'created_at': DateTime.now().toIso8601String(),
        'description': description,
      });

      // Add members
      final members = memberIds
          .map(
            (userId) => {
              'group_id': groupId,
              'user_id': userId,
              'role': userId == currentUser!.id ? 'owner' : 'member',
              'joined_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      await _client.from('group_members').insert(members);

      // Create local group
      await _databaseService.createGroup(
        name: name,
        ownerId: currentUser!.id,
        iconUrl: iconUrl,
        description: description,
      );

      return groupId;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  Future<void> addGroupMember({
    required String groupId,
    required String userId,
    String role = 'member',
  }) async {
    if (currentUser == null) return;

    try {
      await _client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      });

      await _databaseService.addGroupMember(
        groupId: groupId,
        userId: userId,
        role: role,
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    if (currentUser == null) return;

    try {
      await _client.from('group_members').delete().match({
        'group_id': groupId,
        'user_id': userId,
      });

      await _databaseService.removeGroupMember(
        groupId: groupId,
        userId: userId,
      );
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? iconUrl,
    String? description,
  }) async {
    if (currentUser == null) return;

    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (iconUrl != null) updates['icon_url'] = iconUrl;
      if (description != null) updates['description'] = description;

      if (updates.isNotEmpty) {
        await _client.from('groups').update(updates).eq('id', groupId);

        await _databaseService.updateGroup(
          groupId: groupId,
          name: name,
          iconUrl: iconUrl,
          description: description,
        );
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteGroup(String groupId) async {
    if (currentUser == null) return;

    try {
      await _client.from('groups').delete().eq('id', groupId);
      await _databaseService.deleteGroup(groupId);
    } catch (e) {
      // Silently fail
    }
  }

  // ===== Reaction Methods =====

  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    if (currentUser == null) return;

    try {
      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': currentUser!.id,
        'emoji': emoji,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    if (currentUser == null) return;

    try {
      await _client.from('message_reactions').delete().match({
        'message_id': messageId,
        'user_id': currentUser!.id,
        'emoji': emoji,
      });
    } catch (e) {
      // Silently fail
    }
  }

  // ===== Message Edit/Delete Methods =====

  Future<void> editMessage({
    required String messageId,
    required String newBody,
  }) async {
    if (currentUser == null) return;

    try {
      await _client
          .from('messages_backup')
          .update({
            'body': newBody,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('sms_id', messageId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (currentUser == null) return;

    try {
      await _client
          .from('messages_backup')
          .update({'is_deleted': true})
          .eq('sms_id', messageId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> pinMessage(String messageId) async {
    if (currentUser == null) return;

    try {
      await _client
          .from('messages_backup')
          .update({'is_pinned': true})
          .eq('sms_id', messageId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> unpinMessage(String messageId) async {
    if (currentUser == null) return;

    try {
      await _client
          .from('messages_backup')
          .update({'is_pinned': false})
          .eq('sms_id', messageId);
    } catch (e) {
      // Silently fail
    }
  }

  // ===== Presence & Typing Indicators =====

  RealtimeChannel? _presenceChannel;

  void subscribeToPresence({
    required String conversationId,
    required Function(List<Map<String, dynamic>>) onPresenceChange,
  }) {
    _presenceChannel = _client.channel('presence:$conversationId');
    _presenceChannel!.onPresenceSync((payload) {
      final state = _presenceChannel!.presenceState();
      // state is List<SinglePresenceState>
      final users = <Map<String, dynamic>>[];
      for (var presenceState in state) {
        for (var presence in presenceState.presences) {
          users.add(presence.payload);
        }
      }
      onPresenceChange(users);
    }).subscribe();
  }

  void updatePresence({
    required String conversationId,
    required bool isTyping,
  }) {
    if (_presenceChannel == null || currentUser == null) return;

    _presenceChannel!.track({
      'user_id': currentUser!.id,
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void unsubscribeFromPresence() {
    if (_presenceChannel != null) {
      _client.removeChannel(_presenceChannel!);
      _presenceChannel = null;
    }
  }
}
