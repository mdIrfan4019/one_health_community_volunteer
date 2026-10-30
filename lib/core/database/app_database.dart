import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Central SQLite Database for One Health Offline Storage.
/// Manages Master Data Lookups, Offline Outbox Queue, and Local Media Vault.
class AppDatabase {
  static const String _dbName = 'one_health_offline.db';
  static const int _dbVersion = 1;

  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    debugPrint('[DATABASE] Initializing SQLite database at: $path');

    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[DATABASE] Creating database tables (version $version)...');

    // 1. Table for caching master dropdowns (villages, training masters, facilities, topics, etc.)
    await db.execute('''
      CREATE TABLE master_lookups (
        category TEXT NOT NULL,
        key_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (category, key_id)
      )
    ''');

    // 2. Table for storing forms submitted offline (The Outbox)
    await db.execute('''
      CREATE TABLE offline_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_ref TEXT UNIQUE NOT NULL,
        entity_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        error_message TEXT,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // 3. Table for tracking media attachments awaiting upload
    await db.execute('''
      CREATE TABLE offline_media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_ref TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size INTEGER DEFAULT 0,
        upload_status TEXT NOT NULL,
        remote_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 4. Table for caching volunteer's previously fetched records for offline browsing
    await db.execute('''
      CREATE TABLE cached_records (
        entity_type TEXT NOT NULL,
        record_id TEXT NOT NULL,
        volunteer_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (entity_type, record_id, volunteer_id)
      )
    ''');

    debugPrint('[DATABASE] Tables created successfully.');
  }

  // =========================================================================
  // 📚 MASTER LOOKUPS API (Dropdown Caching for 100% Offline Forms)
  // =========================================================================

