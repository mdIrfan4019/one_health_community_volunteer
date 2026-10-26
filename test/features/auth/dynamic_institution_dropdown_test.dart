import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/presentation/screens/volunteer_registration_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DemographicRepository.clearCache();
    DemographicRepository.customClient = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/departments')) {
        return http.Response(
          jsonEncode([
            {'department_id': 1, 'department_name': 'Public Health Department'},
            {'department_id': 2, 'department_name': 'Animal Department'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (path.endsWith('/departments/1/institutions')) {
        return http.Response(
          jsonEncode([
            {
              'institution_type_id': 3,
              'department_id': 1,
              'field_label': 'Health facility',
              'option_name': 'PHC',
              'is_other': false,
              'sort_order': 1,
            },
            {
              'institution_type_id': 6,
              'department_id': 1,
              'field_label': 'Health facility',
              'option_name': 'CHC',
              'is_other': false,
              'sort_order': 2,
            },
            {
              'institution_type_id': 1,
              'department_id': 1,
              'field_label': 'Health facility',
              'option_name': 'Other',
              'is_other': true,
              'sort_order': 3,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (path.endsWith('/departments/2/institutions')) {
        return http.Response(
          jsonEncode([
            {
              'institution_type_id': 4,
              'department_id': 2,
              'field_label': 'Veterinary institution',
              'option_name': 'Veterinary Hospital',
              'is_other': false,
              'sort_order': 1,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (path.endsWith('/locations/states')) {
        return http.Response(
          jsonEncode([
            {'state_name': 'Telangana', 'state_lgd_code': '36'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (path.endsWith('/locations/educations')) {
        return http.Response(
          jsonEncode([
            {'education_id': 1, 'education_name': 'Graduate', 'is_other': false},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      } else if (path.endsWith('/locations/professions')) {
        return http.Response(
          jsonEncode([
            {'profession_id': 1, 'profession_name': 'Student'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });
  });

  tearDown(() {
    DemographicRepository.customClient = null;
  });

  group('DepartmentModel & InstitutionModel Domain Unit Tests', () {
    test('DepartmentModel parses standard JSON and alternate keys', () {
      final json = {
        'department_id': 1,
        'department_name': 'Public Health Department',
      };
      final model = DepartmentModel.fromJson(json);

      expect(model.departmentId, 1);
      expect(model.id, 1);
      expect(model.departmentName, 'Public Health Department');
      expect(model.toString(), 'Public Health Department');

      final serialized = model.toJson();
      expect(serialized['department_id'], 1);
      expect(serialized['department_name'], 'Public Health Department');

      // Alternate keys
      final altModel = DepartmentModel.fromJson({
        'id': 2,
        'name': 'Animal Department',
      });
      expect(altModel.departmentId, 2);
      expect(altModel.departmentName, 'Animal Department');
    });

    test('InstitutionModel parses standard JSON and preserves sort_order & is_other', () {
      final jsonList = [
        {
          'institution_type_id': 3,
          'department_id': 1,
          'field_label': 'Health facility',
          'option_name': 'PHC',
          'is_other': false,
          'sort_order': 1,
        },
        {
          'institution_type_id': 6,
          'department_id': 1,
          'field_label': 'Health facility',
          'option_name': 'CHC',
          'is_other': false,
          'sort_order': 2,
        },
        {
          'institution_type_id': 1,
          'department_id': 1,
          'field_label': 'Health facility',
          'option_name': 'Other',
          'is_other': true,
          'sort_order': 3,
        },
      ];

      final models = jsonList.map((j) => InstitutionModel.fromJson(j)).toList();

      expect(models.length, 3);
      expect(models[0].institutionTypeId, 3);
      expect(models[0].departmentId, 1);
      expect(models[0].fieldLabel, 'Health facility');
      expect(models[0].optionName, 'PHC');
      expect(models[0].isOther, false);
      expect(models[0].sortOrder, 1);

      expect(models[2].institutionTypeId, 1);
      expect(models[2].optionName, 'Other');
      expect(models[2].isOther, true);
      expect(models[2].sortOrder, 3);

      // Verify ascending order
      models.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      expect(models.map((m) => m.optionName).toList(), ['PHC', 'CHC', 'Other']);
    });
  });

  group('DemographicRepository Department & Institution API Tests', () {
    test('fetchDepartmentsFromApi parses direct list response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/departments'));

        return http.Response(
          jsonEncode([
            {'department_id': 1, 'department_name': 'Public Health Department'},
            {'department_id': 2, 'department_name': 'Animal Department'},
            {'department_id': 3, 'department_name': 'Wildlife Department'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final departments = await DemographicRepository.fetchDepartmentsFromApi(
        client: mockClient,
      );
      expect(departments.length, 3);
      expect(departments.first.departmentId, 1);
      expect(departments.first.departmentName, 'Public Health Department');
      expect(departments[1].departmentName, 'Animal Department');
    });

    test('fetchDepartmentsFromApi parses wrapped envelope responses', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'department_id': 4, 'department_name': 'Environment Department'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final departments = await DemographicRepository.fetchDepartmentsFromApi(
        client: mockClient,
      );
      expect(departments.length, 1);
      expect(departments.first.departmentId, 4);
      expect(departments.first.departmentName, 'Environment Department');
    });

    test('fetchInstitutionsFromApi calls endpoint with department_id and sorts by sort_order', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/departments/1/institutions'));

        return http.Response(
          jsonEncode([
            {
              'institution_type_id': 1,
              'department_id': 1,
              'field_label': 'Health facility',
              'option_name': 'Other',
              'is_other': true,
              'sort_order': 3,
            },
            {
              'institution_type_id': 3,
              'department_id': 1,
              'field_label': 'Health facility',
              'option_name': 'PHC',
              'is_other': false,
              'sort_order': 1,
            },
            {
              'institution_type_id': 6,
              'department_id': 1,
              'field_label': 'Health facility',
              'option_name': 'CHC',
              'is_other': false,
              'sort_order': 2,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final institutions = await DemographicRepository.fetchInstitutionsFromApi(
        1,
        client: mockClient,
      );
      expect(institutions.length, 3);
      // Verify that options are sorted in ascending sort_order: PHC (1), CHC (2), Other (3)
      expect(institutions[0].optionName, 'PHC');
      expect(institutions[1].optionName, 'CHC');
      expect(institutions[2].optionName, 'Other');
      expect(institutions[2].isOther, true);
    });

    test('getFallbackDepartments and getFallbackInstitutions return valid defaults', () {
      final depts = DemographicRepository.getFallbackDepartments();
      expect(depts.isNotEmpty, true);
      expect(
        depts.any(
          (d) =>
              d.departmentId == 1 &&
              d.departmentName == 'Public Health Department',
        ),
        true,
      );
      expect(
        depts.any(
          (d) => d.departmentId == 2 && d.departmentName == 'Animal Department',
        ),
        true,
      );

      final institutions1 = DemographicRepository.getFallbackInstitutions(1);
      expect(institutions1.length, 3);
      expect(institutions1.first.fieldLabel, 'Health facility');
      expect(
        institutions1.any((i) => i.isOther && i.optionName == 'Other'),
        true,
      );

      final institutions2 = DemographicRepository.getFallbackInstitutions(2);
      expect(institutions2.isNotEmpty, true);
      expect(institutions2.first.fieldLabel, 'Veterinary institution');
    });
  });

  group('VolunteerRegistrationRequest Form State & Payload Tests', () {
    test(
      'VolunteerRegistrationRequest preserves department and institution info',
      () {
        final request = VolunteerRegistrationRequest(
          volunteerName: 'Aarav',
          gender: 'Male',
          dateOfBirth: DateTime(1995, 5, 20),
          mobileNo: '9876543210',
          email: 'aarav@example.com',
          cohvType: 'Public Health',
          stateLgdCode: 36,
          districtLgdCode: 694,
          blockLgdCode: 5208,
          gramPanchayatLgdCode: 9000001,
          villageLgdCode: 90000001,
          dateOfJoining: DateTime(2026, 10, 20),
          educationId: 1,
          professionId: 1,
          pin: '1234',
          departmentId: 1,
          institutionTypeId: 3,
          institutionName: 'PHC',
          customInstitutionName: null,
        );

        expect(request.departmentId, 1);
        expect(request.institutionTypeId, 3);
        expect(request.institutionName, 'PHC');
        expect(request.customInstitutionName, null);

        final json = request.toJson();
        expect(json['department_id'], 1);
        expect(json['institution_type_id'], 3);
        expect(json['institution_name'], 'PHC');
        expect(json.containsKey('custom_institution_name'), false);

        final otherRequest = VolunteerRegistrationRequest(
          volunteerName: 'Aarav',
          gender: 'Male',
          dateOfBirth: DateTime(1995, 5, 20),
          mobileNo: '9876543210',
          email: 'aarav@example.com',
          cohvType: 'Public Health',
          stateLgdCode: 36,
          districtLgdCode: 694,
          blockLgdCode: 5208,
          gramPanchayatLgdCode: 9000001,
          villageLgdCode: 90000001,
          dateOfJoining: DateTime(2026, 10, 20),
          educationId: 1,
          professionId: 1,
          pin: '1234',
          departmentId: 1,
          institutionTypeId: 1,
          institutionName: 'Other',
          customInstitutionName: 'District Wellness Center',
        );

        final otherJson = otherRequest.toJson();
        expect(otherJson['department_id'], 1);
        expect(otherJson['institution_type_id'], 1);
        expect(otherJson['institution_name'], 'Other');
        expect(
          otherJson['custom_institution_name'],
          'District Wellness Center',
        );
      },
    );
  });

  group('VolunteerRegistrationScreen Dynamic Dropdown & UI Widget Tests', () {
    testWidgets(
      'Initial state: COHV Type dropdown exists; institution & custom inputs hidden',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        // COHV Type dropdown should be visible and unselected
        expect(
          find.byKey(const ValueKey('dropdown_cohv_type_none')),
          findsOneWidget,
        );

        // Institution dropdown and custom input should NOT be in the tree initially
        expect(
          find.byKey(const ValueKey('dropdown_institution_none')),
          findsNothing,
        );
        expect(find.text('Enter institution name here'), findsNothing);
      },
    );

    testWidgets(
      'Selecting COHV Type shows dynamic institution dropdown with red asterisk',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        // Tap COHV Type dropdown
        final cohvFinder = find.byKey(
          const ValueKey('dropdown_cohv_type_none'),
        );
        expect(cohvFinder, findsOneWidget);

        // Tap the dropdown field to open overlay
        await tester.tap(cohvFinder);
        await tester.pumpAndSettle();

        // Select 'Public Health Department'
        final publicHealthOption = find.text('Public Health Department').last;
        await tester.tap(publicHealthOption);
        await tester.pumpAndSettle();

        // Now institution dropdown should be visible with dynamic label 'Health facility *'
        expect(find.textContaining('Health facility'), findsWidgets);

        // Verify that the red asterisk is present in label
        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );
        expect(state.selectedDepartmentModel?.departmentId, 1);
        expect(state.currentInstitutionFieldLabel, 'Health facility');

        // The custom text field for 'Other' must still be hidden
        expect(find.text('Enter institution name here'), findsNothing);
      },
    );

    testWidgets(
      'Selecting "Other" institution reveals custom input with Specify label and hint',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        // Open and select Public Health Department
        await tester.tap(find.byKey(const ValueKey('dropdown_cohv_type_none')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Public Health Department').last);
        await tester.pumpAndSettle();

        // Find the newly rendered institution dropdown
        final institutionFinder = find.byKey(
          const ValueKey('dropdown_institution_none'),
        );
        expect(institutionFinder, findsOneWidget);

        // Tap institution dropdown to open overlay
        await tester.tap(institutionFinder);
        await tester.pumpAndSettle();

        // Options 'PHC', 'CHC', 'Other' should be present
        expect(find.text('PHC'), findsWidgets);
        expect(find.text('CHC'), findsWidgets);
        expect(find.text('Other'), findsWidgets);

        // Select 'Other'
        await tester.tap(find.text('Other').last);
        await tester.pumpAndSettle();

        // Custom input should now be displayed
        expect(find.textContaining('Specify health facility'), findsOneWidget);
        expect(find.text('Enter institution name here'), findsOneWidget);

        // Selecting a regular option (PHC) should hide and clear custom input
        await tester.tap(
          find.byKey(const ValueKey('dropdown_institution_Other')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('PHC').last);
        await tester.pumpAndSettle();

        expect(find.text('Enter institution name here'), findsNothing);
      },
    );

    testWidgets(
      'Switching departments clears previous institution selection and custom input',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        // Select Public Health Department
        await tester.tap(find.byKey(const ValueKey('dropdown_cohv_type_none')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Public Health Department').last);
        await tester.pumpAndSettle();

        // Select Other institution and enter custom text
        await tester.tap(
          find.byKey(const ValueKey('dropdown_institution_none')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Other').last);
        await tester.pumpAndSettle();

        // Enter custom institution name
        await tester.enterText(
          find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.hintText == 'Enter institution name here',
          ),
          'Special Clinic',
        );
        await tester.pumpAndSettle();

        // Now switch department to Animal Department
        await tester.tap(
          find.byKey(
            const ValueKey('dropdown_cohv_type_Public Health Department'),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Animal Department').last);
        await tester.pumpAndSettle();

        // State check: previous institution selection is cleared, label updated to Veterinary institution
        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );
        expect(state.selectedDepartmentModel?.departmentId, 2);
        expect(state.currentInstitutionFieldLabel, 'Veterinary institution');
        expect(state.selectedInstitutionModel, isNull);

        // Custom input should be hidden and cleared
        expect(find.text('Enter institution name here'), findsNothing);
      },
    );
  });
}
