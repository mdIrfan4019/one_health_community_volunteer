import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/profile/data/profile_api_service.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 1: Volunteer Profile Offline Access Tests', () {
    test('UserSession serializes and deserializes demographic fields properly', () {
      final sessionMap = {
        'volunteer_id': 101,
        'volunteer_code': 'COHV-26-0101',
        'volunteer_name': 'Ayesha Khan',
        'mobile_no': '9876543210',
        'department_name': 'Animal Husbandry Department',
        'status': 'ACTIVE',
        'access_token': 'mock_token',
        'gender': 'Female',
        'date_of_birth': '1998-05-15',
        'qualification': 'Bachelor of Veterinary Science',
        'profession': 'Veterinarian',
        'state_name': 'Telangana',
        'district_name': 'Nagarkurnool',
        'block_name': 'Amrabad',
        'gram_panchayat_name': 'Amrabad',
        'village_name': 'Amrabad',
        'supervisor_name': 'Dr. Sharma',
        'supervisor_id': 5,
      };

      final session = UserSession.fromJson(sessionMap);
      expect(session.fullName, 'Ayesha Khan');
      expect(session.gender, 'Female');
      expect(session.dob, '1998-05-15');
      expect(session.qualification, 'Bachelor of Veterinary Science');
      expect(session.profession, 'Veterinarian');

      final jsonOut = session.toJson();
      expect(jsonOut['gender'], 'Female');
      expect(jsonOut['dob'], '1998-05-15');
      expect(jsonOut['qualification'], 'Bachelor of Veterinary Science');
      expect(jsonOut['profession'], 'Veterinarian');
    });

    test('DetailedVolunteerProfile.fromUserSession maps real demographics when offline', () {
      final session = UserSession(
        volunteerId: 'COHV-26-0101',
        numericVolunteerId: 101,
        fullName: 'Ayesha Khan',
        mobile: '9876543210',
        sector: 'Animal Husbandry',
        status: 'ACTIVE',
        token: 'mock_token',
        gender: 'Female',
        dob: '1998-05-15',
        qualification: 'B.V.Sc',
        profession: 'Veterinary Officer',
        stateName: 'Telangana',
        districtName: 'Nagarkurnool',
        blockName: 'Amrabad',
        gramPanchayatName: 'Amrabad',
        villageName: 'Amrabad',
        supervisorName: 'Dr. Sharma',
        supervisorId: 5,
      );

      final profile = DetailedVolunteerProfile.fromUserSession(session);

      expect(profile.fullName, 'Ayesha Khan');
      expect(profile.volunteerId, 'COHV-26-0101');
      expect(profile.gender, 'Female');
      expect(profile.dob, '15 May 1998');
      expect(profile.qualification, 'B.V.Sc');
      expect(profile.profession, 'Veterinary Officer');
      expect(profile.district, 'Nagarkurnool');
      expect(profile.state, 'Telangana');
      expect(profile.supervisor, 'Dr. Sharma (ID: 5)');
    });

    test('ProfileApiService.getDetailedProfile returns cached profile when network fails', () async {
      final cachedProfile = DetailedVolunteerProfile(
        fullName: 'Ramesh Patel',
        volunteerId: 'COHV-26-0099',
        designation: 'COHV Volunteer',
        gender: 'Male',
        dob: '20 Oct 1995',
        mobileNumber: '9123456789',
        email: 'ramesh@example.com',
        village: 'Amrabad',
        panchayat: 'Amrabad',
        block: 'Amrabad',
        division: 'Nagarkurnool Division',
        district: 'Nagarkurnool',
        state: 'Telangana',
        dateOfJoining: '01 Jan 2026',
        qualification: 'Graduate',
        profession: 'Community Health Worker',
        supervisor: 'Dr. Rao',
        lastLogin: 'Active session verified',
        registrationGps: '16.5, 78.5',
      );

      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_token',
        'volunteer_id': 'COHV-26-0099',
        'detailed_volunteer_profile': cachedProfile.toJson(),
      });

      // Saving it explicitly to SessionManager
      await SessionManager.saveDetailedProfile(cachedProfile);

      final service = ProfileApiService();
      // Calling getDetailedProfile with an invalid host or in offline test environment
      final result = await service.getDetailedProfile('COHV-26-0099');

      expect(result.fullName, 'Ramesh Patel');
      expect(result.volunteerId, 'COHV-26-0099');
      expect(result.gender, 'Male');
      expect(result.qualification, 'Graduate');
      expect(result.profession, 'Community Health Worker');
    });

    test('ProfileApiService.getDetailedProfile falls back to UserSession when detailed profile is null', () async {
      final session = UserSession(
        volunteerId: 'COHV-26-0088',
        numericVolunteerId: 88,
        fullName: 'Sunita Verma',
        mobile: '9888877777',
        sector: 'Public Health',
        status: 'ACTIVE',
        token: 'mock_token',
        gender: 'Female',
        dob: '1992-12-01',
        qualification: 'Post Graduate',
        profession: 'ANM',
        stateName: 'Telangana',
        districtName: 'Nagarkurnool',
        blockName: 'Amrabad',
        gramPanchayatName: 'Amrabad',
        villageName: 'Amrabad',
      );

      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_token',
        'volunteer_id': 'COHV-26-0088',
      });
      await SessionManager.saveSession(session);

      final service = ProfileApiService();
      final result = await service.getDetailedProfile('COHV-26-0088');

      expect(result.fullName, 'Sunita Verma');
      expect(result.volunteerId, 'COHV-26-0088');
      expect(result.gender, 'Female');
      expect(result.dob, '1 Dec 1992');
      expect(result.qualification, 'Post Graduate');
      expect(result.profession, 'ANM');
    });
  });
}
