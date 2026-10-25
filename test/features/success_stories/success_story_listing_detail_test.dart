import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/success_stories/data/success_story_api_service.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/success_stories/screens/success_story_detail_screen.dart';
import 'package:cohv/features/success_stories/screens/success_stories_screen.dart';

class MockSuccessStoryApiService extends SuccessStoryApiService {
  List<SuccessStoryRecordModel> mockStories;
  SuccessStoryRecordModel? mockDetailStory;
  int? lastRequestedDetailId;
  bool fetchListCalled = false;

  MockSuccessStoryApiService({
    required this.mockStories,
    this.mockDetailStory,
  });

  @override
  Future<List<SuccessStoryRecordModel>> fetchSuccessStoriesList({
    String? volunteerId,
    int? numericVolunteerId,
  }) async {
    fetchListCalled = true;
    return mockStories;
  }

  @override
  Future<SuccessStoryRecordModel?> fetchSuccessStoryDetail(int storyId) async {
    lastRequestedDetailId = storyId;
    if (mockDetailStory != null) return mockDetailStory;
    for (final s in mockStories) {
      if (s.storyId == storyId) return s;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final rawStoryJson = {
    "story_id": 1,
    "story_code": "STY-26-0001",
    "volunteer_id": 52,
    "volunteer_name": "Abdul",
    "title": "Village Chlorination Test",
    "story_date": "2026-10-25",
    "location_text": "Amrabad",
    "one_health_issue": "Water Contamination",
    "situation": "Contaminated wells in the village",
    "action_taken": "Coordinated with Public Health",
    "department_id": 1,
    "department_name": "Public Health Department",
    "department_other": null,
    "outcome": "Water source secured",
    "community_benefit": "Safe water for 200 households",
    "lessons_learned": "Regular testing avoids outbreaks",
    "is_innovation": false,
    "latitude": "25.281198",
    "longitude": "82.953928",
    "gps_accuracy_m": 22,
    "gps_unavailable_reason": null,
    "verification_status": "SUBMITTED",
    "captured_at": "2026-10-25T13:52:22.969637+05:30",
    "created_at": "2026-10-25T13:52:22.969637+05:30",
    "updated_at": "2026-10-25T13:52:22.969637+05:30"
  };

  group('SuccessStoryRecordModel Tests', () {
    test('Parses GET /api/success-stories/all response item correctly', () {
      final story = SuccessStoryRecordModel.fromJson(rawStoryJson);

      expect(story.storyId, 1);
      expect(story.storyCode, 'STY-26-0001');
      expect(story.volunteerId, 52);
      expect(story.volunteerName, 'Abdul');
      expect(story.title, 'Village Chlorination Test');
      expect(story.storyDate, '2026-10-25');
      expect(story.formattedDate, '25 Oct 2026');
      expect(story.locationText, 'Amrabad');
      expect(story.oneHealthIssue, 'Water Contamination');
      expect(story.departmentId, 1);
      expect(story.departmentName, 'Public Health Department');
      expect(story.outcome, 'Water source secured');
      expect(story.communityBenefit, 'Safe water for 200 households');
      expect(story.lessonsLearned, 'Regular testing avoids outbreaks');
      expect(story.isInnovation, isFalse);
      expect(story.formattedCategory, 'Success Story');
      expect(story.formattedInnovation, 'No');
      expect(story.formattedVerificationStatus, 'Submitted');
      expect(story.statusBadge, 'pending');
      expect(story.formattedGpsLocation, contains('25.281198, 82.953928'));
    });

    test('Innovation flag formats category correctly', () {
      final innovJson = Map<String, dynamic>.from(rawStoryJson);
      innovJson['is_innovation'] = true;
      final story = SuccessStoryRecordModel.fromJson(innovJson);

      expect(story.isInnovation, isTrue);
      expect(story.formattedCategory, 'innovation / best practice');
      expect(story.formattedInnovation, 'Yes');
    });
  });

  group('SuccessStoriesScreen Widget Tests', () {
    testWidgets('Renders story card with Sample Support layout from API', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final story = SuccessStoryRecordModel.fromJson(rawStoryJson);
      final mockApi = MockSuccessStoryApiService(mockStories: [story]);

      await tester.pumpWidget(
        MaterialApp(
          home: SuccessStoriesScreen(
            apiService: mockApi,
            volunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(mockApi.fetchListCalled, isTrue);

      // Verify Screen Header
      expect(find.text('Success Stories'), findsOneWidget);

      // Verify Card elements (Sample Support layout)
      expect(find.byType(SuccessStoryCard), findsOneWidget);
      expect(find.text('Village Chlorination Test'), findsOneWidget);
      expect(find.text('synced'), findsOneWidget);
      expect(find.textContaining('STY-26-0001'), findsOneWidget);
      expect(find.textContaining('25 Oct 2026'), findsOneWidget);
      expect(find.text('Amrabad · Success Story'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Verify Floating Action Button
      expect(find.byKey(const ValueKey('add_success_story_fab')), findsOneWidget);
      expect(find.text('New Story'), findsOneWidget);
    });

    testWidgets('Renders empty state when API returns no stories', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSuccessStoryApiService(mockStories: []);

      await tester.pumpWidget(
        MaterialApp(
          home: SuccessStoriesScreen(
            apiService: mockApi,
            volunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('No success stories documented yet.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping card opens detail screen with story details', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final story = SuccessStoryRecordModel.fromJson(rawStoryJson);
      final mockApi = MockSuccessStoryApiService(
        mockStories: [story],
        mockDetailStory: story,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SuccessStoriesScreen(
            apiService: mockApi,
            volunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the card
      await tester.tap(find.byType(SuccessStoryCard));
      await tester.pumpAndSettle();

      // Verify Detail Screen is presented
      expect(find.byType(SuccessStoryDetailScreen), findsOneWidget);
      expect(mockApi.lastRequestedDetailId, 1);

      // Verify Detail Card content
      expect(find.text('Village Chlorination Test'), findsNWidgets(2)); // Card header & Title row
      expect(find.text('STY-26-0001'), findsOneWidget);
      expect(find.text('25 Oct 2026'), findsOneWidget);
      expect(find.text('Amrabad'), findsOneWidget);
      expect(find.text('Water Contamination'), findsOneWidget);
      expect(find.text('Contaminated wells in the village'), findsOneWidget);
      expect(find.text('Coordinated with Public Health'), findsOneWidget);
      expect(find.text('Public Health Department'), findsOneWidget);
      expect(find.text('Water source secured'), findsOneWidget);
      expect(find.text('Safe water for 200 households'), findsOneWidget);
      expect(find.text('Regular testing avoids outbreaks'), findsOneWidget);
      expect(find.text('ATTACHMENTS'), findsOneWidget);

      // Tap Back button
      final backBtn = find.widgetWithText(OutlinedButton, 'Back');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Returned to list
      expect(find.byType(SuccessStoriesScreen), findsOneWidget);
    });
  });

  group('SuccessStoryDetailScreen Direct Fetch Tests', () {
    testWidgets('Loads data dynamically from GET /api/success-stories/{id} when initialized with id', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final story = SuccessStoryRecordModel.fromJson(rawStoryJson);
      final mockApi = MockSuccessStoryApiService(
        mockStories: [],
        mockDetailStory: story,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SuccessStoryDetailScreen(
            storyId: 1,
            apiService: mockApi,
            volunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(mockApi.lastRequestedDetailId, 1);
      expect(find.text('Village Chlorination Test'), findsNWidgets(2));
      expect(find.text('Public Health Department'), findsOneWidget);
      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
