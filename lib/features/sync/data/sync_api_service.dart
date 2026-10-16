import 'package:cohv/core/constants/api_constants.dart';
import '../domain/sync_models.dart';

class SyncApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointSyncBatch = ApiConstants.endpointSyncBatch;

  /// Upload batch of offline pending records to server
  Future<List<String>> uploadBatch({
    required String volunteerId,
    required List<SyncRecord> records,
  }) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // final response = await http.post(
    //   Uri.parse(endpointSyncBatch),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     // 'Authorization': 'Bearer $token',
    //   },
    //   body: jsonEncode({
    //     'volunteer_id': volunteerId,
    //     'records': records.map((r) => r.toJson()).toList(),
    //   }),
    // );
    //
    // if (response.statusCode == 200 || response.statusCode == 201) {
    //   final data = jsonDecode(response.body);
    //   final List uploadedIds = data['synced_ids'] ?? [];
    //   return uploadedIds.map((e) => e.toString()).toList();
    // } else {
    //   throw Exception('Server rejected synchronization batch.');
    // }
    // =======================================================================

    // Simulated network transmission delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Simulated successful upload response
    return records.map((r) => r.id).toList();
  }
}
