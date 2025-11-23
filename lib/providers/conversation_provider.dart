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
      _conversations[index]['unread_count'] = 0;
      notifyListeners();
    }
  }

  // Delete a conversation
  Future<void> deleteConversation(int threadId) async {
    _conversations.removeWhere((c) => c['thread_id'] == threadId);
    notifyListeners();
    // TODO: Delete from database
  }
}
