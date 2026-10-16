import 'package:cohv/core/constants/api_constants.dart';
import '../domain/profile_models.dart';

class ProfileApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointProfileDetails = ApiConstants.endpointProfileDetails;
  static const String endpointLoginHistory = ApiConstants.endpointLoginHistory;
  static const String endpointUpdateProfile = ApiConstants.endpointUpdateProfile;

  /// Fetch full detailed volunteer profile
  Future<DetailedVolunteerProfile> getDetailedProfile(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointProfileDetails?volunteer_id=$volunteerId'),
    //   headers: {'Authorization': 'Bearer $token'},
    // );
    // if (response.statusCode == 200) {
    //   return DetailedVolunteerProfile.fromJson(jsonDecode(response.body));
    // } else {
    //   throw Exception('Failed to load profile details.');
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 500));

    // Simulated initial data matching prototype screenshot
    return DetailedVolunteerProfile(
      fullName: 'Test1',
      volunteerId: volunteerId.isNotEmpty ? volunteerId : 'COHV-26-0001',
      designation: 'COHV',
      gender: 'Male',
      dob: '10 Jul 1997',
      mobileNumber: '9565897524',
      email: 'test1@gmail.com',
      village: 'Mannanur',
      panchayat: 'Mannanur',
      block: 'Amrabad',
      division: 'Mahabubnagar Division',
      district: 'Nagarkurnool',
      state: 'Telangana',
      dateOfJoining: '11 Oct 2026',
      qualification: 'Higher Secondary',
      profession: 'Farmer',
      supervisor: 'Assigned on approval',
      healthFacilityLinked: 'CHC',
      veterinaryInstitutionLinked: '—',
      forestInstitutionLinked: '—',
      preferredLanguage: 'English',
      status: 'Active',
      lastLogin: '14 Oct 2026, 10:23',
      registrationGps: '28.609306, 77.367452',
    );
  }

  /// Fetch Section 2 shared handset login history
  Future<List<LoginHistoryEntry>> getLoginHistory(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointLoginHistory?volunteer_id=$volunteerId'),
    // );
    // if (response.statusCode == 200) {
    //   final List data = jsonDecode(response.body);
    //   return data.map((e) => LoginHistoryEntry.fromJson(e)).toList();
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 300));

    // Simulated login entries matching screenshot
    return [
      LoginHistoryEntry(
        timestamp: '14 Oct 2026, 10:23',
        authMethod: 'PIN',
        deviceId: 'DEV-C0YBZ9WK',
      ),
      LoginHistoryEntry(
        timestamp: '13 Oct 2026, 16:09',
        authMethod: 'PIN',
        deviceId: 'DEV-C0YBZ9WK',
      ),
    ];
  }
}
