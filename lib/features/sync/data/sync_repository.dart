// Create file: lib/features/sync/data/sync_repository.dart

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

  void _seedInitialRecords() {
    // 10 initial synced records matching the prototype UI screenshot
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
    return record;
  }

  /// Get summary counters for UI
  SyncSummary getSummary() {
    final pending = _records.where((r) => r.status == SyncStatus.pending).length;
    final synced = _records.where((r) => r.status == SyncStatus.synced).length;
    final isOnline = _connectionOverride ?? true;

    return SyncSummary(
      totalRecords: _records.length,
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
