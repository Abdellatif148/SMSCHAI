// Example: Instrumented Supabase Service Methods
// This file shows how to add performance tracking to your network operations

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/performance_tracker.dart';

class InstrumentedSupabaseExamples {
  final SupabaseClient _client = Supabase.instance.client;

  /// Example 1: Track file upload with file size
  Future<String> uploadFileWithTracking(String filePath) async {
    final file = File(filePath);
    final fileSize = await file.length();

    return PerformanceTracker.trackNetworkRequest(
      'storage.upload',
      () async {
        // Actual upload logic
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';

        await _client.storage.from('chat_attachments').upload(fileName, file);

        final publicUrl = _client.storage
            .from('chat_attachments')
            .getPublicUrl(fileName);

        return publicUrl;
      },
      method: 'POST',
      fileSize:
          fileSize, // Metadata: track upload size for performance analysis
    );
  }

  /// Example 2: Track message upload (API call)
  Future<void> uploadMessageWithTracking(Map<String, dynamic> message) async {
    return PerformanceTracker.trackNetworkRequest(
      'messages.upload',
      () async {
        // Actual upload to Supabase
        await _client.from('messages_backup').insert(message);
      },
      method: 'POST',
      additionalMetadata: {
        'encrypted': message['body'] != null,
        'message_type': message['type'],
      },
    );
  }

  /// Example 3: Track message fetch (download)
  Future<List<Map<String, dynamic>>> fetchMessagesWithTracking({
    int? since,
  }) async {
    return PerformanceTracker.trackNetworkRequest(
      'messages.fetch',
      () async {
        var query = _client.from('messages_backup').select();

        if (since != null) {
          query = query.gt('timestamp', since);
        }

        final response = await query
            .order('timestamp', ascending: false)
            .limit(100);

        final messages = List<Map<String, dynamic>>.from(response);

        return messages;
      },
      method: 'GET',
      additionalMetadata: {'incremental': since != null, 'limit': 100},
    );
  }

  /// Example 4: Track authentication operation
  Future<void> signInWithTracking(String email, String password) async {
    return PerformanceTracker.trackNetworkRequest('auth.signin', () async {
      await _client.auth.signInWithPassword(email: email, password: password);
    }, method: 'POST');
  }
}
