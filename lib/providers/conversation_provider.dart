import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/sms_service.dart';

class ConversationProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SmsService _smsService = SmsService();

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _dbService.getConversations();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _conversations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh conversations (pull-to-refresh)
  Future<void> refresh() async {
    await loadConversations();
  }

  // Sync SMS from device
  Future<void> syncFromDevice() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _smsService.syncSmsToLocalDb();
      await loadConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update unread count for a conversation
  void markAsRead(int threadId) {
    final index = _conversations.indexWhere((c) => c['thread_id'] == threadId);
    if (index != -1) {
      final conversation = _conversations[index];
      _conversations[index]['unread_count'] = 0;
      notifyListeners();

      // Persist to DB
      _dbService.updateConversation(
        threadId: threadId,
        address: conversation['address'],
        snippet: conversation['snippet'],
        date: conversation['date'],
        resetUnread: true,
      );
    }
  }

  /// Delete a conversation and optionally its messages
  /// [deleteMessages] - if true, also deletes all messages in the conversation
  Future<void> deleteConversation(
    int threadId, {
    bool deleteMessages = false,
  }) async {
    // Remove from local list first for immediate UI update
    _conversations.removeWhere((c) => c['thread_id'] == threadId);
    notifyListeners();

    // Delete from database
    try {
      await _dbService.deleteConversation(
        threadId,
        deleteMessages: deleteMessages,
      );
    } catch (e) {
      // If database deletion fails, reload to restore consistency
      _error = 'Failed to delete conversation: ${e.toString()}';
      await loadConversations();
    }
  }
}
