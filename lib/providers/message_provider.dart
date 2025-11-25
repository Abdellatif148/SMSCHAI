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
  Future<void> sendMessage(
    String address,
    String body, {
    String? attachmentPath,
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
        if (attachmentPath != null) 'attachment_url': attachmentPath,
        if (attachmentPath != null)
          'attachment_type': 'image/jpeg', // Default to image for now
      };

      _messages.insert(0, tempMessage);
      notifyListeners();

      if (attachmentPath != null) {
        // Send MMS
        try {
          await _smsService.sendMms(address, attachmentPath, body);
        } catch (e) {
          // Fallback to cloud upload if MMS fails
          // For now, just throw error to trigger catch block or handle it
          throw Exception('Failed to send MMS: $e');
        }
      } else {
        // Send SMS
        await _smsService.sendSms(address, body);
      }

      // Reload to get the actual message from DB
      await Future.delayed(
        const Duration(milliseconds: 1000),
      ); // Increased delay for MMS
      await loadMessages(address);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send an attachment
  Future<void> sendAttachment(String address, String filePath) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Optimistic Update: Add message with local path
      final tempMessage = {
        'address': address,
        'body': 'Sent an attachment',
        'date': DateTime.now().millisecondsSinceEpoch,
        'type': 2, // Sent
        'read': 1,
        'sending': true,
        'attachment_url': filePath, // Local path initially
        'attachment_type': 'image', // Assume image for now
      };

      _messages.insert(0, tempMessage);
      notifyListeners();

      // 2. Try sending via MMS (Android Intent)
      try {
        await _smsService.sendMms(address, filePath, '');
        // Note: We can't easily know if MMS succeeded as it hands off to another app.
        // We assume success if no error was thrown during hand-off.

        // Update local DB to persist the message
        await _dbService.insertMessage({
          ...tempMessage,
          'sending': false, // Clear sending flag
          'is_synced': 0,
        });
      } catch (mmsError) {
        debugPrint(
          'MMS failed or not supported, falling back to cloud link: $mmsError',
        );

        // 3. Fallback: Upload to Supabase and send link
        final url = await SupabaseService().uploadFile(filePath);
        final body = 'Sent an attachment: $url';

        // Update the temp message in the list
        _messages[0]['body'] = body;
        _messages[0]['attachment_url'] = url; // Update to remote URL
        notifyListeners();

        // Send SMS with link
        await sendMessage(address, body);
      }
    } catch (e) {
      _error = 'Failed to send attachment: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
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
