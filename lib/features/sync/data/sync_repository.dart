import 'package:cohv/core/database/app_database.dart';
import '../domain/sync_models.dart';

class SyncRepository {
  // Singleton pattern so all modules share the same offline queue
  static final SyncRepository _instance = SyncRepository._internal();
  factory SyncRepository() => _instance;
  SyncRepository._internal() {
    _seedInitialRecords();
  }

  final List<SyncRecord> _records = [];
  bool? _connectionOverride = true; // Default simulated 'Treat as connected'
  int _dbPendingCount = 0;
  int _dbSyncedCount = 0;
  int _dbTotalCount = 0;
  bool _hasLoadedFromDb = false;

  /// Asynchronously refresh counts from SQLite AppDatabase
  Future<SyncSummary> refreshFromDatabase() async {
    try {
      _dbPendingCount = await AppDatabase.instance.getPendingCount();
      _dbSyncedCount = await AppDatabase.instance.getSyncedCount();
      _dbTotalCount = await AppDatabase.instance.getTotalOutboxCount();
      _hasLoadedFromDb = true;
    } catch (_) {}
    return getSummary();
  }

  void _seedInitialRecords() {
    // Initial records matching the prototype UI screenshot before DB load
    for (int i = 1; i <= 10; i++) {
      _records.add(
        SyncRecord(
          id: 'REC-26-${i.toString().padLeft(4, '0')}',
          entityType: 'VISIT',
          payload: {'notes': 'Initial surveillance record $i'},
          capturedAt: DateTime.now().subtract(Duration(hours: 24 - i)),
          status: SyncStatus.synced,
          syncedAt: DateTime.now().subtract(Duration(hours: 24 - i)),
        ),
      );
    }
  }

  /// Add a newly created form entry to the local offline queue
  Future<SyncRecord> enqueueRecord({
    required String entityType,
    required Map<String, dynamic> payload,
  }) async {
    final sequence = _records.length + 1;
    final record = SyncRecord(
      id: 'REC-26-${sequence.toString().padLeft(4, '0')}',
      entityType: entityType,
      payload: payload,
      capturedAt: DateTime.now(),
      status: SyncStatus.pending,
    );
    _records.add(record);
    await refreshFromDatabase();
    return record;
  }

  /// Get summary counters for UI
  SyncSummary getSummary() {
    final int total;
    final int pending;
    final int synced;

    if (_hasLoadedFromDb) {
      total = _dbTotalCount;
      pending = _dbPendingCount;
      synced = _dbSyncedCount;
    } else {
      final pendingInMemory =
          _records.where((r) => r.status == SyncStatus.pending).length;
      pending = _dbPendingCount > 0 ? _dbPendingCount : pendingInMemory;
      total = _dbTotalCount > 0 ? _dbTotalCount : _records.length;
      synced = _dbSyncedCount > 0
          ? _dbSyncedCount
          : (total - pending).clamp(0, total);
    }

    final isOnline = _connectionOverride ?? true;

    return SyncSummary(
      totalRecords: total,
      pendingSync: pending,
      synchronised: synced,
      isOnline: isOnline,
      isOverridden: _connectionOverride != null,
    );
  }

  List<SyncRecord> getPendingRecords() {
    return _records.where((r) => r.status == SyncStatus.pending).toList();
  }

  void markRecordsAsSynced(List<String> recordIds) {
    for (var record in _records) {
      if (recordIds.contains(record.id)) {
        record.status = SyncStatus.synced;
        record.syncedAt = DateTime.now();
      }
    }
  }

  void setConnectionOverride(bool? overrideValue) {
    _connectionOverride = overrideValue;
  }
}
