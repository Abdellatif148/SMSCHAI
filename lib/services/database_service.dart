import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'smschat.db');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        address TEXT,
        body TEXT,
        date INTEGER,
        date_sent INTEGER,
        read INTEGER,
        type INTEGER, -- 1 = Received, 2 = Sent
        thread_id INTEGER,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_messages_address ON messages(address)');
    await db.execute('CREATE INDEX idx_messages_date ON messages(date DESC)');
    await db.execute(
      'CREATE INDEX idx_messages_thread_id ON messages(thread_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_sync_status ON messages(is_synced) WHERE is_synced = 0',
    );

    // Conversations/Threads table (optional, can be derived from messages but good for performance)
    await db.execute('''
      CREATE TABLE conversations (
        thread_id INTEGER PRIMARY KEY,
        address TEXT,
        snippet TEXT,
        date INTEGER,
        unread_count INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_conversations_date ON conversations(date DESC)',
    );

    // Contacts table (for caching)
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        display_name TEXT,
        phones TEXT, -- JSON string or comma separated
        avatar BLOB
      )
    ''');
  }

  // CRUD Operations

  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(String address) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'address = ?',
      whereArgs: [address],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final db = await database;
    return await db.query('messages', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;
    // This is a simplified query. In reality, you might group by thread_id or address
    // For now, let's just return unique addresses from messages if conversations table isn't fully managed yet
    // Or better, query the conversations table if we are maintaining it.
    // Let's stick to querying messages and grouping for now to keep it simple if we don't have complex thread logic yet.
    // But since we created a table, let's use it.
    return await db.query('conversations', orderBy: 'date DESC');
  }

  Future<void> updateConversation({
    required int threadId,
    required String address,
    required String snippet,
    required int date,
    bool incrementUnread = false,
    bool resetUnread = false,
  }) async {
    final db = await database;

    // Get existing conversation to handle unread count
    final existing = await db.query(
      'conversations',
      where: 'thread_id = ?',
      whereArgs: [threadId],
    );

    int unreadCount = 0;
    if (existing.isNotEmpty) {
      unreadCount = (existing.first['unread_count'] as int?) ?? 0;
    }

    if (resetUnread) {
      unreadCount = 0;
    } else if (incrementUnread) {
      unreadCount++;
    }

    await db.insert('conversations', {
      'thread_id': threadId,
      'address': address,
      'snippet': snippet,
      'date': date,
      'unread_count': unreadCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Batch insert messages with transaction (better performance)
  Future<void> batchInsertMessages(List<Map<String, dynamic>> messages) async {
    final db = await database;
    final batch = db.batch();

    for (var message in messages) {
      // Check for duplicates before inserting
      final existing = await db.query(
        'messages',
        where: 'address = ? AND date = ? AND body = ?',
        whereArgs: [message['address'], message['date'], message['body']],
        limit: 1,
      );

      if (existing.isEmpty) {
        batch.insert(
          'messages',
          message,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    await batch.commit(noResult: true);
  }

  // Check if message already exists (for deduplication)
  Future<bool> messageExists(Map<String, dynamic> message) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'address = ? AND date = ? AND body = ?',
      whereArgs: [message['address'], message['date'], message['body']],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Get unsynced messages for cloud upload
  Future<List<Map<String, dynamic>>> getUnsyncedMessages() async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'date ASC',
    );
  }

  // Mark messages as synced
  Future<void> markAsSynced(List<int> messageIds) async {
    final db = await database;
    final batch = db.batch();

    for (var id in messageIds) {
      batch.update(
        'messages',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  // Get messages with pagination
  Future<List<Map<String, dynamic>>> getMessagesPaginated(
    String address,
    int limit,
    int offset,
  ) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'address = ?',
      whereArgs: [address],
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Search messages by body text
  Future<List<Map<String, dynamic>>> searchMessages(String query) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'body LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'date DESC',
      limit: 50,
    );
  }

  // Get message count for a conversation
  Future<int> getMessageCount(String address) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE address = ?',
      [address],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
