# Performance Tracking - Quick Reference

## 🚀 Quick Start

1. **Get Sentry DSN**: Sign up at [sentry.io](https://sentry.io) and create a Flutter project
2. **Configure DSN**: Update `lib/core/constants.dart`:
   ```dart
   static const String sentryDsn = 'YOUR_DSN_HERE';
   ```
3. **Run app**: `flutter run` and use normally
4. **View dashboard**: Go to Sentry → Performance tab

## 📝 Usage Examples

See complete examples in [lib/examples/](file:///c:/Users/DELL/Desktop/smschat/smschat/lib/examples/):

### Database Operations
```dart
import 'package:smschat/utils/performance_tracker.dart';

Future<List<Map<String, dynamic>>> getMessages(String address) async {
  return PerformanceTracker.trackDatabaseOperation(
    'query',
    () async {
      final db = await database;
      return await db.query('messages', where: 'address = ?', whereArgs: [address]);
    },
    table: 'messages',
  );
}
```

### SMS Operations
```dart
Future<void> sendSms(String address, String body) async {
  return PerformanceTracker.trackSmsOperation(
    'send',
    () async {
      await _telephony.sendSms(to: address, message: body);
    },
    recipient: address,
  );
}
```

### Network Requests
```dart
Future<String> uploadFile(String filePath) async {
  final fileSize = await File(filePath).length();
  
  return PerformanceTracker.trackNetworkRequest(
    'storage.upload',
    () async {
      // Upload logic
      return publicUrl;
    },
    method: 'POST',
    fileSize: fileSize,
  );
}
```

## 📊 What You'll See in Sentry

- **Transaction names**: `sms.send`, `db.query`, `network.upload`
- **Duration metrics**: P50, P75, P95 percentiles
- **Metadata**: Record counts, file sizes, recipients
- **Error tracking**: Failed operations with stack traces
- **Trends**: Performance over time

## 🎯 Key Metrics to Watch

| Metric | Good | Warning | Action Needed |
|--------|------|---------|---------------|
| Database query | <50ms | 50-200ms | >200ms |
| SMS send | <500ms | 500ms-2s | >2s |
| File upload (1MB) | <2s | 2-5s | >5s |
| Message sync (100 msgs) | <3s | 3-10s | >10s |

## 🛠️ Configuration

In `lib/core/constants.dart`:

```dart
// Toggle tracking
static const bool enablePerformanceTracking = true;

// Sample rate (1.0 = 100%, 0.2 = 20%)
static const double tracesSampleRate = 1.0;  // Lower in production!
```

## 📚 Learn More

- Full guide: [walkthrough.md](file:///C:/Users/DELL/.gemini/antigravity/brain/c31440f8-407b-4e98-a7d3-b9729f2b5ca0/walkthrough.md)
- Utility class: [performance_tracker.dart](file:///c:/Users/DELL/Desktop/smschat/smschat/lib/utils/performance_tracker.dart)
- Sentry docs: https://docs.sentry.io/platforms/flutter/performance/
