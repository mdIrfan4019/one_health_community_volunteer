import 'package:cohv/core/constants/api_constants.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/referral_models.dart';

class ReferralsApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointReferralsList = ApiConstants.endpointReferralsList;
  static const String endpointCreateReferral = ApiConstants.endpointCreateReferral;

  final SyncRepository _syncRepository = SyncRepository();

  /// Fetch list of referrals for the volunteer
  Future<List<ReferralItem>> getReferrals(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointReferralsList?volunteer_id=$volunteerId'),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // if (response.statusCode == 200) {
    //   final List data = jsonDecode(response.body);
    //   return data.map((e) => ReferralItem.fromJson(e)).toList();
    // } else {
    //   throw Exception('Failed to load referrals.');
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 400));

    // Simulated initial record matching prototype screenshot
    return [
      ReferralItem(
        id: 'REF-26-0005',
        facilityName: 'CHC',
        stream: 'Human',
        referralType: 'CHC',
        village: 'Amrabad',
        eventDate: DateTime(2026, 10, 13),
        referralDate: DateTime(2026, 10, 13),
        reason: 'Severe persistent fever cluster',
        isFollowedUp: true,
        status: 'synced',
        latitude: 28.60928,
        longitude: 77.367449,
        accuracy: 133,
        volunteerId: volunteerId,
        deviceId: 'DEV-C0YBZ9WK',
      ),
    ];
  }

  /// Create and submit a new referral
  Future<ReferralItem> createReferral(ReferralItem item) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // final response = await http.post(
    //   Uri.parse(endpointCreateReferral),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(item.toJson()),
    // );
    // if (response.statusCode == 200 || response.statusCode == 201) {
    //   return ReferralItem.fromJson(jsonDecode(response.body));
    // } else {
    //   throw Exception('Failed to save referral.');
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 800));

    // Automatically enqueue into local offline Sync Repository
    await _syncRepository.enqueueRecord(
      entityType: 'REF',
      payload: item.toJson(),
    );

    return item;
  }
}
