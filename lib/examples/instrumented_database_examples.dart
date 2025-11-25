// Example: Instrumented Database Service Methods
// This file shows how to add performance tracking to your database operations

import 'package:sqflite/sqflite.dart';
import '../utils/performance_tracker.dart';

class InstrumentedDatabaseExamples {
  late Database db;

  /// Example 1: Track a simple query operation
  Future<List<Map<String, dynamic>>> getMessagesWithTracking(
    String address,
  ) async {
    return PerformanceTracker.trackDatabaseOperation('query', () async {
      // Your actual database query
      return await db.query(
        'messages',
        where: 'address = ?',
        whereArgs: [address],
        orderBy: 'date DESC',
      );
    }, table: 'messages');
  }

  /// Example 2: Track batch insert with record count
  Future<void> batchInsertMessagesWithTracking(
    List<Map<String, dynamic>> messages,
  ) async {
    return PerformanceTracker.trackDatabaseOperation(
      'batch_insert',
      () async {
        final batch = db.batch();

        for (var message in messages) {
          batch.insert(
            'messages',
            message,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        await batch.commit(noResult: true);
      },
      table: 'messages',
      recordCount: messages.length, // Metadata: how many records inserted
    );
  }

  /// Example 3: Track search operation with metadata
  Future<List<Map<String, dynamic>>> searchMessagesWithTracking(
    String query,
  ) async {
    return PerformanceTracker.trackDatabaseOperation(
      'search',
      () async {
        final results = await db.query(
          'messages',
          where: 'body LIKE ?',
          whereArgs: ['%$query%'],
          orderBy: 'date DESC',
          limit: 50,
        );
        return results;
      },
      table: 'messages',
      additionalMetadata: {
        'query_length': query.length, // How long was the search query
      },
    );
  }
}
