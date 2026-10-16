import 'package:cohv/core/constants/api_constants.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/awareness_models.dart';

class AwarenessApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointAwarenessList = ApiConstants.endpointAwarenessList;
  static const String endpointCreateAwareness = ApiConstants.endpointCreateAwareness;

  final SyncRepository _syncRepository = SyncRepository();

  /// Fetch list of awareness activities
  Future<List<AwarenessItem>> getAwarenessList(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointAwarenessList?volunteer_id=$volunteerId'),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // if (response.statusCode == 200) {
    //   final List data = jsonDecode(response.body);
    //   return data.map((e) => AwarenessItem.fromJson(e)).toList();
    // } else {
    //   throw Exception('Failed to load awareness activities.');
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 400));

    // Simulated initial record matching prototype screenshot
    return [
      AwarenessItem(
        id: 'AWR-26-0006',
        activityType: 'Village meetings',
        date: DateTime(2026, 10, 13),
        village: 'Amrabad',
        peopleReached: 45,
        topicCovered: 'Sanitation and waste disposal',
        departmentInvolved: 'Multi-Sectoral Joint Team',
        status: 'synced',
        latitude: 28.60928,
        longitude: 77.367449,
        accuracy: 133,
        volunteerId: volunteerId,
        deviceId: 'DEV-C0YBZ9WK',
      ),
    ];
  }

  /// Create and submit a new awareness activity
  Future<AwarenessItem> createAwareness(AwarenessItem item) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // final response = await http.post(
    //   Uri.parse(endpointCreateAwareness),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(item.toJson()),
    // );
    // if (response.statusCode == 200 || response.statusCode == 201) {
    //   return AwarenessItem.fromJson(jsonDecode(response.body));
    // } else {
    //   throw Exception('Failed to save awareness activity.');
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 800));

    // Automatically enqueue into local offline Sync Repository
    await _syncRepository.enqueueRecord(
      entityType: 'AWR',
      payload: item.toJson(),
    );

    return item;
  }
}
