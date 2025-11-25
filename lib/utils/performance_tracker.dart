import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized performance tracking utility for Sentry Performance Monitoring
class PerformanceTracker {
  /// Start a new transaction for top-level operations
  static Future<ISentrySpan?> startTransaction(
    String name, {
    String operation = 'task',
    Map<String, dynamic>? metadata,
  }) async {
    final transaction = Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );

    // Add custom metadata
    if (metadata != null) {
      metadata.forEach((key, value) {
        transaction.setData(key, value);
      });
    }

    return transaction;
  }

  /// Start a child span within a transaction
  static ISentrySpan? startSpan(
    ISentrySpan parent,
    String operation, {
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    final span = parent.startChild(operation, description: description);

    // Add custom metadata
    if (metadata != null) {
      metadata.forEach((key, value) {
        span.setData(key, value);
      });
    }

    return span;
  }

  /// Track any async operation with automatic span management
  static Future<T> recordOperation<T>(
    String operation,
    Future<T> Function() operation_, {
    String? description,
    Map<String, dynamic>? metadata,
    String transactionName = 'operation',
  }) async {
    final transaction = await startTransaction(
      transactionName,
      operation: operation,
      metadata: metadata,
    );

    try {
      final result = await operation_();
      transaction?.status = const SpanStatus.ok();
      return result;
    } catch (e) {
      transaction?.status = const SpanStatus.internalError();
      transaction?.throwable = e;
      rethrow;
    } finally {
      await transaction?.finish();
    }
  }

  /// Track database operations
  static Future<T> trackDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    String? table,
    int? recordCount,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final metadata = <String, dynamic>{
      'db.system': 'sqlite',
      if (table != null) 'db.table': table,
      if (recordCount != null) 'record_count': recordCount,
      ...?additionalMetadata,
    };

    return recordOperation(
      'db.$operationName',
      operation,
      description: table != null ? '$operationName on $table' : operationName,
      metadata: metadata,
      transactionName: 'db.$operationName',
    );
  }

  /// Track network requests
  static Future<T> trackNetworkRequest<T>(
    String endpoint,
    Future<T> Function() operation, {
    String method = 'POST',
    int? fileSize,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final metadata = <String, dynamic>{
      'http.method': method,
      'http.endpoint': endpoint,
      if (fileSize != null) 'file_size_bytes': fileSize,
      ...?additionalMetadata,
    };

    return recordOperation(
      'http.request',
      operation,
      description: '$method $endpoint',
      metadata: metadata,
      transactionName: 'network.$endpoint',
    );
  }

  /// Track SMS operations
  static Future<T> trackSmsOperation<T>(
    String operationType,
    Future<T> Function() operation, {
    String? recipient,
    int? messageCount,
    bool? hasAttachment,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final metadata = <String, dynamic>{
      'sms.type': operationType,
      if (recipient != null) 'sms.recipient': recipient,
      if (messageCount != null) 'message_count': messageCount,
      if (hasAttachment != null) 'has_attachment': hasAttachment,
      ...?additionalMetadata,
    };

    return recordOperation(
      'sms.$operationType',
      operation,
      description: 'SMS $operationType',
      metadata: metadata,
      transactionName: 'sms.$operationType',
    );
  }

  /// Manually finish a span with status
  static Future<void> finishSpan(
    ISentrySpan? span, {
    SpanStatus status = const SpanStatus.ok(),
    dynamic error,
  }) async {
    if (span == null) return;

    span.status = status;
    if (error != null) {
      span.throwable = error;
    }
    await span.finish();
  }
}
