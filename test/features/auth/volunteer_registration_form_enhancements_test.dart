import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/presentation/screens/volunteer_registration_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DemographicRepository.clearCache();
  });

  tearDown(() {
    DemographicRepository.customClient = null;
  });

  group('1. Mobile Number Enhancements', () {
    testWidgets(
      'Mobile field enforces digitsOnly and max 10 numeric digits',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Mock empty dynamic APIs
        DemographicRepository.customClient = MockClient((request) async {
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        // Find mobile TextField
        final mobileFinder = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.keyboardType == TextInputType.phone,
        );
        expect(mobileFinder, findsOneWidget);

        final textField = tester.widget<TextField>(mobileFinder);
        final formatters = textField.inputFormatters;
        expect(formatters, isNotNull);
        expect(
          formatters!.any((f) => f is LengthLimitingTextInputFormatter && f.maxLength == 10),
          isTrue,
        );
        expect(
          formatters.any((f) => f == FilteringTextInputFormatter.digitsOnly),
          isTrue,
        );

        // Enter input with more than 10 digits
        await tester.enterText(mobileFinder, '98765432109999');
        await tester.pumpAndSettle();

        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );
        // Field controller should clamp to 10 digits
        expect(state.mobileController.text.length, lessThanOrEqualTo(10));
        expect(state.mobileController.text, '9876543210');
      },
    );

    test('Mobile number regex validation accepts valid Indian numbers and rejects invalid', () {
      final validRegex = RegExp(r'^[6-9]\d{9}$');
      expect(validRegex.hasMatch('9876543210'), isTrue);
      expect(validRegex.hasMatch('8876543210'), isTrue);
      expect(validRegex.hasMatch('7876543210'), isTrue);
      expect(validRegex.hasMatch('6876543210'), isTrue);

      // Rejects numbers starting with 0-5
      expect(validRegex.hasMatch('5876543210'), isFalse);
      expect(validRegex.hasMatch('1876543210'), isFalse);
      expect(validRegex.hasMatch('0876543210'), isFalse);

      // Rejects numbers with length != 10
      expect(validRegex.hasMatch('987654321'), isFalse);
      expect(validRegex.hasMatch('98765432101'), isFalse);
      expect(validRegex.hasMatch(''), isFalse);
      expect(validRegex.hasMatch('98765abcde'), isFalse);
    });
  });

  group('2. Date of Birth (18+ Validation) Enhancements', () {
    testWidgets(
      'Calendar max selectable date is today minus 18 years and allows exactly 18-year-old',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        DemographicRepository.customClient = MockClient((request) async {
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );

        final now = DateTime.now();
        final expectedCutoff = DateTime(now.year - 18, now.month, now.day);
        final calculatedCutoff = state.maxDobCutoff;

        expect(calculatedCutoff.year, expectedCutoff.year);
        expect(calculatedCutoff.month, expectedCutoff.month);
        expect(calculatedCutoff.day, expectedCutoff.day);

        // Verification: 18th birthday is exactly at calculatedCutoff
        int ageAtCutoff = now.year - calculatedCutoff.year;
        if (now.month < calculatedCutoff.month ||
            (now.month == calculatedCutoff.month && now.day < calculatedCutoff.day)) {
          ageAtCutoff--;
        }
        expect(ageAtCutoff >= 18, isTrue);

        // Verification: 1 day after cutoff is under 18 years
        final underageDate = calculatedCutoff.add(const Duration(days: 1));
        int ageUnderage = now.year - underageDate.year;
        if (now.month < underageDate.month ||
            (now.month == underageDate.month && now.day < underageDate.day)) {
          ageUnderage--;
        }
        expect(ageUnderage < 18, isTrue);
      },
    );

    testWidgets(
      'Submission age validation rejects volunteer under 18 with appropriate error message',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        DemographicRepository.customClient = MockClient((request) async {
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );

        // Set an underage date of birth (e.g. today minus 17 years)
        final now = DateTime.now();
        state.selectedDob = DateTime(now.year - 17, now.month, now.day);

        // Trigger register submission
        await state.handleRegister();
        await tester.pump();

        // Expect snackbar/attention banner with 'Volunteer must be at least 18 years old.'
        expect(find.text('Volunteer must be at least 18 years old.'), findsWidgets);
      },
    );
  });

  group('3. Dynamic Dropdowns Enhancements', () {
    testWidgets(
      'When API returns empty response, dropdowns show empty message and contain no dummy options',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Mock empty responses for all dynamic endpoints
        DemographicRepository.customClient = MockClient((request) async {
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );

        // All dynamic lists should be strictly empty, without fallback data
        expect(state.departmentList, isEmpty);
        expect(state.stateList, isEmpty);
        expect(state.districtList, isEmpty);
        expect(state.blockList, isEmpty);
        expect(state.panchayatList, isEmpty);
        expect(state.villageList, isEmpty);
        expect(state.educationList, isEmpty);
        expect(state.professionList, isEmpty);
        expect(state.supervisorList, isEmpty);

        // State dropdown should show 'No states available'
        expect(find.text('No states available'), findsOneWidget);
        // COHV Type dropdown should show 'No COHV types available'
        expect(find.text('No COHV types available'), findsOneWidget);
        // Education dropdown should show 'No qualifications available'
        expect(find.text('No qualifications available'), findsOneWidget);
        // Profession dropdown should show 'No professions available'
        expect(find.text('No professions available'), findsOneWidget);

        // Offline data warning text should NOT appear on normal empty responses
        expect(find.textContaining('offline data'), findsNothing);
      },
    );

    testWidgets(
      'When API fails with 500 error, displays error message with Retry action without falling back to dummy options',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        int callCount = 0;
        DemographicRepository.customClient = MockClient((request) async {
          callCount++;
          return http.Response('Internal Server Error', 500);
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );

        // Lists must remain empty without dummy items
        expect(state.departmentList, isEmpty);
        expect(state.stateList, isEmpty);

        // Error banners should be visible with Retry buttons
        expect(find.text('Failed to load COHV types.'), findsOneWidget);
        expect(find.text('Failed to load states.'), findsOneWidget);
        expect(find.text('Failed to load qualifications.'), findsOneWidget);
        expect(find.text('Failed to load professions.'), findsOneWidget);

        // Offline dummy data should NOT be shown
        expect(find.textContaining('offline data'), findsNothing);

        // Find and tap a Retry button
        final retryFinders = find.text('Retry');
        expect(retryFinders, findsWidgets);

        final initialCalls = callCount;
        await tester.tap(retryFinders.first);
        await tester.pumpAndSettle();

        // Verify that retry initiated another API call
        expect(callCount, greaterThan(initialCalls));
      },
    );

    testWidgets(
      'When API succeeds, dropdowns are populated dynamically with API items',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        DemographicRepository.customClient = MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/departments')) {
            return http.Response(
              jsonEncode([
                {'department_id': 101, 'department_name': 'One Health Department'},
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (path.endsWith('/locations/states')) {
            return http.Response(
              jsonEncode([
                {'state_name': 'Custom State Alpha', 'state_lgd_code': '99'},
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (path.endsWith('/locations/educations')) {
            return http.Response(
              jsonEncode([
                {'education_id': 201, 'education_name': 'Post Doctorate', 'is_other': false},
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else if (path.endsWith('/locations/professions')) {
            return http.Response(
              jsonEncode([
                {'profession_id': 301, 'profession_name': 'Field Epidemiologist'},
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        });

        await tester.pumpWidget(
          const MaterialApp(home: VolunteerRegistrationScreen()),
        );
        await tester.pumpAndSettle();

        final state = tester.state<VolunteerRegistrationScreenState>(
          find.byType(VolunteerRegistrationScreen),
        );

        expect(state.departmentList.length, 1);
        expect(state.departmentList.first.departmentName, 'One Health Department');

        expect(state.stateList.length, 1);
        expect(state.stateList.first.stateName, 'Custom State Alpha');

        expect(state.educationList.length, 1);
        expect(state.educationList.first.educationName, 'Post Doctorate');

        expect(state.professionList.length, 1);
        expect(state.professionList.first.professionName, 'Field Epidemiologist');

        // Tap COHV Type dropdown and select 'One Health Department'
        await tester.tap(find.byKey(const ValueKey('dropdown_cohv_type_none')));
        await tester.pumpAndSettle();
        expect(find.text('One Health Department'), findsWidgets);
        await tester.tap(find.text('One Health Department').last);
        await tester.pumpAndSettle();

        expect(state.selectedCohvType, 'One Health Department');
      },
    );
  });
}
