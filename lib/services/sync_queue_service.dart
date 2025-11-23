import 'dart:async';
import 'dart:collection';
import 'database_service.dart';
import 'supabase_service.dart';
import 'logger_service.dart';

enum SyncOperation { upload, download }

class SyncQueueItem {
  final String id;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final int priority;
  int retryCount;
  DateTime? lastAttempt;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.data,
    this.priority = 0,
    this.retryCount = 0,
    this.lastAttempt,
  });
}

class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final DatabaseService _dbService = DatabaseService();
  final SupabaseService _supabaseService = SupabaseService();
  final LoggerService _logger = LoggerService();

  final Queue<SyncQueueItem> _uploadQueue = Queue();
  final Queue<SyncQueueItem> _downloadQueue = Queue();

  bool _isProcessing = false;
  Timer? _retryTimer;

  static const int _maxRetries = 3;
  static const int _baseRetryDelay = 2; // seconds

  // Add item to upload queue
  void enqueueUpload(Map<String, dynamic> message, {int priority = 0}) {
    final item = SyncQueueItem(
      id: '${message['id']}_${DateTime.now().millisecondsSinceEpoch}',
      operation: SyncOperation.upload,
      data: message,
      priority: priority,
    );

    _uploadQueue.add(item);
    _logger.debug('Enqueued upload: ${item.id}');
    _processQueue();
  }

  // Add item to download queue
  void enqueueDownload(Map<String, dynamic> message, {int priority = 0}) {
    final item = SyncQueueItem(
      id: '${message['id']}_${DateTime.now().millisecondsSinceEpoch}',
      operation: SyncOperation.download,
      data: message,
      priority: priority,
    );

    _downloadQueue.add(item);
    _logger.debug('Enqueued download: ${item.id}');
    _processQueue();
  }

  // Process queues
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Process uploads first (higher priority)
      while (_uploadQueue.isNotEmpty) {
        final item = _uploadQueue.first;
        final success = await _processUpload(item);

        if (success) {
          _uploadQueue.removeFirst();
          _logger.info('Upload successful: ${item.id}');
        } else {
          // Handle retry with exponential backoff
          _handleRetry(item, _uploadQueue);
          break; // Stop processing this queue for now
        }
      }

      // Process downloads
      while (_downloadQueue.isNotEmpty) {
        final item = _downloadQueue.first;
        final success = await _processDownload(item);

        if (success) {
          _downloadQueue.removeFirst();
          _logger.info('Download successful: ${item.id}');
        } else {
          _handleRetry(item, _downloadQueue);
          break;
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Queue processing error', e, stackTrace);
    } finally {
      _isProcessing = false;
    }
  }

  // Process individual upload
  Future<bool> _processUpload(SyncQueueItem item) async {
    try {
      item.lastAttempt = DateTime.now();
      await _supabaseService.uploadMessage(item.data, encrypt: true);

      // Mark as synced in local DB
      if (item.data['id'] != null) {
        await _dbService.markAsSynced([item.data['id']]);
      }

      return true;
    } catch (e, stackTrace) {
      _logger.warning('Upload failed: ${item.id}', e, stackTrace);
      return false;
    }
  }

  // Process individual download
  Future<bool> _processDownload(SyncQueueItem item) async {
    try {
      item.lastAttempt = DateTime.now();

      // Check if message already exists
      if (await _dbService.messageExists(item.data)) {
        return true; // Skip duplicate
      }

      await _dbService.insertMessage(item.data);
      return true;
    } catch (e, stackTrace) {
      _logger.warning('Download failed: ${item.id}', e, stackTrace);
      return false;
    }
  }

  // Handle retry with exponential backoff
  void _handleRetry(SyncQueueItem item, Queue<SyncQueueItem> queue) {
    item.retryCount++;

    if (item.retryCount >= _maxRetries) {
      _logger.error('Max retries exceeded for ${item.id}, removing from queue');
      queue.removeFirst();
      return;
    }

    // Exponential backoff: 2^retryCount seconds
    final retryDelay = Duration(
      seconds: _baseRetryDelay * (1 << item.retryCount),
    );

    _logger.info(
      'Scheduling retry ${item.retryCount}/$_maxRetries for ${item.id} in ${retryDelay.inSeconds}s',
    );

    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, () {
      _processQueue();
    });
  }

  // Get queue status
  Map<String, dynamic> getStatus() {
    return {
      'uploadQueueSize': _uploadQueue.length,
      'downloadQueueSize': _downloadQueue.length,
      'isProcessing': _isProcessing,
    };
  }

  // Clear all queues (use with caution)
  void clearQueues() {
    _uploadQueue.clear();
    _downloadQueue.clear();
    _retryTimer?.cancel();
    _logger.warning('All sync queues cleared');
  }

  // Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    clearQueues();
  }
}
