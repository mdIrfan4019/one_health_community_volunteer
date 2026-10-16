import 'package:cohv/core/constants/api_constants.dart';
import '../domain/dashboard_models.dart';

class DashboardApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointDashboardSummary = ApiConstants.endpointDashboardSummary;
  static const String endpointProfile = ApiConstants.endpointProfile;

  /// Fetch dynamic KPI metrics for the logged-in volunteer
  Future<DashboardMetrics> getDashboardMetrics(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointDashboardSummary?volunteer_id=$volunteerId'),
    //   headers: {'Authorization': 'Bearer $authToken'},
    // );
    // if (response.statusCode == 200) {
    //   return DashboardMetrics.fromJson(jsonDecode(response.body));
    // } else {
    //   throw Exception('Failed to load dashboard metrics.');
    // }
    // =======================================================================

    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Default seed metrics (matching prototype initial state)
    return DashboardMetrics(
      totalVisits: 0,
      alertsGenerated: 0,
      referrals: 0,
      pendingFollowUps: 0,
      awarenessActivities: 0,
      trainingsImparted: 0,
      trainingsAttended: 0,
      pendingSyncCount: 0,
    );
  }

  /// Fetch volunteer profile and demographic anchor
  Future<VolunteerProfile> getVolunteerProfile(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointProfile?volunteer_id=$volunteerId'),
    //   headers: {'Authorization': 'Bearer $authToken'},
    // );
    // if (response.statusCode == 200) {
    //   return VolunteerProfile.fromJson(jsonDecode(response.body));
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 500));

    return VolunteerProfile(
      fullName: 'Ramu',
      volunteerId: volunteerId.isNotEmpty ? volunteerId : 'COHV-26-0013',
      status: 'Active',
      locationBreadcrumb: 'Mannanur · Amrabad · Nagarkurnool',
    );
  }
}
