import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/sms_service.dart';

class MessageProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SmsService _smsService = SmsService();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentAddress;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load messages for a specific address
  Future<void> loadMessages(String address) async {
    if (_currentAddress == address && _messages.isNotEmpty) {
      return; // Already loaded
    }

    _currentAddress = address;
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

  // Load more messages (pagination)
  Future<void> loadMoreMessages(String address, int offset) async {
    try {
      final newMessages = await _dbService.getMessagesPaginated(
        address,
        20, // Load 20 more
        offset,
      );
      _messages.addAll(newMessages);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Send a new message
  Future<void> sendMessage(String address, String body) async {
    try {
      // Optimistic update - add message immediately
      final tempMessage = {
        'address': address,
        'body': body,
        'date': DateTime.now().millisecondsSinceEpoch,
        'type': 2, // Sent
        'read': 1,
        'sending': true, // Temp flag
      };

      _messages.insert(0, tempMessage);
      notifyListeners();

      // Actually send SMS
      await _smsService.sendSms(address, body);

      // Reload to get the actual message from DB
      await Future.delayed(const Duration(milliseconds: 500));
      await loadMessages(address);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
