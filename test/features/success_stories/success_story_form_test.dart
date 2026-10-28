import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/features/success_stories/data/success_story_api_service.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/success_stories/screens/new_success_story_screen.dart';

class MockSuccessStoryApiService extends SuccessStoryApiService {
  final List<SuccessStoryDepartmentModel> mockDepartments;
  SuccessStoryCreateRequest? lastSubmittedRequest;
  SuccessStoryCreateResponse? mockResponse;

  MockSuccessStoryApiService({
    required this.mockDepartments,
  });

  @override
  Future<List<SuccessStoryDepartmentModel>> fetchDepartments() async {
    return mockDepartments;
  }

  @override
  Future<SuccessStoryCreateResponse> submitSuccessStory(
    SuccessStoryCreateRequest request,
  ) async {
    lastSubmittedRequest = request;
    return mockResponse ??
        SuccessStoryCreateResponse(
          success: true,
          message: 'Success story submitted successfully.',
          storyId: 10,
          storyCode: 'STY-26-0010',
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final rawDepartmentsJson = [
    {
      "department_id": 1,
      "department_name": "Public Health Department",
    },
    {
      "department_id": 2,
      "department_name": "Animal Husbandry Department",
    },
    {
      "department_id": 3,
      "department_name": "Wildlife Department",
    },
    {
      "department_id": 4,
      "department_name": "Environment Department",
    },
    {
      "department_id": 5,
      "department_name": "Rural Department",
    },
    {
      "department_id": 6,
      "department_name": "Urban Department",
    },
  ];

  final allMockDepartments = rawDepartmentsJson
      .map((item) => SuccessStoryDepartmentModel.fromJson(item))
      .toList();

  group('SuccessStoryDepartmentModel Tests', () {
    test('Correctly parses departments from GET /api/success-stories/departments API', () {
      expect(allMockDepartments.length, 6);
      expect(allMockDepartments[0].departmentId, 1);
      expect(allMockDepartments[0].departmentName, 'Public Health Department');
      expect(allMockDepartments[1].departmentId, 2);
      expect(allMockDepartments[1].departmentName, 'Animal Husbandry Department');
      expect(allMockDepartments[2].departmentId, 3);
      expect(allMockDepartments[2].departmentName, 'Wildlife Department');
      expect(allMockDepartments[3].departmentId, 4);
      expect(allMockDepartments[3].departmentName, 'Environment Department');
      expect(allMockDepartments[4].departmentId, 5);
      expect(allMockDepartments[4].departmentName, 'Rural Department');
      expect(allMockDepartments[5].departmentId, 6);
      expect(allMockDepartments[5].departmentName, 'Urban Department');
    });

    test('Identifies "Community / NGO" and "Other" correctly', () {
      final otherDept = SuccessStoryDepartmentModel.fromJson({
        "department_id": 99,
        "department_name": "Other",
      });
      expect(otherDept.isOther, isTrue);

      final ngoDept = SuccessStoryDepartmentModel.fromJson({
        "department_id": 7,
        "department_name": "Community / NGO",
      });
      expect(ngoDept.isOther, isTrue);
    });
  });

  group('POST /api/success-stories Payload & Response Tests', () {
    test('SuccessStoryCreateRequest toJson matches OpenAPI Swagger schema exactly', () {
      const request = SuccessStoryCreateRequest(
        volunteerId: 1,
        clientRef: 'STY-1729860000',
        deviceId: 'DEV-WZU69XEL',
        title: 'Rabies Awareness Drive',
        storyDate: '2026-10-25',
        locationText: 'Achampet Village, Achampet GP',
        oneHealthIssue: 'Zoonotic disease control',
        situation: 'Community dogs straying near schools without rabies vaccination.',
        actionTaken: 'Mobilized veterinary team and vaccinated 45 dogs.',
        departmentId: 2,
        departmentOther: null,
        outcome: 'Zero animal bite cases reported in the next 3 months.',
        communityBenefit: 'Safer environment for school children.',
        lessonsLearned: 'Cross-department coordination with local school heads is key.',
        isInnovation: true,
        latitude: 25.281198,
        longitude: 82.953928,
        gpsAccuracyM: 22,
        gpsUnavailableReason: null,
      );

      final json = request.toJson();

      expect(json['volunteer_id'], 1);
      expect(json['client_ref'], 'STY-1729860000');
      expect(json['device_id'], 'DEV-WZU69XEL');
      expect(json['title'], 'Rabies Awareness Drive');
      expect(json['story_date'], '2026-10-25');
      expect(json['location_text'], 'Achampet Village, Achampet GP');
      expect(json['one_health_issue'], 'Zoonotic disease control');
      expect(json['situation'], 'Community dogs straying near schools without rabies vaccination.');
      expect(json['action_taken'], 'Mobilized veterinary team and vaccinated 45 dogs.');
      expect(json['department_id'], 2);
      expect(json['department_other'], isNull);
      expect(json['outcome'], 'Zero animal bite cases reported in the next 3 months.');
      expect(json['community_benefit'], 'Safer environment for school children.');
      expect(json['lessons_learned'], 'Cross-department coordination with local school heads is key.');
      expect(json['is_innovation'], isTrue);
      expect(json['latitude'], 25.281198);
      expect(json['longitude'], 82.953928);
      expect(json['gps_accuracy_m'], 22);
      expect(json['gps_unavailable_reason'], isNull);
    });

    test('SuccessStoryCreateResponse parses server response properly', () {
      final successJson = {
        "success": true,
        "message": "Success story created successfully",
        "data": {
          "story_id": 15,
          "story_code": "STY-26-0015",
        },
      };

      final response = SuccessStoryCreateResponse.fromJson(successJson);
      expect(response.success, isTrue);
      expect(response.storyId, 15);
      expect(response.storyCode, 'STY-26-0015');
    });
  });

  group('NewSuccessStoryScreen Widget Tests', () {
    testWidgets('Renders all fields, searchable department dropdown, and location card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSuccessStoryApiService(
        mockDepartments: allMockDepartments,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NewSuccessStoryScreen(
            apiService: mockApi,
            initialVolunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      Finder findRichText(String text) => find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains(text),
          );

      // Verify Header
      expect(find.text('New Success Story'), findsOneWidget);

      // Verify Labels
      expect(findRichText('Title *'), findsOneWidget);
      expect(findRichText('Date *'), findsOneWidget);
      expect(findRichText('Location'), findsOneWidget);
      expect(findRichText('One Health issue *'), findsOneWidget);
      expect(findRichText('Situation / problem *'), findsOneWidget);
      expect(findRichText('Action taken by COHV *'), findsOneWidget);
      expect(findRichText('Department'), findsWidgets);
      expect(findRichText('Outcome *'), findsOneWidget);
      expect(findRichText('Community benefit'), findsOneWidget);
      expect(findRichText('Lessons learned'), findsOneWidget);
      expect(find.text('Record as an innovation / best practice'), findsOneWidget);

      // Verify Attachment Buttons
      expect(find.text('Photograph'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);

      // Verify Location Card
      expect(find.text('LOCATION'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // Verify Save and Cancel Buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Form validation blocks saving without required fields', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSuccessStoryApiService(
        mockDepartments: allMockDepartments,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NewSuccessStoryScreen(
            apiService: mockApi,
            initialVolunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save button without entering values
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify validator messages
      expect(find.text('Please enter Title'), findsOneWidget);
      expect(find.text('Please enter One Health issue'), findsOneWidget);
      expect(find.text('Please enter Situation / problem'), findsOneWidget);
      expect(find.text('Please enter Action taken by COHV'), findsOneWidget);
      expect(find.text('Please enter Outcome'), findsOneWidget);

      // API should not have been called
      expect(mockApi.lastSubmittedRequest, isNull);
    });

    testWidgets('Submitting valid form calls POST /api/success-stories with correct payload', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSuccessStoryApiService(
        mockDepartments: allMockDepartments,
      );

      Map<String, dynamic>? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewSuccessStoryScreen(
                      apiService: mockApi,
                      initialVolunteerId: 'COHV-26-0004',
                    ),
                  ),
                );
              },
              child: const Text('Open Form'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      // Title
      final titleField = find.byKey(const ValueKey('story_title_field'));
      await tester.ensureVisible(titleField);
      await tester.enterText(titleField, 'Village Water Chlorination Success');
      await tester.pumpAndSettle();

      // One Health issue
      final issueField = find.byKey(const ValueKey('story_issue_field'));
      await tester.ensureVisible(issueField);
      await tester.enterText(issueField, 'Water contamination outbreak control');
      await tester.pumpAndSettle();

      // Situation
      final situationField = find.byKey(const ValueKey('story_problem_field'));
      await tester.ensureVisible(situationField);
      await tester.enterText(
          situationField, 'Diarrhea cases reported due to contaminated well.');
      await tester.pumpAndSettle();

      // Action taken
      final actionField = find.byKey(const ValueKey('story_action_field'));
      await tester.ensureVisible(actionField);
      await tester.enterText(actionField,
          'Coordinated with Public Health Department for chlorination.');
      await tester.pumpAndSettle();

      // Select Department via Searchable Dropdown
      final dropdownFinder =
          find.byKey(const ValueKey('story_department_dropdown'));
      expect(dropdownFinder, findsOneWidget);
      await tester.ensureVisible(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Select 'Public Health Department'
      await tester.tap(find.text('Public Health Department').last);
      await tester.pumpAndSettle();

      // Close multi-select dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Outcome
      final outcomeField = find.byKey(const ValueKey('story_outcome_field'));
      await tester.ensureVisible(outcomeField);
      await tester.enterText(outcomeField,
          'Well was chlorinated and no new diarrhea cases were observed.');
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.byKey(const ValueKey('story_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify POST API call
      expect(mockApi.lastSubmittedRequest, isNotNull);
      final req = mockApi.lastSubmittedRequest!;
      expect(req.title, 'Village Water Chlorination Success');
      expect(req.oneHealthIssue, 'Water contamination outbreak control');
      expect(req.departmentId, 1);
      expect(req.actionTaken, contains('Public Health'));
      expect(req.outcome, contains('chlorinated'));

      // Verify returned result to caller
      expect(returnedResult, isNotNull);
      expect(returnedResult!['title'], 'Village Water Chlorination Success');
      expect(returnedResult!['department'], 'Public Health Department');
      expect(returnedResult!['status'], 'submitted');
    });

    testWidgets('Location refresh button updates coordinates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSuccessStoryApiService(
        mockDepartments: allMockDepartments,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: NewSuccessStoryScreen(
            apiService: mockApi,
            initialVolunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Refresh in location card
      final refreshBtn = find.text('Refresh');
      await tester.ensureVisible(refreshBtn);
      await tester.pumpAndSettle();
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      expect(find.text('Location coordinates refreshed.'), findsOneWidget);
    });
  });
}
