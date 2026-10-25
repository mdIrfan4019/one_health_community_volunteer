import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import 'package:cohv/features/profile/domain/profile_models.dart';
import 'package:cohv/features/profile/presentation/screen/edit_profile_screen.dart';
import 'package:cohv/features/profile/presentation/screen/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // JSON mimicking staging server GET /api/volunteers/50
  final stagingVolunteerJson = {
    'volunteer_id': 50,
    'volunteer_code': 'COHV-26-0016',
    'volunteer_name': 'Piyush Sharma',
    'gender': 'MALE',
    'date_of_birth': '2001-10-24',
    'mobile_no': '9523683214',
    'email': 'piyush123@gmail.com',
    'department_id': 1,
    'department_name': 'Public Health Department',
    'cohv_type': 'Public Health Department',
    'institution_type_id': 6,
    'institution_type_name': 'CHC',
    'institution_name': 'CHC Amrabad',
    'other_institution_name': null,
    'state_lgd_code': 36,
    'state_name': 'Telangana',
    'district_lgd_code': 694,
    'district_name': 'Nagarkurnool',
    'block_lgd_code': 5208,
    'block_name': 'Amrabad',
    'gram_panchayat_lgd_code': 9000002,
    'gram_panchayat_name': 'Amrabad',
    'village_lgd_code': 90000004,
    'village_name': 'Amrabad',
    'date_of_joining': '2026-10-24',
    'education_id': 3,
    'education_name': 'Diploma',
    'profession_id': 4,
    'profession_name': 'Para-veterinarian',
    'supervisor_id': 1,
    'supervisor_name': 'Dr. Ravi Kumar',
    'supervisor_mobile': '9000000101',
    'supervisor_email': 'ravi.kumar@example.com',
    'photo_path': 'volunteers/COHV-26-0016.jpg',
    'status': 'ACTIVE',
    'reg_latitude': '28.609306',
    'reg_longitude': '77.367452',
    'last_login_at': '2026-10-25T01:24:47.684077+05:30',
    'institution_field_label': 'Health facility',
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock_bearer_token',
      'volunteer_id': 'COHV-26-0016',
      'numeric_volunteer_id': 50,
      'volunteer_name': 'Piyush Sharma',
    });
  });

  group('Profile Details & Edit Profile Dynamic Data Tests', () {
    test('DetailedVolunteerProfile maps profession_name to Designation and education_name to Educational qualification', () {
      final profile = DetailedVolunteerProfile.fromVolunteerProfileJson(stagingVolunteerJson);

      // Verify Designation strictly maps to profession_name
      expect(profile.designation, 'Para-veterinarian');
      expect(profile.profession, 'Para-veterinarian');
      expect(profile.professionId, 4);

      // Verify Educational Qualification strictly maps to education_name
      expect(profile.qualification, 'Diploma');
      expect(profile.educationId, 3);

      // Verify COHV Type
      expect(profile.cohvType, 'Public Health Department');

      // Verify Institution details
      expect(profile.institutionTypeId, 6);
      expect(profile.institutionTypeName, 'CHC');
      expect(profile.institutionName, 'CHC Amrabad');
      expect(profile.institutionFieldLabel, 'Health facility');
      expect(profile.institutionDisplay, 'CHC Amrabad');

      // Verify Date of Birth formatting and age calculation
      expect(profile.dob, '24 Oct 2001');
      expect(profile.ageAndDobDisplay, contains('24 Oct 2001'));
      expect(profile.age, isNotNull);
      expect(profile.age, greaterThan(0));

      // Verify Gender title-cased
      expect(profile.gender, 'Male');

      // Verify GPS format
      expect(profile.registrationGps, '28.609306, 77.367452');
    });

    test('InstitutionModel parses API structure including field_label, option_name and is_other', () {
      final dept1Json = [
        {'institution_type_id': 3, 'department_id': 1, 'field_label': 'Health facility', 'option_name': 'PHC', 'is_other': false, 'sort_order': 1},
        {'institution_type_id': 6, 'department_id': 1, 'field_label': 'Health facility', 'option_name': 'CHC', 'is_other': false, 'sort_order': 2},
        {'institution_type_id': 1, 'department_id': 1, 'field_label': 'Health facility', 'option_name': 'Other', 'is_other': true, 'sort_order': 3},
      ];

      final institutions = dept1Json.map((j) => InstitutionModel.fromJson(j)).toList();

      expect(institutions.length, 3);
      expect(institutions[0].fieldLabel, 'Health facility');
      expect(institutions[0].optionName, 'PHC');
      expect(institutions[0].isOther, isFalse);

      expect(institutions[1].fieldLabel, 'Health facility');
      expect(institutions[1].optionName, 'CHC');
      expect(institutions[1].institutionTypeId, 6);

      expect(institutions[2].isOther, isTrue);
      expect(institutions[2].optionName, 'Other');
    });

    test('Dynamic institution handles custom name when is_other is true', () {
      final customJson = Map<String, dynamic>.from(stagingVolunteerJson);
      customJson['institution_type_id'] = 1;
      customJson['institution_type_name'] = 'Other';
      customJson['other_institution_name'] = 'Custom Trust Clinic';

      final profile = DetailedVolunteerProfile.fromVolunteerProfileJson(customJson);
      expect(profile.institutionDisplay, 'Custom Trust Clinic');
    });

    testWidgets('ProfileScreen renders dynamic details and eliminates hardcoded rows', (tester) async {
      final profile = DetailedVolunteerProfile.fromVolunteerProfileJson(stagingVolunteerJson);
      await SessionManager.saveDetailedProfile(profile);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileScreen(volunteerId: 'COHV-26-0016'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header values
      expect(find.text('Piyush Sharma'), findsOneWidget);
      expect(find.text('COHV-26-0016'), findsOneWidget);
      expect(find.text('Para-veterinarian'), findsNWidgets(2)); // Subtitle and Designation row

      // Key-Value rows
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);

      expect(find.text('Age / date of birth'), findsOneWidget);
      expect(find.textContaining('24 Oct 2001'), findsOneWidget);

      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('9523683214'), findsOneWidget);

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('piyush123@gmail.com'), findsOneWidget);

      expect(find.text('Village / ward'), findsOneWidget);
      expect(find.text('Gram Panchayat /\nMunicipality'), findsOneWidget);
      expect(find.text('Block / Taluk'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);

      expect(find.text('COHV Type'), findsOneWidget);
      expect(find.text('Public Health Department'), findsOneWidget);

      expect(find.text('Educational\nqualification'), findsOneWidget);
      expect(find.text('Diploma'), findsOneWidget);

      expect(find.text('Designation'), findsOneWidget);

      expect(find.text('Reporting supervisor'), findsOneWidget);
      expect(find.textContaining('Dr. Ravi Kumar'), findsOneWidget);

      // Dynamic Institution row
      expect(find.text('Health facility'), findsOneWidget);
      expect(find.text('CHC Amrabad'), findsOneWidget);

      // Verify HARDCODED rows are NOT displayed
      expect(find.text('Veterinary institution\nlinked'), findsNothing);
      expect(find.text('Forest institution linked'), findsNothing);
      expect(find.text('Institution linked'), findsNothing);
    });

    testWidgets('EditProfileScreen initializes dynamic Designation, Qualification and Institution', (tester) async {
      final profile = DetailedVolunteerProfile.fromVolunteerProfileJson(stagingVolunteerJson);

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(profile: profile),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify form titles and elements
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Piyush Sharma'), findsNWidgets(2)); // Photo editor card and text field

      // Verify Designation dropdown label exists
      expect(find.text('Designation'), findsOneWidget);

      // Verify Educational Qualification dropdown label exists
      expect(find.text('Educational Qualification'), findsOneWidget);

      // Verify Department dropdown exists
      expect(find.text('Department'), findsOneWidget);

      // Verify Save button
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
