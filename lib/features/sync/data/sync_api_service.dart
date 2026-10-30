import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/database/offline_sync_service.dart';
import '../domain/sync_models.dart';

class SyncApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointSyncBatch = ApiConstants.endpointSyncBatch;

  /// Upload batch of offline pending records to server using the offline outbox engine.
  Future<List<String>> uploadBatch({
    required String volunteerId,
    required List<SyncRecord> records,
  }) async {
    final result = await OfflineSyncService.instance.syncAllPending();
    return records.take(result.syncedCount).map((r) => r.id).toList();
  }
}
