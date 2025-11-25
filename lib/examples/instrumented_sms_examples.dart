// Example: Instrumented SMS Service Methods
// This file shows how to add performance tracking to your SMS operations

import 'package:another_telephony/telephony.dart';
import '../utils/performance_tracker.dart';

class InstrumentedSmsExamples {
  final Telephony _telephony = Telephony.instance;

  /// Example 1: Track SMS sending
  Future<void> sendSmsWithTracking(String address, String body) async {
    return PerformanceTracker.trackSmsOperation(
      'send',
      () async {
        // Actual SMS sending logic
        await _telephony.sendSms(to: address, message: body);
      },
      recipient:
          address, // Metadata: who we're sending to (anonymized in Sentry)
    );
  }

  /// Example 2: Track MMS sending with attachment info
  Future<void> sendMmsWithTracking(
    String address,
    String attachmentPath,
    String body,
  ) async {
    return PerformanceTracker.trackSmsOperation(
      'mms',
      () async {
        // Your MMS sending logic here
        // await platform.invokeMethod('sendMms', {...});
      },
      recipient: address,
      hasAttachment: true, // Metadata: indicates this is a media message
    );
  }

  /// Example 3: Track message sync operation
  Future<void> syncMessagesWithTracking(
    List<Map<String, dynamic>> messages,
  ) async {
    return PerformanceTracker.trackSmsOperation(
      'sync',
      () async {
        // Your sync logic here
        // Process and insert messages...

        // Simulated sync process
        for (var _ in messages) {
          // Process message
          await Future.delayed(Duration(milliseconds: 10));
        }
      },
      messageCount: messages.length, // Metadata: how many messages synced
    );
  }

  /// Example 4: Track cloud restore with custom metadata
  Future<int> restoreFromCloudWithTracking() async {
    return PerformanceTracker.trackSmsOperation('restore', () async {
      // Fetch messages from cloud
      final cloudMessages = <Map<String, dynamic>>[]; // Your fetch logic

      // Insert locally
      for (var _ in cloudMessages) {
        // Insert message
      }

      return cloudMessages.length;
    }, additionalMetadata: {'source': 'cloud', 'incremental': false});
  }
}
