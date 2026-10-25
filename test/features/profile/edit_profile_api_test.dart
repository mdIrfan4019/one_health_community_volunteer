import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/features/profile/data/profile_api_service.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';
import 'package:cohv/features/profile/presentation/screen/edit_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test-jwt-token',
      'user_session_json': jsonEncode({
        'user_id': '52',
        'volunteer_id': 'COHV-26-0052',
        'numeric_volunteer_id': 52,
        'full_name': 'Piyush Sharma',
        'mobile': '9876543210',
        'email': 'piyush@example.com',
        'sector': 'Public Health Department',
        'token': 'test-jwt-token',
        'state_lgd_code': 10,
        'district_lgd_code': 101,
        'block_lgd_code': 1001,
        'gram_panchayat_lgd_code': 10001,
        'village_lgd_code': 100001,
      }),
    });
  });

  DetailedVolunteerProfile createTestProfile({
    int? institutionTypeId = 6,
    String? institutionName = 'CHC',
    String? otherInstitutionName,
    String? rawDateOfBirth = '1997-07-10',
    String dob = '10 Jul 1997',
  }) {
    return DetailedVolunteerProfile(
      fullName: 'Piyush Sharma',
      volunteerId: 'COHV-26-0052',
      numericVolunteerId: 52,
      designation: 'Public Health Department',
      gender: 'Male',
      dob: dob,
      rawDateOfBirth: rawDateOfBirth,
      mobileNumber: '9876543210',
      email: 'piyush@example.com',
      village: 'Amrabad Village',
      panchayat: 'Amrabad GP',
      block: 'Amrabad',
      division: 'Nagarkurnool Division',
      district: 'Nagarkurnool',
      state: 'Telangana',
      dateOfJoining: '01 Jan 2026',
      qualification: 'Graduate',
      profession: 'Community Health Worker',
      supervisor: 'Dr. Ravi Kumar',
      departmentId: 1,
      departmentName: 'Public Health Department',
      cohvType: 'Public Health Department',
      institutionTypeId: institutionTypeId,
      institutionTypeName: institutionName,
      institutionFieldLabel: 'Health facility',
      institutionName: institutionName,
      otherInstitutionName: otherInstitutionName,
      educationId: 3,
      professionId: 2,
      stateLgdCode: 10,
      districtLgdCode: 101,
      blockLgdCode: 1001,
      gramPanchayatLgdCode: 10001,
      villageLgdCode: 100001,
      lastLogin: 'Active session verified',
      registrationGps: '16.5000° N, 78.5000° E',
    );
  }

  group('DetailedVolunteerProfile date formatting and update JSON tests', () {
    test('formattedIsoDateOfBirth correctly resolves ISO YYYY-MM-DD from various formats', () {
      final p1 = createTestProfile(rawDateOfBirth: '1997-07-10', dob: '10 Jul 1997');
      expect(p1.formattedIsoDateOfBirth, '1997-07-10');

      final p2 = createTestProfile(rawDateOfBirth: null, dob: '15 Aug 1995');
      expect(p2.formattedIsoDateOfBirth, '1995-08-15');

      final p3 = createTestProfile(rawDateOfBirth: null, dob: '1990-12-25');
      expect(p3.formattedIsoDateOfBirth, '1990-12-25');
    });

    test('toUpdateJson produces exact Swagger schema fields', () {
      final profile = createTestProfile(
        institutionTypeId: 6,
        institutionName: 'CHC',
        otherInstitutionName: null,
      );

      final jsonMap = profile.toUpdateJson(photoPayload: 'data-or-url');

      expect(jsonMap['volunteer_name'], 'Piyush Sharma');
      expect(jsonMap['gender'], 'Male');
      expect(jsonMap['date_of_birth'], '1997-07-10');
      expect(jsonMap['mobile_no'], '9876543210');
      expect(jsonMap['email'], 'piyush@example.com');
      expect(jsonMap['institution_type_id'], 6);
      expect(jsonMap['institution_name'], 'CHC');
      expect(jsonMap['other_institution_name'], isNull);
      expect(jsonMap['education_id'], 3);
      expect(jsonMap['profession_id'], 2);
      expect(jsonMap['state_lgd_code'], 10);
      expect(jsonMap['district_lgd_code'], 101);
      expect(jsonMap['block_lgd_code'], 1001);
      expect(jsonMap['gram_panchayat_lgd_code'], 10001);
      expect(jsonMap['village_lgd_code'], 100001);
      expect(jsonMap['photo'], 'data-or-url');
    });
  });

  group('ProfileApiService.updateProfile PUT API binding tests', () {
    test('PUT /api/volunteers/{volunteer_id} is called with correct path parameter and payload for CHC', () async {
      final profile = createTestProfile(
        institutionTypeId: 6,
        institutionName: 'CHC',
        otherInstitutionName: null,
      );

      http.BaseRequest? capturedRequest;
      Map<String, String>? capturedFields;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        if (request.method == 'PUT' && request.url.path.contains('/api/volunteers/52')) {
          capturedRequest = request;
          if (request is http.MultipartRequest) {
            capturedFields = request.fields;
          }
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'success': true,
              'message': 'Volunteer profile updated successfully',
              'data': {
                'volunteer_id': 52,
                'volunteer_code': 'COHV-26-0052',
                'volunteer_name': 'Piyush Sharma',
                'gender': 'Male',
                'date_of_birth': '1997-07-10',
                'mobile_no': '9876543210',
                'email': 'piyush@example.com',
                'institution_type_id': 6,
                'institution_name': 'CHC',
                'education_id': 3,
                'profession_id': 2,
                'state_lgd_code': 10,
                'district_lgd_code': 101,
                'block_lgd_code': 1001,
                'gram_panchayat_lgd_code': 10001,
                'village_lgd_code': 100001,
              },
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.StreamedResponse(Stream.value(utf8.encode('Not Found')), 404);
      });

      final service = ProfileApiService();
      final success = await service.updateProfile(profile, client: mockClient);

      expect(success, isTrue);
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.toString(), '${ApiConstants.baseUrl}/volunteers/52');
      expect(capturedRequest!.headers['authorization'], 'Bearer test-jwt-token');

      // Verify multipart form fields
      expect(capturedFields!['volunteer_name'], 'Piyush Sharma');
      expect(capturedFields!['gender'], 'Male');
      expect(capturedFields!['date_of_birth'], '1997-07-10');
      expect(capturedFields!['mobile_no'], '9876543210');
      expect(capturedFields!['email'], 'piyush@example.com');
      expect(capturedFields!['institution_type_id'], '6');
      expect(capturedFields!['institution_name'], 'CHC');
      expect(capturedFields!['other_institution_name'], isNull);
      expect(capturedFields!['education_id'], '3');
      expect(capturedFields!['profession_id'], '2');
      expect(capturedFields!['state_lgd_code'], '10');
      expect(capturedFields!['district_lgd_code'], '101');
      expect(capturedFields!['block_lgd_code'], '1001');
      expect(capturedFields!['gram_panchayat_lgd_code'], '10001');
      expect(capturedFields!['village_lgd_code'], '100001');
    });

    test('PUT /api/volunteers/{volunteer_id} maps Other institution with custom name', () async {
      final profile = createTestProfile(
        institutionTypeId: 1,
        institutionName: 'Other',
        otherInstitutionName: 'Community Hospital Amrabad',
      );

      Map<String, String>? capturedFields;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        if (request.method == 'PUT' && request.url.path.contains('/api/volunteers/52')) {
          if (request is http.MultipartRequest) {
            capturedFields = request.fields;
          }
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'success': true,
              'message': 'Volunteer profile updated successfully',
              'data': {
                'volunteer_id': 52,
                'volunteer_name': 'Piyush Sharma',
                'institution_type_id': 1,
                'institution_name': 'Other',
                'other_institution_name': 'Community Hospital Amrabad',
              },
            }))),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.StreamedResponse(Stream.value(utf8.encode('Not Found')), 404);
      });

      final service = ProfileApiService();
      final success = await service.updateProfile(profile, client: mockClient);

      expect(success, isTrue);
      expect(capturedFields, isNotNull);
      expect(capturedFields!['institution_type_id'], '1');
      expect(capturedFields!['institution_name'], 'Other');
      expect(capturedFields!['other_institution_name'], 'Community Hospital Amrabad');
    });

    test('updateProfile attaches photoFile as multipart UploadFile', () async {
      final tempDir = await Directory.systemTemp.createTemp('profile_test_');
      final testPhoto = File('${tempDir.path}/test_avatar.jpg');
      await testPhoto.writeAsBytes(utf8.encode('fake-image-bytes-12345'));

      final profile = createTestProfile();
      List<http.MultipartFile>? capturedFiles;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        if (request.method == 'PUT') {
          if (request is http.MultipartRequest) {
            capturedFiles = request.files;
          }
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({'success': true, 'message': 'Updated'}))),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.StreamedResponse(Stream.value(utf8.encode('Error')), 400);
      });

      final service = ProfileApiService();
      final success = await service.updateProfile(
        profile,
        photoFile: testPhoto,
        client: mockClient,
      );

      expect(success, isTrue);
      expect(capturedFiles, isNotNull);
      expect(capturedFiles!.length, 1);
      expect(capturedFiles!.first.field, 'photo');
      expect(capturedFiles!.first.filename, 'test_avatar.jpg');

      await tempDir.delete(recursive: true);
    });

    test('updateProfile throws server error message when backend returns 422 Unprocessable Entity', () async {
      final profile = createTestProfile();

      final mockClient = MockClient.streaming((request, bodyStream) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'detail': 'Invalid mobile number format',
          }))),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ProfileApiService();
      expect(
        () => service.updateProfile(profile, client: mockClient),
        throwsA(predicate((e) => e.toString().contains('Invalid mobile number format'))),
      );
    });
  });

  group('EditProfileScreen Widget Tests', () {
    testWidgets('EditProfileScreen renders correctly and shows dynamic institution field', (tester) async {
      final profile = createTestProfile(
        institutionTypeId: 6,
        institutionName: 'CHC',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(profile: profile),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Personal Details Card
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Gender *'), findsOneWidget);
      expect(find.text('Date of Birth (DOB) *'), findsOneWidget);
      expect(find.text('Mobile Number *'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Verify Assigned Administrative Postings Card is locked
      expect(find.text('Assigned Administrative Postings (Locked)'), findsOneWidget);
      expect(find.text('Nagarkurnool'), findsOneWidget);
      expect(find.text('Telangana'), findsOneWidget);
    });
  });
}
