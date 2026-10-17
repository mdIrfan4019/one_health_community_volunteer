// import 'package:cohv/core/constants/api_constants.dart';
// import 'package:cohv/core/storage/session_manager.dart';
//
// import '../domain/dashboard_models.dart';
//
// class DashboardApiService {
//   // =========================================================================
//   // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
//   // =========================================================================
//   static const String baseUrl = ApiConstants.baseUrl;
//   static const String endpointDashboardSummary =
//       ApiConstants.endpointDashboardSummary;
//   static const String endpointProfile = ApiConstants.endpointProfile;
//
//   /// Fetch dynamic KPI metrics for the logged-in volunteer
//   Future<DashboardMetrics> getDashboardMetrics(String volunteerId) async {
//     // Simulated network delay
//     await Future.delayed(const Duration(milliseconds: 600));
//
//     // Default seed metrics (matching prototype initial state)
//     return DashboardMetrics(
//       totalVisits: 0,
//       alertsGenerated: 0,
//       referrals: 0,
//       pendingFollowUps: 0,
//       awarenessActivities: 0,
//       trainingsImparted: 0,
//       trainingsAttended: 0,
//       pendingSyncCount: 0,
//     );
//   }
//
//   /// Fetch volunteer profile and demographic anchor
//   // Future<VolunteerProfile> getVolunteerProfile(String volunteerId) async {
//   //   final cached = await SessionManager.getUserSession();
//   //   if (cached != null) {
//   //     return VolunteerProfile(
//   //       fullName: cached.fullName,
//   //       volunteerId: cached.volunteerId.isNotEmpty ? cached.volunteerId : volunteerId,
//   //       status: cached.status.toUpperCase() == 'ACTIVE' ? 'Active' : cached.status,
//   //       locationBreadcrumb: cached.locationBreadcrumb.isNotEmpty
//   //           ? cached.locationBreadcrumb
//   //           : 'Amrabad · Amrabad · Nagarkurnool',
//   //       photoUrl: cached.photoPath,
//   //     );
//   //   }
//   //
//   //   await Future.delayed(const Duration(milliseconds: 300));
//   //
//   //   return VolunteerProfile(
//   //     fullName: 'Rajan',
//   //     volunteerId: volunteerId.isNotEmpty ? volunteerId : 'COHV-26-0005',
//   //     status: 'Active',
//   //     locationBreadcrumb: 'Amrabad · Amrabad · Nagarkurnool',
//   //   );
//   // }
//
//   Future<VolunteerProfile> getVolunteerProfile(String volunteerId) async {
//     try {
//       final freshSession = await AuthApiService().getCurrentUser();
//       return VolunteerProfile(
//         fullName: freshSession.fullName,
//         volunteerId: freshSession.volunteerId.isNotEmpty
//             ? freshSession.volunteerId
//             : volunteerId,
//         status: freshSession.status.toUpperCase() == 'ACTIVE'
//             ? 'Active'
//             : freshSession.status,
//         locationBreadcrumb: freshSession.locationBreadcrumb.isNotEmpty
//             ? freshSession.locationBreadcrumb
//             : 'Amrabad · Amrabad · Nagarkurnool',
//         photoUrl: freshSession.photoPath,
//       );
//     } catch (_) {}
//
//     final cached = await SessionManager.getUserSession();
//     if (cached != null) {
//       return VolunteerProfile(
//         fullName: cached.fullName,
//         volunteerId: cached.volunteerId.isNotEmpty
//             ? cached.volunteerId
//             : volunteerId,
//         status: cached.status.toUpperCase() == 'ACTIVE'
//             ? 'Active'
//             : cached.status,
//         locationBreadcrumb: cached.locationBreadcrumb.isNotEmpty
//             ? cached.locationBreadcrumb
//             : 'Amrabad · Amrabad · Nagarkurnool',
//         photoUrl: cached.photoPath,
//       );
//     }
//
//     return VolunteerProfile(
//       fullName: 'Rajan',
//       volunteerId: volunteerId.isNotEmpty ? volunteerId : 'COHV-26-0005',
//       status: 'Active',
//       locationBreadcrumb: 'Amrabad · Amrabad · Nagarkurnool',
//     );
//   }
// }

import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';

import '../domain/dashboard_models.dart';

class DashboardApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointDashboardSummary =
      ApiConstants.endpointDashboardSummary;
  static const String endpointProfile = ApiConstants.endpointProfile;

  final AuthApiService _authApiService = AuthApiService();

  /// Fetch dynamic KPI metrics for the logged-in volunteer
  Future<DashboardMetrics> getDashboardMetrics(String volunteerId) async {
    await Future.delayed(const Duration(milliseconds: 300));

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

  /// Fetch volunteer profile dynamically from GET /api/auth/me or local SessionManager
  Future<VolunteerProfile> getVolunteerProfile(String volunteerId) async {
    try {
      final freshSession = await _authApiService.getCurrentUser();
      return VolunteerProfile(
        fullName: freshSession.fullName,
        volunteerId: freshSession.volunteerId.isNotEmpty
            ? freshSession.volunteerId
            : volunteerId,
        status: freshSession.status.toUpperCase() == 'ACTIVE'
            ? 'Active'
            : freshSession.status,
        locationBreadcrumb: freshSession.locationBreadcrumb,
        photoUrl: freshSession.photoPath,
      );
    } catch (_) {}

    final cached = await SessionManager.getUserSession();
    if (cached != null) {
      return VolunteerProfile(
        fullName: cached.fullName,
        volunteerId: cached.volunteerId.isNotEmpty
            ? cached.volunteerId
            : volunteerId,
        status: cached.status.toUpperCase() == 'ACTIVE'
            ? 'Active'
            : cached.status,
        locationBreadcrumb: cached.locationBreadcrumb,
        photoUrl: cached.photoPath,
      );
    }

    return VolunteerProfile(
      fullName: '',
      volunteerId: volunteerId,
      status: 'Active',
      locationBreadcrumb: '',
    );
  }
}
