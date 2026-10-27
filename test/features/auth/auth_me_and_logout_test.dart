import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> sampleMeApiResponse = {
    "volunteer_id": 27,
    "volunteer_code": "COHV-26-0005",
    "volunteer_name": "Rajan",
    "mobile_no": "9568452369",
    "email": "rajan123@gmail.com",
    "cohv_type": "Public Health",
    "status": "ACTIVE",
    "photo_path": "volunteers/COHV-26-0005.jpg",
    "state_lgd_code": 36,
    "state_name": "Telangana",
    "district_lgd_code": 694,
    "district_name": "Nagarkurnool",
    "block_lgd_code": 5208,
    "block_name": "Amrabad",
    "gram_panchayat_lgd_code": 9000002,
    "gram_panchayat_name": "Amrabad",
    "village_lgd_code": 90000004,
    "village_name": "Amrabad",
    "supervisor_id": 1,
    "supervisor_name": "Dr. Ravi Kumar"
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserSession & Profile Serialization Tests', () {
    test('Correctly parses /api/auth/me response JSON into UserSession', () {
      final session = UserSession.fromJson(
        sampleMeApiResponse,
        token: 'test_access_token_123',
      );

      expect(session.volunteerId, equals('COHV-26-0005'));
      expect(session.numericVolunteerId, equals(27));
      expect(session.fullName, equals('Rajan'));
      expect(session.mobile, equals('9568452369'));
      expect(session.email, equals('rajan123@gmail.com'));
      expect(session.sector, equals('Public Health'));
      expect(session.status, equals('ACTIVE'));
      expect(session.photoPath, equals('volunteers/COHV-26-0005.jpg'));
      expect(session.stateName, equals('Telangana'));
      expect(session.districtName, equals('Nagarkurnool'));
      expect(session.blockName, equals('Amrabad'));
      expect(session.gramPanchayatName, equals('Amrabad'));
      expect(session.villageName, equals('Amrabad'));
      expect(session.supervisorName, equals('Dr. Ravi Kumar'));
      expect(session.supervisorId, equals(1));
      expect(session.token, equals('test_access_token_123'));
      expect(session.locationBreadcrumb, equals('Amrabad · Amrabad · Nagarkurnool'));
    });

    test('Correctly parses Animal Husbandry /api/auth/me response with department_name and department_id', () {
      final animalHusbandryMe = {
        "volunteer_id": 37,
        "volunteer_code": "COHV-26-0007",
        "volunteer_name": "Mayank",
        "mobile_no": "9523695832",
        "email": "mayank123@gmail.com",
        "department_id": 2,
        "department_name": "Animal Husbandry Department",
        "cohv_type": "Animal Husbandry Department",
        "status": "ACTIVE",
      };

      final session = UserSession.fromJson(animalHusbandryMe, token: 'animal_token');
      expect(session.volunteerId, equals('COHV-26-0007'));
      expect(session.numericVolunteerId, equals(37));
      expect(session.departmentId, equals(2));
      expect(session.departmentName, equals('Animal Husbandry Department'));
      expect(session.sector, equals('Animal Husbandry Department'));
    });

    test('Correctly parses Animal Husbandry /api/auth/login response wrapped in volunteer map', () {
      final loginResponse = {
        "access_token": "mock_jwt_token",
        "token_type": "bearer",
        "volunteer": {
          "volunteer_id": 37,
          "volunteer_code": "COHV-26-0007",
          "volunteer_name": "Mayank",
          "department_id": 2,
          "department_name": "Animal Husbandry Department",
          "cohv_type": "Animal Husbandry Department",
          "status": "ACTIVE",
        }
      };

      final session = UserSession.fromJson(loginResponse);
      expect(session.volunteerId, equals('COHV-26-0007'));
      expect(session.departmentId, equals(2));
      expect(session.departmentName, equals('Animal Husbandry Department'));
      expect(session.sector, equals('Animal Husbandry Department'));
    });

    test('Correctly converts UserSession into DetailedVolunteerProfile', () {
      final session = UserSession.fromJson(
        sampleMeApiResponse,
        token: 'test_access_token_123',
      );

      final profile = DetailedVolunteerProfile.fromUserSession(session);

      expect(profile.volunteerId, equals('COHV-26-0005'));
      expect(profile.fullName, equals('Rajan'));
      expect(profile.mobileNumber, equals('9568452369'));
      expect(profile.email, equals('rajan123@gmail.com'));
      expect(profile.designation, equals('Public Health'));
      expect(profile.status, equals('ACTIVE'));
      expect(profile.supervisor, contains('Dr. Ravi Kumar'));
      expect(profile.supervisor, contains('ID: 1'));
      expect(profile.state, equals('Telangana'));
      expect(profile.district, equals('Nagarkurnool'));
      expect(profile.block, equals('Amrabad'));
      expect(profile.panchayat, equals('Amrabad'));
      expect(profile.village, equals('Amrabad'));
      expect(profile.photoUrl, equals('volunteers/COHV-26-0005.jpg'));
    });

    test('DetailedVolunteerProfile.fromMeJson directly parses API map', () {
      final profile = DetailedVolunteerProfile.fromMeJson(sampleMeApiResponse);

      expect(profile.volunteerId, equals('COHV-26-0005'));
      expect(profile.fullName, equals('Rajan'));
      expect(profile.supervisor, equals('Dr. Ravi Kumar (ID: 1)'));
    });
  });

  group('SessionManager Local Storage Tests', () {
    test('saveSession and getUserSession roundtrip successfully', () async {
      final session = UserSession.fromJson(
        sampleMeApiResponse,
        token: 'mock_bearer_token',
      );

      await SessionManager.saveSession(session);

      final token = await SessionManager.getToken();
      expect(token, equals('mock_bearer_token'));

      final cachedSession = await SessionManager.getUserSession();
      expect(cachedSession, isNotNull);
      expect(cachedSession!.volunteerId, equals('COHV-26-0005'));
      expect(cachedSession.fullName, equals('Rajan'));
      expect(cachedSession.token, equals('mock_bearer_token'));

      final isLoggedIn = await SessionManager.isLoggedIn();
      expect(isLoggedIn, isTrue);

      await SessionManager.clearSession();
      final clearedToken = await SessionManager.getToken();
      expect(clearedToken, isNull);
      expect(await SessionManager.isLoggedIn(), isFalse);
    });
  });

  group('AuthApiService - Use Cases & API Bindings', () {
    test('getCurrentUser (GET /api/auth/me) with Status 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, contains('/auth/me'));
        expect(request.headers['Authorization'], equals('Bearer valid_token_123'));
        expect(request.headers['Accept'], equals('application/json'));

        return http.Response(
          jsonEncode(sampleMeApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      final user = await service.getCurrentUser(
        token: 'valid_token_123',
        client: mockClient,
      );

      expect(user.volunteerId, equals('COHV-26-0005'));
      expect(user.fullName, equals('Rajan'));
      expect(user.status, equals('ACTIVE'));
      expect(user.token, equals('valid_token_123'));
    });

    test('getCurrentUser (GET /api/auth/me) with Status 401 Unauthorized clears session and throws AuthException', () async {
      await SessionManager.saveSession(
        UserSession.fromJson(sampleMeApiResponse, token: 'expired_token'),
      );
      expect(await SessionManager.getToken(), equals('expired_token'));

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Token expired or invalid'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();

      await expectLater(
        service.getCurrentUser(
          token: 'expired_token',
          client: mockClient,
        ),
        throwsA(isA<AuthException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );

      // Verify SessionManager cleared local storage
      final tokenAfter = await SessionManager.getToken();
      expect(tokenAfter, isNull);
    });

    test('logout (POST /api/auth/logout) sends Authorization Bearer header and clears storage', () async {
      await SessionManager.saveSession(
        UserSession.fromJson(sampleMeApiResponse, token: 'token_to_logout'),
      );

      bool headerChecked = false;

      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, contains('/auth/logout'));
        expect(request.headers['Authorization'], equals('Bearer token_to_logout'));
        headerChecked = true;
        return http.Response(
          jsonEncode({'message': 'Logged out successfully'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      final success = await service.logout(
        token: 'token_to_logout',
        client: mockClient,
      );

      expect(success, isTrue);
      expect(headerChecked, isTrue);
      expect(await SessionManager.getToken(), isNull);
    });
  });

  group('ApiConstants Helper Tests', () {
    test('resolveImageUrl correctly resolves relative and absolute paths', () {
      expect(ApiConstants.resolveImageUrl(null), isNull);
      expect(ApiConstants.resolveImageUrl(''), isNull);
      expect(
        ApiConstants.resolveImageUrl('https://example.com/photo.jpg'),
        equals('https://example.com/photo.jpg'),
      );
      final resolved = ApiConstants.resolveImageUrl('volunteers/COHV-26-0005.jpg');
      expect(resolved, contains('/volunteers/COHV-26-0005.jpg'));
    });
  });
}
