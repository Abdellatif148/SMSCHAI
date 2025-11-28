import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/sms_service.dart';
import '../services/supabase_service.dart';

class MessageProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SmsService _smsService = SmsService();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentAddress;
  bool _isGroup = false;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGroup => _isGroup;

  // Load messages for a specific address
  Future<void> loadMessages(String address) async {
    if (_currentAddress == address && !_isGroup && _messages.isNotEmpty) {
      return; // Already loaded
    }

    _currentAddress = address;
    _isGroup = false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _dbService.getMessages(address);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _messages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load messages for a group
  Future<void> loadGroupMessages(String groupId) async {
    if (_currentAddress == groupId && _isGroup && _messages.isNotEmpty) {
      return;
    }

    _currentAddress = groupId;
    _isGroup = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _dbService.getGroupMessages(groupId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _messages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more messages (pagination)
  Future<void> loadMoreMessages(String addressOrGroupId, int offset) async {
    try {
      final newMessages = await _dbService.getMessagesPaginated(
        addressOrGroupId,
        20, // Load 20 more
        offset,
        isGroup: _isGroup,
      );
      _messages.addAll(newMessages);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Send a new message
  Future<void> sendMessage(
    String address,
    String body, {
    String? attachmentPath,
    String? mediaType,
    int? replyToId,
    String? groupId,
  }) async {
    try {
      // Optimistic update - add message immediately
      final tempMessage = {
        'address': address,
        'body': body,
        'date': DateTime.now().millisecondsSinceEpoch,
        'type': 2, // Sent
        'read': 1,
        'sending': true, // Temp flag
        if (attachmentPath != null) 'media_url': attachmentPath,
        if (mediaType != null) 'media_type': mediaType,
        if (replyToId != null) 'reply_to_id': replyToId,
        if (groupId != null) 'group_id': groupId,
        'delivery_status': 'sent',
      };

      _messages.insert(0, tempMessage);
      notifyListeners();

      if (groupId != null) {
        // Handle Group Message
        if (attachmentPath != null) {
          final url = await SupabaseService().uploadFile(attachmentPath);
          tempMessage['media_url'] = url;
        }

        // Save to local DB
        await _dbService.insertMessage({
          ...tempMessage,
          'sending': false,
          'is_synced': 0,
        });

        // Sync to Supabase (via background service or direct call)
        // For now, we rely on the sync service which picks up unsynced messages
      } else {
        // Handle 1-on-1 Message (SMS/MMS)
        if (attachmentPath != null) {
          // Upload file first if it's not an MMS
          try {
            final url = await SupabaseService().uploadFile(attachmentPath);

            // Send as SMS with link
            final fullBody = body.isEmpty ? 'Sent a file: $url' : '$body\n$url';
            await _smsService.sendSms(address, fullBody);

            // Save to DB with cloud URL
            await _dbService.insertMessage({
              ...tempMessage,
              'media_url': url,
              'body': fullBody,
              'sending': false,
              'is_synced': 0,
            });
          } catch (e) {
            throw Exception('Failed to upload media: $e');
          }
        } else {
          // Send SMS
          await _smsService.sendSms(address, body);

          // Save to DB
          await _dbService.insertMessage({
            ...tempMessage,
            'sending': false,
            'is_synced': 0,
          });
        }
      }

      // Reload to get the actual message from DB
      await Future.delayed(const Duration(milliseconds: 500));
      if (groupId != null) {
        await loadGroupMessages(groupId);
      } else {
        await loadMessages(address);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add reaction
  Future<void> addReaction(int messageId, String emoji) async {
    try {
      // Optimistic update
      final index = _messages.indexWhere((m) => m['id'] == messageId);
      if (index != -1) {
        final message = Map<String, dynamic>.from(_messages[index]);
        final reactions = message['reactions'] != null
            ? Map<String, dynamic>.from(
                DatabaseService().parseJson(message['reactions']),
              )
            : <String, dynamic>{};

        if (!reactions.containsKey(emoji)) {
          reactions[emoji] = [];
        }
        (reactions[emoji] as List).add(
          'me',
        ); // 'me' as placeholder for current user

        message['reactions'] = DatabaseService().stringifyJson(reactions);
        _messages[index] = message;
        notifyListeners();
      }

      await _dbService.addReaction(
        messageId: messageId,
        userId: SupabaseService().currentUser?.id ?? 'me',
        emoji: emoji,
      );

      // Sync with Supabase
      if (SupabaseService().currentUser != null) {
        // We'd need the Supabase message ID here, which might be different
        // For now, we'll skip direct Supabase call and rely on sync service
      }
    } catch (e) {
      // Revert on error?
    }
  }

  // Remove reaction
  Future<void> removeReaction(int messageId, String emoji) async {
    try {
      // Optimistic update logic...
      await _dbService.removeReaction(
        messageId: messageId,
        userId: SupabaseService().currentUser?.id ?? 'me',
        emoji: emoji,
      );
    } catch (e) {
      // Handle error
    }
  }

  // Pin/Unpin message
  Future<void> togglePin(int messageId, bool isPinned) async {
    try {
      // Optimistic update
      final index = _messages.indexWhere((m) => m['id'] == messageId);
      if (index != -1) {
        final message = Map<String, dynamic>.from(_messages[index]);
        message['is_pinned'] = isPinned ? 1 : 0;
        _messages[index] = message;
        notifyListeners();
      }

      if (isPinned) {
        await _dbService.pinMessage(messageId);
      } else {
        await _dbService.unpinMessage(messageId);
      }
    } catch (e) {
      // Handle error
    }
  }

  // Edit message
  Future<void> editMessage(int messageId, String newBody) async {
    try {
      // Optimistic update
      final index = _messages.indexWhere((m) => m['id'] == messageId);
      if (index != -1) {
        final message = Map<String, dynamic>.from(_messages[index]);
        message['body'] = newBody;
        message['edited_at'] = DateTime.now().millisecondsSinceEpoch;
        _messages[index] = message;
        notifyListeners();
      }

      await _dbService.editMessage(messageId: messageId, newBody: newBody);
    } catch (e) {
      // Handle error
    }
  }

  // Delete message
  Future<void> deleteMessage(int messageId) async {
    try {
      // Optimistic update
      final index = _messages.indexWhere((m) => m['id'] == messageId);
      if (index != -1) {
        final message = Map<String, dynamic>.from(_messages[index]);
        message['is_deleted'] = 1;
        _messages[index] = message;
        notifyListeners();
      }

      await _dbService.deleteMessage(messageId);
    } catch (e) {
      // Handle error
    }
  }

  // Refresh messages
  Future<void> refresh(String address) async {
    await loadMessages(address);
  }

  // Clear current conversation
  void clear() {
    _messages = [];
    _currentAddress = null;
    _error = null;
    notifyListeners();
  }

  // Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    try {
      return await _dbService.searchMessages(query);
    } catch (e) {
      return [];
    }
  }
}
