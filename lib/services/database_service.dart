import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Messages table with extended features
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
        is_synced INTEGER DEFAULT 0,
        media_url TEXT,
        media_type TEXT, -- 'text', 'image', 'video', 'audio', 'file'
        reply_to_id INTEGER,
        is_pinned INTEGER DEFAULT 0,
        reactions TEXT, -- JSON string of reactions
        is_deleted INTEGER DEFAULT 0,
        edited_at INTEGER,
        group_id TEXT,
        sender_id TEXT,
        delivery_status TEXT DEFAULT 'sent', -- 'sent', 'delivered', 'read'
        FOREIGN KEY (reply_to_id) REFERENCES messages(id)
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
    await db.execute(
      'CREATE INDEX idx_messages_group_id ON messages(group_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_pinned ON messages(is_pinned) WHERE is_pinned = 1',
    );

    // Conversations/Threads table
    await db.execute('''
      CREATE TABLE conversations (
        thread_id INTEGER PRIMARY KEY,
        address TEXT,
        snippet TEXT,
        date INTEGER,
        unread_count INTEGER,
        is_group INTEGER DEFAULT 0,
        group_name TEXT,
        group_icon_url TEXT
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

    // Groups table
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_url TEXT,
        owner_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_groups_owner ON groups(owner_id)');

    // Group members table
    await db.execute('''
      CREATE TABLE group_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT DEFAULT 'member', -- 'owner', 'admin', 'member'
        joined_at INTEGER NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
        UNIQUE(group_id, user_id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_group_members_group ON group_members(group_id)',
    );
    await db.execute(
      'CREATE INDEX idx_group_members_user ON group_members(user_id)',
    );

    // Typing indicators table (for real-time features)
    await db.execute('''
      CREATE TABLE typing_indicators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        UNIQUE(conversation_id, user_id)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to messages table
      await db.execute('ALTER TABLE messages ADD COLUMN media_url TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN media_type TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN reply_to_id INTEGER');
      await db.execute(
        'ALTER TABLE messages ADD COLUMN is_pinned INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE messages ADD COLUMN reactions TEXT');
      await db.execute(
        'ALTER TABLE messages ADD COLUMN is_deleted INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE messages ADD COLUMN edited_at INTEGER');
      await db.execute('ALTER TABLE messages ADD COLUMN group_id TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN sender_id TEXT');
      await db.execute(
        'ALTER TABLE messages ADD COLUMN delivery_status TEXT DEFAULT \'sent\'',
      );

      // Add indexes for new columns
      await db.execute(
        'CREATE INDEX idx_messages_group_id ON messages(group_id)',
      );
      await db.execute(
        'CREATE INDEX idx_messages_pinned ON messages(is_pinned) WHERE is_pinned = 1',
      );

      // Add new columns to conversations table
      await db.execute(
        'ALTER TABLE conversations ADD COLUMN is_group INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE conversations ADD COLUMN group_name TEXT');
      await db.execute(
        'ALTER TABLE conversations ADD COLUMN group_icon_url TEXT',
      );

      // Create new tables
      await db.execute('''
        CREATE TABLE groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon_url TEXT,
          owner_id TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          description TEXT
        )
      ''');

      await db.execute('CREATE INDEX idx_groups_owner ON groups(owner_id)');

      await db.execute('''
        CREATE TABLE group_members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          role TEXT DEFAULT 'member',
          joined_at INTEGER NOT NULL,
          FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
          UNIQUE(group_id, user_id)
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_group_members_group ON group_members(group_id)',
      );
      await db.execute(
        'CREATE INDEX idx_group_members_user ON group_members(user_id)',
      );

      await db.execute('''
        CREATE TABLE typing_indicators (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          conversation_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          UNIQUE(conversation_id, user_id)
        )
      ''');
    }
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
      where: 'address = ? AND group_id IS NULL',
      whereArgs: [address],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getGroupMessages(String groupId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'group_id = ?',
      whereArgs: [groupId],
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
    String addressOrGroupId,
    int limit,
    int offset, {
    bool isGroup = false,
  }) async {
    final db = await database;
    if (isGroup) {
      return await db.query(
        'messages',
        where: 'group_id = ?',
        whereArgs: [addressOrGroupId],
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );
    } else {
      return await db.query(
        'messages',
        where: 'address = ? AND group_id IS NULL',
        whereArgs: [addressOrGroupId],
        orderBy: 'date DESC',
        limit: limit,
        offset: offset,
      );
    }
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

  // Delete a conversation and optionally its messages
  Future<void> deleteConversation(
    int threadId, {
    bool deleteMessages = false,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete the conversation entry
      await txn.delete(
        'conversations',
        where: 'thread_id = ?',
        whereArgs: [threadId],
      );

      // Optionally delete all associated messages
      if (deleteMessages) {
        await txn.delete(
          'messages',
          where: 'thread_id = ?',
          whereArgs: [threadId],
        );
      }
    });
  }

  // Clear all data from the database
  Future<void> clearAllData() async {
    final db = await database;

    await db.transaction((txn) async {
      // Delete all messages
      await txn.delete('messages');
      // Delete all conversations
      await txn.delete('conversations');
      // Delete all contacts
      await txn.delete('contacts');
      // Delete all groups
      await txn.delete('groups');
      // Delete all group members
      await txn.delete('group_members');
      // Delete all typing indicators
      await txn.delete('typing_indicators');
    });
  }

  // ===== Group Chat Methods =====

  // Create a new group
  Future<String> createGroup({
    required String name,
    required String ownerId,
    String? iconUrl,
    String? description,
  }) async {
    final db = await database;
    final groupId = '${ownerId}_${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now().millisecondsSinceEpoch;

    await db.insert('groups', {
      'id': groupId,
      'name': name,
      'icon_url': iconUrl,
      'owner_id': ownerId,
      'created_at': createdAt,
      'description': description,
    });

    // Add owner as first member
    await addGroupMember(groupId: groupId, userId: ownerId, role: 'owner');

    // Add to conversations list
    await db.insert('conversations', {
      'address': name,
      'snippet': 'Group created',
      'date': createdAt,
      'unread_count': 0,
      'is_group': 1,
      'group_id': groupId,
      'group_name': name,
      'group_icon_url': iconUrl,
    });

    return groupId;
  }

  // Add a member to a group
  Future<void> addGroupMember({
    required String groupId,
    required String userId,
    String role = 'member',
  }) async {
    final db = await database;
    await db.insert('group_members', {
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'joined_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Remove a member from a group
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    final db = await database;
    await db.delete(
      'group_members',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  // Get all members of a group
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final db = await database;
    return await db.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  // Get all groups for a user
  Future<List<Map<String, dynamic>>> getUserGroups(String userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT g.* FROM groups g
      INNER JOIN group_members gm ON g.id = gm.group_id
      WHERE gm.user_id = ?
      ORDER BY g.created_at DESC
    ''',
      [userId],
    );
  }

  // Get group info
  Future<Map<String, dynamic>?> getGroup(String groupId) async {
    final db = await database;
    final result = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [groupId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update group info
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? iconUrl,
    String? description,
  }) async {
    final db = await database;
    final Map<String, dynamic> updates = {};

    if (name != null) updates['name'] = name;
    if (iconUrl != null) updates['icon_url'] = iconUrl;
    if (description != null) updates['description'] = description;

    if (updates.isNotEmpty) {
      await db.update('groups', updates, where: 'id = ?', whereArgs: [groupId]);
    }
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete group (members will be cascade deleted)
      await txn.delete('groups', where: 'id = ?', whereArgs: [groupId]);
      // Delete group messages
      await txn.delete('messages', where: 'group_id = ?', whereArgs: [groupId]);
    });
  }

  // ===== Message Reaction Methods =====

  // Add a reaction to a message
  Future<void> addReaction({
    required int messageId,
    required String userId,
    required String emoji,
  }) async {
    final db = await database;

    // Get current reactions
    final result = await db.query(
      'messages',
      columns: ['reactions'],
      where: 'id = ?',
      whereArgs: [messageId],
    );

    if (result.isEmpty) return;

    Map<String, dynamic> reactions = {};
    if (result.first['reactions'] != null) {
      try {
        reactions = Map<String, dynamic>.from(
          parseJson(result.first['reactions'] as String),
        );
      } catch (e) {
        reactions = {};
      }
    }

    // Add new reaction
    if (!reactions.containsKey(emoji)) {
      reactions[emoji] = [];
    }
    (reactions[emoji] as List).add(userId);

    await db.update(
      'messages',
      {'reactions': stringifyJson(reactions)},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Remove a reaction from a message
  Future<void> removeReaction({
    required int messageId,
    required String userId,
    required String emoji,
  }) async {
    final db = await database;

    final result = await db.query(
      'messages',
      columns: ['reactions'],
      where: 'id = ?',
      whereArgs: [messageId],
    );

    if (result.isEmpty) return;

    Map<String, dynamic> reactions = {};
    if (result.first['reactions'] != null) {
      try {
        reactions = Map<String, dynamic>.from(
          parseJson(result.first['reactions'] as String),
        );
      } catch (e) {
        return;
      }
    }

    // Remove reaction
    if (reactions.containsKey(emoji)) {
      (reactions[emoji] as List).remove(userId);
      if ((reactions[emoji] as List).isEmpty) {
        reactions.remove(emoji);
      }
    }

    await db.update(
      'messages',
      {'reactions': stringifyJson(reactions)},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // ===== Pin/Unpin Methods =====

  Future<void> pinMessage(int messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_pinned': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> unpinMessage(int messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_pinned': 0},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Get pinned messages for a conversation
  Future<List<Map<String, dynamic>>> getPinnedMessages(String address) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'address = ? AND is_pinned = 1',
      whereArgs: [address],
      orderBy: 'date DESC',
    );
  }

  // ===== Edit/Delete Methods =====

  Future<void> editMessage({
    required int messageId,
    required String newBody,
  }) async {
    final db = await database;
    await db.update(
      'messages',
      {'body': newBody, 'edited_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Soft delete a message
  Future<void> deleteMessage(int messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Hard delete a message (permanent)
  Future<void> permanentlyDeleteMessage(int messageId) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  // ===== Typing Indicator Methods =====

  Future<void> setTyping({
    required String conversationId,
    required String userId,
  }) async {
    final db = await database;
    await db.insert('typing_indicators', {
      'conversation_id': conversationId,
      'user_id': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearTyping({
    required String conversationId,
    required String userId,
  }) async {
    final db = await database;
    await db.delete(
      'typing_indicators',
      where: 'conversation_id = ? AND user_id = ?',
      whereArgs: [conversationId, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getTypingUsers(
    String conversationId,
  ) async {
    final db = await database;
    // Clean up old typing indicators (> 5 seconds old)
    final cutoff = DateTime.now().millisecondsSinceEpoch - 5000;
    await db.delete(
      'typing_indicators',
      where: 'timestamp < ?',
      whereArgs: [cutoff],
    );

    return await db.query(
      'typing_indicators',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  // ===== Delivery Status Methods =====

  Future<void> updateDeliveryStatus({
    required int messageId,
    required String status, // 'sent', 'delivered', 'read'
  }) async {
    final db = await database;
    await db.update(
      'messages',
      {'delivery_status': status},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // ===== Helper Methods =====

  dynamic parseJson(String jsonString) {
    try {
      if (jsonString.isEmpty || jsonString == 'null') return {};
      return json.decode(jsonString);
    } catch (e) {
      return {};
    }
  }

  String stringifyJson(dynamic data) {
    try {
      return json.encode(data);
    } catch (e) {
      return '';
    }
  }
}