  /// Save or replace a list of master lookup items for a specific category.
  Future<void> saveMasterLookupBatch({
    required String category,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) keyExtractor,
    bool clearExisting = true,
  }) async {
    if (items.isEmpty) return;
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toUtc().toIso8601String();

      // Clear existing records for this category to keep data fresh if requested
      if (clearExisting) {
        batch.delete(
          'master_lookups',
          where: 'category = ?',
          whereArgs: [category],
        );
      }

      for (final item in items) {
        final keyId = keyExtractor(item);
        if (keyId.isEmpty || keyId == 'null_null') continue;
        batch.insert('master_lookups', {
          'category': category,
          'key_id': keyId,
          'data_json': jsonEncode(item),
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      debugPrint(
        '[DATABASE] Saved ${items.length} master items for [$category]',
      );
    } catch (e) {
      debugPrint('[DATABASE] Error saving master lookup batch [$category]: $e');
    }
  }

  /// Removes any corrupt rows with null_null or empty key_ids
  Future<void> cleanCorruptLookups() async {
    try {
      final db = await database;
      await db.delete(
        'master_lookups',
        where: "key_id = 'null_null' OR key_id = ''",
      );
    } catch (_) {}
  }

  /// Retrieve all master items for a specific category.
  Future<List<Map<String, dynamic>>> getMasterLookupList(
    String category,
  ) async {
    try {
      final db = await database;
      final rows = await db.query(
        'master_lookups',
        where: 'category = ?',
        whereArgs: [category],
      );

      return rows
          .map((r) {
            try {
              return jsonDecode(r['data_json'] as String)
                  as Map<String, dynamic>;
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('[DATABASE] Error reading master lookups [$category]: $e');
      return [];
    }
  }

  // =========================================================================
  // 📤 OFFLINE OUTBOX QUEUE (Form Submissions Saved While Offline)
  // =========================================================================

  /// Enqueue an offline form submission into the SQLite outbox.
  Future<int> enqueueRecord({
    required String clientRef,
    required String entityType,
    required Map<String, dynamic> payload,
    List<String> mediaPaths = const [],
    List<String> videoPaths = const [],
    List<String> documentPaths = const [],
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    return await db.transaction((txn) async {
      // 1. Insert outbox record
      final recordId = await txn.insert('offline_outbox', {
        'client_ref': clientRef,
        'entity_type': entityType,
        'payload_json': jsonEncode(payload),
        'status': 'PENDING',
        'retry_count': 0,
        'error_message': null,
        'created_at': now,
        'synced_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Insert associated photos
      for (final path in mediaPaths) {
        if (path.trim().isEmpty) continue;
        await txn.insert('offline_media', {
          'client_ref': clientRef,
          'file_path': path.trim(),
          'file_type': 'photo',
          'file_size': 0,
          'upload_status': 'PENDING',
          'remote_url': null,
          'created_at': now,
        });
      }

      // 3. Insert associated videos
      for (final path in videoPaths) {
        if (path.trim().isEmpty) continue;
        await txn.insert('offline_media', {
          'client_ref': clientRef,
          'file_path': path.trim(),
          'file_type': 'video',
          'file_size': 0,
          'upload_status': 'PENDING',
          'remote_url': null,
          'created_at': now,
        });
      }

      // 4. Insert associated documents
      for (final path in documentPaths) {
        if (path.trim().isEmpty) continue;
        await txn.insert('offline_media', {
          'client_ref': clientRef,
          'file_path': path.trim(),
          'file_type': 'document',
          'file_size': 0,
          'upload_status': 'PENDING',
          'remote_url': null,
          'created_at': now,
        });
      }

      debugPrint('[DATABASE] Enqueued outbox record $clientRef ($entityType)');
      return recordId;
    });
  }

  /// Get all records currently waiting to be synchronised (pending, syncing, or failed retry).
  Future<List<Map<String, dynamic>>> getPendingRecords() async {
    final db = await database;
    return await db.query(
      'offline_outbox',
      where: "status != 'SYNCED'",
      orderBy: 'id ASC',
    );
  }

  /// Get pending unsynced records count for UI badge and sync dispatch.
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM offline_outbox WHERE status != 'SYNCED'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get successfully synchronised records count from SQLite.
  Future<int> getSyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM offline_outbox WHERE status = 'SYNCED'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get failed records count from SQLite.
  Future<int> getFailedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM offline_outbox WHERE status = 'FAILED'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total count of all records in outbox (pending + synced).
  Future<int> getTotalOutboxCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_outbox',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark an outbox record status (e.g. SYNCED, FAILED, SYNCING).
  Future<void> updateRecordStatus({
    required String clientRef,
    required String status,
    String? errorMessage,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.update(
      'offline_outbox',
      {
        'status': status,
        if (errorMessage != null) ...{'error_message': errorMessage},
        if (status == 'SYNCED') 'synced_at': now,
      },
      where: 'client_ref = ?',
      whereArgs: [clientRef],
    );
  }

  /// Get all outbox records for a given entity type (e.g. 'EVENT', 'REFERRAL').
  Future<List<Map<String, dynamic>>> getOutboxRecordsByEntity(
    String entityType,
  ) async {
    final db = await database;
    return await db.query(
      'offline_outbox',
      where: 'entity_type = ?',
      whereArgs: [entityType],
      orderBy: 'id DESC',
    );
  }

  // =========================================================================
  // 📥 CACHED HISTORICAL RECORDS (Offline Browsing)
  // =========================================================================

  /// Cache list of records returned by server for offline browsing.
  Future<void> cacheRecordsList({
    required String entityType,
    required String volunteerId,
    required List<Map<String, dynamic>> records,
    required String Function(Map<String, dynamic>) idExtractor,
  }) async {
    if (records.isEmpty) return;
    try {
      final db = await database;
      final batch = db.batch();
      final now = DateTime.now().toUtc().toIso8601String();

      for (final record in records) {
        final recordId = idExtractor(record);
        batch.insert('cached_records', {
          'entity_type': entityType,
          'record_id': recordId,
          'volunteer_id': volunteerId,
          'data_json': jsonEncode(record),
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[DATABASE] Error caching records for [$entityType]: $e');
    }
  }

  /// Retrieve cached historical records for offline viewing.
  Future<List<Map<String, dynamic>>> getCachedRecordsList({
    required String entityType,
    required String volunteerId,
  }) async {
    try {
      final db = await database;
      final rows = (volunteerId.trim().isNotEmpty)
          ? await db.query(
              'cached_records',
              where: 'entity_type = ? AND volunteer_id = ?',
              whereArgs: [entityType, volunteerId.trim()],
              orderBy: 'updated_at DESC',
            )
          : await db.query(
              'cached_records',
              where: 'entity_type = ?',
              whereArgs: [entityType],
              orderBy: 'updated_at DESC',
            );

      return rows
          .map((r) {
            try {
              return jsonDecode(r['data_json'] as String)
                  as Map<String, dynamic>;
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('[DATABASE] Error reading cached records [$entityType]: $e');
      return [];
    }
  }
}
