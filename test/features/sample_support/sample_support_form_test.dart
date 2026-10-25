import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/sample_reprot/data/sample_support_api_service.dart';
import 'package:cohv/features/sample_reprot/screens/sample_support_form_screen.dart';

class MockSampleSupportApiService extends SampleSupportApiService {
  final List<SampleTypeModel> mockTypes;
  final List<VillageModel> mockVillages;

  MockSampleSupportApiService({
    required this.mockTypes,
    required this.mockVillages,
  });

  @override
  Future<List<SampleTypeModel>> fetchSampleTypes({String? sectorFilter}) async {
    if (sectorFilter != null && sectorFilter.trim().isNotEmpty) {
      final filtered =
          mockTypes.where((t) => t.isApplicableTo(sectorFilter)).toList();
      if (filtered.isNotEmpty) return filtered;
    }
    return mockTypes;
  }

  @override
  Future<List<VillageModel>> fetchVillagesForPanchayat(int? gpCode) async {
    return mockVillages;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final rawSampleTypesJson = [
    {
      "sample_type_id": 1,
      "sample_type_name": "Human samples",
      "applicable_sectors": ["human"],
      "is_other": false,
    },
    {
      "sample_type_id": 2,
      "sample_type_name": "Livestock samples",
      "applicable_sectors": ["animal"],
      "is_other": false,
    },
    {
      "sample_type_id": 3,
      "sample_type_name": "Poultry samples",
      "applicable_sectors": ["animal"],
      "is_other": false,
    },
    {
      "sample_type_id": 4,
      "sample_type_name": "Companion animal samples",
      "applicable_sectors": ["animal", "human"],
      "is_other": false,
    },
    {
      "sample_type_id": 5,
      "sample_type_name": "Wildlife samples",
      "applicable_sectors": ["wildlife"],
      "is_other": false,
    },
    {
      "sample_type_id": 6,
      "sample_type_name": "Water samples",
      "applicable_sectors": ["environment"],
      "is_other": false,
    },
    {
      "sample_type_id": 7,
      "sample_type_name": "Food samples",
      "applicable_sectors": ["human", "environment"],
      "is_other": false,
    },
    {
      "sample_type_id": 8,
      "sample_type_name": "Environmental samples",
      "applicable_sectors": ["environment"],
      "is_other": false,
    },
    {
      "sample_type_id": 9,
      "sample_type_name": "Other",
      "applicable_sectors": ["human", "animal", "wildlife", "environment"],
      "is_other": true,
    },
  ];

  final allMockTypes = rawSampleTypesJson
      .map((j) => SampleTypeModel.fromJson(j))
      .toList();

  final mockVillages = const [
    VillageModel(
      villageName: 'Achampet Village',
      villageLgdCode: '580001',
      villageId: 101,
    ),
    VillageModel(
      villageName: 'Mannanur Hamlet',
      villageLgdCode: '580002',
      villageId: 102,
    ),
    VillageModel(
      villageName: 'Amrabad Ward',
      villageLgdCode: '580003',
      villageId: 103,
    ),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_session_json': jsonEncode(
        UserSession(
          volunteerId: 'COHV-26-0004',
          fullName: 'Test Volunteer',
          mobile: '9876543210',
          sector: 'Public Health',
          status: 'ACTIVE',
          token: 'mock-jwt-token',
          gramPanchayatLgdCode: 200123,
          gramPanchayatName: 'Achampet GP',
          villageLgdCode: 580001,
          villageName: 'Achampet Village',
          districtName: 'Nagarkurnool',
          stateName: 'Telangana',
        ).toJson(),
      ),
    });
  });

  group('SampleTypeModel & Sector Filtering Tests', () {
    test('Correctly parses all 9 sample types from API JSON', () {
      expect(allMockTypes.length, 9);
      expect(allMockTypes[0].sampleTypeName, 'Human samples');
      expect(allMockTypes[0].applicableSectors, ['human']);
      expect(allMockTypes[8].isOther, true);
    });

    test('Public Health volunteer (sector: human) sees only applicable sample types', () {
      final humanTypes =
          allMockTypes.where((t) => t.isApplicableTo('human')).toList();

      expect(humanTypes.length, 4);
      final names = humanTypes.map((t) => t.sampleTypeName).toList();
      expect(names, contains('Human samples'));
      expect(names, contains('Companion animal samples'));
      expect(names, contains('Food samples'));
      expect(names, contains('Other'));

      expect(names, isNot(contains('Livestock samples')));
      expect(names, isNot(contains('Poultry samples')));
      expect(names, isNot(contains('Wildlife samples')));
      expect(names, isNot(contains('Water samples')));
      expect(names, isNot(contains('Environmental samples')));
    });

    test('Animal Health volunteer (sector: animal) sees only animal applicable types', () {
      final animalTypes =
          allMockTypes.where((t) => t.isApplicableTo('animal')).toList();

      expect(animalTypes.length, 4);
      final names = animalTypes.map((t) => t.sampleTypeName).toList();
      expect(names, contains('Livestock samples'));
      expect(names, contains('Poultry samples'));
      expect(names, contains('Companion animal samples'));
      expect(names, contains('Other'));

      expect(names, isNot(contains('Human samples')));
      expect(names, isNot(contains('Water samples')));
    });

    test('Department mapping maps correctly', () {
      expect(
        SampleSupportApiService.mapDepartmentToSector('Public Health'),
        'human',
      );
      expect(
        SampleSupportApiService.mapDepartmentToSector('Animal Health Department'),
        'animal',
      );
      expect(
        SampleSupportApiService.mapDepartmentToSector('Forest and Wildlife'),
        'wildlife',
      );
      expect(
        SampleSupportApiService.mapDepartmentToSector('Pollution Control Board'),
        'environment',
      );
    });
  });

  group('SampleSupportFormScreen Widget Tests', () {
    testWidgets('Renders form fields, fixed header, and media buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSampleSupportApiService(
        mockTypes: allMockTypes,
        mockVillages: mockVillages,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SampleSupportFormScreen(
            apiService: mockApi,
            initialVolunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Authenticated Header
      expect(find.byType(AuthenticatedAppBar), findsOneWidget);
      expect(find.text('New Sample Support'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('global_notification_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('global_sync_button')),
        findsOneWidget,
      );

      // Form labels and dropdowns
      expect(find.text('Sample type *'), findsOneWidget);
      expect(find.text('Date *'), findsOneWidget);
      expect(find.text('Number facilitated'), findsOneWidget);
      expect(find.text('Village / ward *'), findsOneWidget);

      // Media Buttons
      expect(find.text('Photograph'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);

      // Searchable dropdowns
      expect(
        find.byType(SearchableDropdownFormField<SampleTypeModel>),
        findsOneWidget,
      );
      expect(
        find.byType(SearchableDropdownFormField<VillageModel>),
        findsOneWidget,
      );

      // Location Card & Refresh Button
      expect(find.text('LOCATION'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      // Save & Cancel
      expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
    });

    testWidgets('Filtering for Public Health volunteer shows only human-applicable sample types', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSampleSupportApiService(
        mockTypes: allMockTypes,
        mockVillages: mockVillages,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SampleSupportFormScreen(
            apiService: mockApi,
            initialVolunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the Sample Type dropdown to open it
      final sampleDropdownFinder = find.byType(
        SearchableDropdownFormField<SampleTypeModel>,
      );
      expect(sampleDropdownFinder, findsOneWidget);

      await tester.tap(sampleDropdownFinder);
      await tester.pumpAndSettle();

      // Check available options in overlay
      expect(find.text('Human samples'), findsOneWidget);
      expect(find.text('Companion animal samples'), findsOneWidget);
      expect(find.text('Food samples'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Should NOT contain animal-only or environment-only options
      expect(find.text('Livestock samples'), findsNothing);
      expect(find.text('Poultry samples'), findsNothing);
      expect(find.text('Wildlife samples'), findsNothing);
      expect(find.text('Water samples'), findsNothing);
    });

    testWidgets('Form validation prevents save without sample type', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSampleSupportApiService(
        mockTypes: allMockTypes,
        mockVillages: mockVillages,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SampleSupportFormScreen(
            apiService: mockApi,
            initialVolunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save without selecting sample type
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('Please select sample type'), findsOneWidget);
    });

    testWidgets('Refreshing GPS updates location metadata', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockApi = MockSampleSupportApiService(
        mockTypes: allMockTypes,
        mockVillages: mockVillages,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SampleSupportFormScreen(
            apiService: mockApi,
            initialVolunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Refresh button in LOCATION section
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(find.text('Location coordinates refreshed.'), findsOneWidget);
    });
  });
}
