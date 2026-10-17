import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Volunteer Registration Tests', () {
    test('VolunteerRegistrationRequest toJson matches OpenAPI spec', () {
      final request = VolunteerRegistrationRequest(
        volunteerName: 'Madhav',
        gender: 'Male',
        dateOfBirth: DateTime(1999, 10, 16),
        mobileNo: '6201139795',
        email: 'madhav@gmail.com',
        cohvType: 'Animal',
        stateLgdCode: 1,
        districtLgdCode: 1,
        blockLgdCode: 5208,
        gramPanchayatLgdCode: 9000001,
        villageLgdCode: 90000001,
        dateOfJoining: DateTime(2026, 10, 16),
        educationId: 1,
        professionId: 1,
        pin: '1234',
        supervisorId: 2,
        latitude: 28.609306,
        longitude: 77.367452,
        gpsAccuracyM: 153,
        deviceId: 'DEV-C0YBZ9WK',
      );

      final json = request.toJson();
      expect(json['volunteer_name'], 'Madhav');
      expect(json['gender'], 'Male');
      expect(json['date_of_birth'], '1999-10-16');
      expect(json['mobile_no'], '6201139795');
      expect(json['email'], 'madhav@gmail.com');
      expect(json['cohv_type'], 'Animal');
      expect(json['state_lgd_code'], 1);
      expect(json['district_lgd_code'], 1);
      expect(json['block_lgd_code'], 5208);
      expect(json['gram_panchayat_lgd_code'], 9000001);
      expect(json['village_lgd_code'], 90000001);
      expect(json['date_of_joining'], '2026-10-16');
      expect(json['education_id'], 1);
      expect(json['profession_id'], 1);
      expect(json['supervisor_id'], 2);
      expect(json['pin'], '1234');
      expect(json['latitude'], 28.609306);
      expect(json['longitude'], 77.367452);
      expect(json['gps_accuracy_m'], 153);
      expect(json['device_id'], 'DEV-C0YBZ9WK');
    });

    test('RegistrationResult parses backend 201 response correctly', () {
      final json = {
        'message': 'Registration submitted. Awaiting supervisor approval.',
        'volunteer_id': 26,
        'volunteer_code': 'COHV-26-0004',
        'status': 'PENDING',
        'photo_path': 'volunteers/COHV-26-0004.png'
      };

      final result = RegistrationResult.fromJson(json, fullName: 'Madhav');
      expect(result.numericVolunteerId, 26);
      expect(result.volunteerCode, 'COHV-26-0004');
      expect(result.volunteerId, 'COHV-26-0004');
      expect(result.status, 'PENDING');
      expect(result.accountStatus, 'Inactive');
      expect(result.fullName, 'Madhav');
      expect(result.photoPath, 'volunteers/COHV-26-0004.png');
    });

    test('AuthApiService registers volunteer successfully with MockClient', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/volunteers/register'));

        return http.Response(
          '''{
            "message": "Registration submitted. Awaiting supervisor approval.",
            "volunteer_id": 26,
            "volunteer_code": "COHV-26-0004",
            "status": "PENDING",
            "photo_path": "volunteers/COHV-26-0004.png"
          }''',
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      final req = VolunteerRegistrationRequest(
        volunteerName: 'Madhav',
        gender: 'Male',
        dateOfBirth: DateTime(1999, 10, 16),
        mobileNo: '6201139795',
        email: 'madhav@gmail.com',
        cohvType: 'Animal',
        stateLgdCode: 1,
        districtLgdCode: 1,
        blockLgdCode: 5208,
        gramPanchayatLgdCode: 9000001,
        villageLgdCode: 90000001,
        dateOfJoining: DateTime(2026, 10, 16),
        educationId: 1,
        professionId: 1,
        pin: '1234',
        supervisorId: 2,
      );

      final result = await service.registerVolunteer(req, client: mockClient);
      expect(result.volunteerCode, 'COHV-26-0004');
      expect(result.numericVolunteerId, 26);
      expect(result.status, 'PENDING');
    });

    test('AuthApiService handles 409 duplicate mobile error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "This mobile number is already registered."}',
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      final req = VolunteerRegistrationRequest(
        volunteerName: 'Madhav',
        gender: 'Male',
        dateOfBirth: DateTime(1999, 10, 16),
        mobileNo: '6201139795',
        email: 'madhav@gmail.com',
        cohvType: 'Animal',
        stateLgdCode: 1,
        districtLgdCode: 1,
        blockLgdCode: 5208,
        gramPanchayatLgdCode: 9000001,
        villageLgdCode: 90000001,
        dateOfJoining: DateTime(2026, 10, 16),
        educationId: 1,
        professionId: 1,
        pin: '1234',
      );

      expect(
        () => service.registerVolunteer(req, client: mockClient),
        throwsA(predicate((e) => e.toString().contains('This mobile number is already registered.'))),
      );
    });

    test('AuthApiService handles 422 validation error message parsing', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": [{"loc": ["body", "mobile_no"], "msg": "Field required", "type": "missing"}]}',
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      final req = VolunteerRegistrationRequest(
        volunteerName: 'Madhav',
        gender: 'Male',
        dateOfBirth: DateTime(1999, 10, 16),
        mobileNo: '',
        email: 'madhav@gmail.com',
        cohvType: 'Animal',
        stateLgdCode: 1,
        districtLgdCode: 1,
        blockLgdCode: 5208,
        gramPanchayatLgdCode: 9000001,
        villageLgdCode: 90000001,
        dateOfJoining: DateTime(2026, 10, 16),
        educationId: 1,
        professionId: 1,
        pin: '1234',
      );

      expect(
        () => service.registerVolunteer(req, client: mockClient),
        throwsA(predicate((e) => e.toString().contains('mobile_no: Field required'))),
      );
    });

    test('SignInWithPinRequest toJson maps to login and pin with optional device_id', () {
      final req1 = SignInWithPinRequest(
        identifier: 'COHV-26-0001',
        pin: '1234',
        deviceId: 'DEV-C0YBZ9WK',
      );
      expect(req1.toJson(), {
        'login': 'COHV-26-0001',
        'pin': '1234',
        'device_id': 'DEV-C0YBZ9WK',
      });

      final req2 = SignInWithPinRequest(
        identifier: '9876543210',
        pin: '5678',
      );
      expect(req2.toJson(), {
        'login': '9876543210',
        'pin': '5678',
      });
    });

    test('AuthApiService.loginWithPin handles 200 OK and parses UserSession', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/auth/login'));

        return http.Response(
          '''{
            "access_token": "mock_jwt_access_token_xyz",
            "token_type": "bearer",
            "expires_in": 86400,
            "volunteer": {
              "volunteer_id": 26,
              "volunteer_code": "COHV-26-0004",
              "volunteer_name": "Madhav Test",
              "mobile_no": "9999900002",
              "email": "madhav@example.com",
              "cohv_type": "Public Health",
              "status": "ACTIVE",
              "photo_path": "volunteers/COHV-26-0004.png",
              "state_lgd_code": 36,
              "state_name": "Telangana",
              "district_lgd_code": 694,
              "district_name": "Nagarkurnool",
              "block_lgd_code": 5208,
              "block_name": "Amrabad",
              "gram_panchayat_lgd_code": 9000001,
              "gram_panchayat_name": "Mannanur",
              "village_lgd_code": 90000001,
              "village_name": "Mannanur",
              "supervisor_id": 1,
              "supervisor_name": "Dr. Ravi Kumar"
            }
          }''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      final session = await service.loginWithPin(
        SignInWithPinRequest(identifier: 'COHV-26-0004', pin: '1234'),
        client: mockClient,
      );

      expect(session.volunteerId, 'COHV-26-0004');
      expect(session.numericVolunteerId, 26);
      expect(session.fullName, 'Madhav Test');
      expect(session.token, 'mock_jwt_access_token_xyz');
      expect(session.status, 'ACTIVE');
      expect(session.mobile, '9999900002');
      expect(session.sector, 'Public Health');
      expect(session.supervisorName, 'Dr. Ravi Kumar');
    });

    test('AuthApiService.loginWithPin handles 403 awaiting approval error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "Your registration is awaiting approval by your supervisor."}',
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      expect(
        () => service.loginWithPin(
          SignInWithPinRequest(identifier: '9999900001', pin: '1234'),
          client: mockClient,
        ),
        throwsA(predicate((e) => e.toString().contains('Your registration is awaiting approval by your supervisor.'))),
      );
    });

    test('AuthApiService.loginWithPin handles 401 invalid credentials error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"detail": "Invalid volunteer credentials or PIN."}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AuthApiService();
      expect(
        () => service.loginWithPin(
          SignInWithPinRequest(identifier: 'COHV-26-9999', pin: '0000'),
          client: mockClient,
        ),
        throwsA(predicate((e) => e.toString().contains('Invalid volunteer credentials or PIN.'))),
      );
    });
  });
}
