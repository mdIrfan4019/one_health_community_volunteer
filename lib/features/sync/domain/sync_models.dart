// Create file: lib/features/sync/domain/sync_models.dart

enum SyncStatus { pending, syncing, synced, failed }

class SyncRecord {
  final String id; // e.g. REC-26-0001
  final String entityType; // e.g. VISIT, REF, AWR, SMP, TRN, STY
  final Map<String, dynamic> payload;
  final DateTime capturedAt;
  SyncStatus status;
  DateTime? syncedAt;
  String? errorMessage;

  SyncRecord({
    required this.id,
    required this.entityType,
    required this.payload,
    required this.capturedAt,
    this.status = SyncStatus.pending,
    this.syncedAt,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'entity_type': entityType,
    'payload': payload,
    'captured_at': capturedAt.toIso8601String(),
    'status': status.name,
    'synced_at': syncedAt?.toIso8601String(),
  };

  factory SyncRecord.fromJson(Map<String, dynamic> json) => SyncRecord(
    id: json['id'] ?? '',
    entityType: json['entity_type'] ?? 'VISIT',
    payload: Map<String, dynamic>.from(json['payload'] ?? {}),
    capturedAt: DateTime.parse(json['captured_at']),
    status: SyncStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SyncStatus.synced,
    ),
    syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
  );
}

class SyncSummary {
  final int totalRecords;
  final int pendingSync;
  final int synchronised;
  final bool isOnline;
  final bool isOverridden;

  SyncSummary({
    required this.totalRecords,
    required this.pendingSync,
    required this.synchronised,
    required this.isOnline,
    required this.isOverridden,
  });
}
