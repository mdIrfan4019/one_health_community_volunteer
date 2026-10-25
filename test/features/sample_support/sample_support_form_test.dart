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
import 'package:cohv/features/sample_reprot/screens/sample_support_screen.dart';

class MockSampleSupportApiService extends SampleSupportApiService {
  final List<SampleTypeModel> mockTypes;
  final List<VillageModel> mockVillages;
  List<SampleSupportRecordModel> mockRecords;
  SampleSupportRecordModel? mockDetail;
  int? lastDetailRequestedId;
  SampleSupportCreateRequest? lastSubmittedRequest;
  SampleSupportCreateResponse? mockResponse;

  MockSampleSupportApiService({
    required this.mockTypes,
    required this.mockVillages,
    this.mockRecords = const [],
    this.mockDetail,
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

  @override
  Future<SampleSupportCreateResponse> submitSampleSupport(
    SampleSupportCreateRequest request,
  ) async {
    lastSubmittedRequest = request;
    return mockResponse ??
        SampleSupportCreateResponse(
          success: true,
          message: 'Sample support created successfully.',
          sampleId: 101,
          sampleCode: 'SMP-26-0005',
          volunteerId: request.volunteerId,
          sampleTypeId: request.sampleTypeId,
          sampleTypeName: 'Human samples',
          sampleDate: request.sampleDate,
          sampleCount: request.sampleCount,
          villageLgdCode: request.villageLgdCode,
          villageName: 'Achampet Village',
        );
  }

  @override
  Future<List<SampleSupportRecordModel>> fetchSampleSupportList({
    int? volunteerId,
  }) async {
    return mockRecords;
  }

  @override
  Future<SampleSupportRecordModel?> fetchSampleSupportDetail(int sampleId) async {
    lastDetailRequestedId = sampleId;
    if (mockDetail != null) return mockDetail;
    for (final r in mockRecords) {
      if (r.sampleId == sampleId) return r;
    }
    return null;
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
          numericVolunteerId: 4,
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
      'numeric_volunteer_id': 4,
    });
  });

  group('SampleTypeModel & Sector Filtering Tests', () {
    test('Correctly parses all 9 sample types from API JSON', () {
      expect(allMockTypes.length, 9);
      expect(allMockTypes[0].sampleTypeId, 1);
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

  group('POST /api/sample-support Payload & Response Tests', () {
    test('SampleSupportCreateRequest toJson serializes exact OpenAPI payload', () {
      const request = SampleSupportCreateRequest(
        volunteerId: 4,
        clientRef: 'SMP-REF-12345',
        deviceId: 'DEV-WZU69XEL',
        sampleTypeId: 1,
        sampleDate: '2026-10-25',
        sampleCount: 2,
        villageLgdCode: 580001,
        latitude: 25.281198,
        longitude: 82.953928,
        gpsAccuracyM: 22,
        gpsUnavailableReason: null,
        capturedAt: '2026-10-25T04:44:55.571Z',
      );

      final json = request.toJson();
      expect(json['volunteer_id'], 4);
      expect(json['client_ref'], 'SMP-REF-12345');
      expect(json['device_id'], 'DEV-WZU69XEL');
      expect(json['sample_type_id'], 1);
      expect(json['sample_date'], '2026-10-25');
      expect(json['sample_count'], 2);
      expect(json['village_lgd_code'], 580001);
      expect(json['latitude'], 25.281198);
      expect(json['longitude'], 82.953928);
      expect(json['gps_accuracy_m'], 22);
      expect(json['gps_unavailable_reason'], isNull);
      expect(json['captured_at'], '2026-10-25T04:44:55.571Z');
    });

    test('SampleSupportCreateResponse deserializes 201 Created server response', () {
      final apiResponse = {
        "message": "Sample support created successfully",
        "data": {
          "sample_id": 42,
          "sample_code": "SMP-26-0042",
          "volunteer_id": 4,
          "volunteer_name": "Test Volunteer",
          "cohv_type": "Public Health",
          "sample_type_id": 1,
          "sample_type_name": "Human samples",
          "sample_date": "2026-10-25",
          "sample_count": 2,
          "village_lgd_code": 580001,
          "village_name": "Achampet Village",
          "verification_status": "pending",
          "captured_at": "2026-10-25T04:44:55.572Z",
          "created_at": "2026-10-25T04:44:55.572Z",
        },
      };

      final response = SampleSupportCreateResponse.fromJson(apiResponse);
      expect(response.success, isTrue);
      expect(response.message, "Sample support created successfully");
      expect(response.sampleId, 42);
      expect(response.sampleCode, "SMP-26-0042");
      expect(response.sampleTypeName, "Human samples");
      expect(response.sampleCount, 2);
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

    testWidgets('Submitting form calls POST API with expected payload', (
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

      Map<String, dynamic>? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  returnedResult = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SampleSupportFormScreen(
                        apiService: mockApi,
                        initialVolunteerId: 'COHV-26-0004',
                      ),
                    ),
                  );
                },
                child: const Text('Open Form'),
              );
            },
          ),
        ),
      );

      // Open Form
      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      // Select Sample Type
      final sampleDropdown = find.byType(
        SearchableDropdownFormField<SampleTypeModel>,
      );
      await tester.tap(sampleDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Human samples'));
      await tester.pumpAndSettle();

      // Facilitated Count: change to 3
      final facilitatedFinder = find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller?.text == '1',
      );
      await tester.enterText(facilitatedFinder, '3');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      // Verify POST API was called with exact fields
      expect(mockApi.lastSubmittedRequest, isNotNull);
      final req = mockApi.lastSubmittedRequest!;
      expect(req.volunteerId, 4);
      expect(req.sampleTypeId, 1);
      expect(req.sampleCount, 3);
      expect(req.deviceId, 'DEV-WZU69XEL');
      expect(req.clientRef, startsWith('SMP-'));
      expect(req.sampleDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

      // Verify returned result to previous screen
      expect(returnedResult, isNotNull);
      expect(returnedResult!['sampleCode'], 'SMP-26-0005');
      expect(returnedResult!['numberFacilitated'], 3);
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

  group('SampleSupportRecordModel Deserialization & Formatting Tests', () {
    test('Deserializes API response from GET /api/sample-support correctly', () {
      final json = {
        "sample_id": 1,
        "sample_code": "SMP-26-0001",
        "volunteer_id": 52,
        "volunteer_name": "Abdul",
        "cohv_type": "Public Health Department",
        "department_name": "Public Health Department",
        "sample_type_id": 1,
        "sample_type_name": "Human samples",
        "sample_date": "2026-10-25",
        "sample_count": 1,
        "village_lgd_code": 90000004,
        "village_name": "Amrabad",
        "verification_status": "SUBMITTED",
        "captured_at": "2026-10-25T11:43:10.795770+05:30",
        "created_at": "2026-10-25T11:43:19.841491+05:30",
      };

      final record = SampleSupportRecordModel.fromJson(json);

      expect(record.sampleId, 1);
      expect(record.sampleCode, 'SMP-26-0001');
      expect(record.volunteerId, 52);
      expect(record.volunteerName, 'Abdul');
      expect(record.cohvType, 'Public Health Department');
      expect(record.departmentName, 'Public Health Department');
      expect(record.sampleTypeId, 1);
      expect(record.sampleTypeName, 'Human samples');
      expect(record.sampleDate, '2026-10-25');
      expect(record.sampleCount, 1);
      expect(record.villageLgdCode, 90000004);
      expect(record.villageName, 'Amrabad');
      expect(record.verificationStatus, 'SUBMITTED');

      // Test formatted values
      expect(record.formattedDate, '25 Oct 2026');
      expect(record.formattedVerificationStatus, 'Submitted');
      expect(record.formattedSyncStatus, 'Synced');
      expect(record.formattedGpsLocation, '28.583058, 77.370347 · ±58 m');
    });

    test('Custom GPS location and accuracy format as expected', () {
      final json = {
        "sample_id": 7,
        "sample_code": "SMP-26-0007",
        "sample_type_id": 1,
        "sample_type_name": "Human samples",
        "sample_date": "2026-10-24",
        "sample_count": 2,
        "village_name": "Mannanur",
        "latitude": 28.583058,
        "longitude": 77.370347,
        "gps_accuracy_m": 58,
      };

      final record = SampleSupportRecordModel.fromJson(json);
      expect(record.formattedDate, '24 Oct 2026');
      expect(record.formattedGpsLocation, '28.583058, 77.370347 · ±58 m');
      expect(record.sampleCount, 2);
    });
  });

  group('SampleSupportScreen Listing and Detail Screen Widget Tests', () {
    testWidgets('Listing screen renders cards matching Screenshot 1 and opens Detail Screen matching Screenshot 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRecords = [
        const SampleSupportRecordModel(
          sampleId: 1,
          sampleCode: 'SMP-26-0001',
          volunteerId: 52,
          volunteerName: 'Abdul',
          sampleTypeId: 1,
          sampleTypeName: 'Human samples',
          sampleDate: '2026-10-25',
          sampleCount: 1,
          villageLgdCode: 90000004,
          villageName: 'Amrabad',
          verificationStatus: 'SUBMITTED',
          syncStatus: 'synced',
        ),
      ];

      final mockApi = MockSampleSupportApiService(
        mockTypes: allMockTypes,
        mockVillages: mockVillages,
        mockRecords: testRecords,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SampleSupportScreen(
            apiService: mockApi,
            volunteerId: 'COHV-26-0004',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Header
      expect(find.text('Sample Support'), findsWidgets);

      // 2. Verify List Card elements matching Screenshot 1
      expect(find.text('Human samples'), findsOneWidget);
      expect(find.text('synced'), findsOneWidget);
      expect(find.text('1 facilitated'), findsOneWidget);
      expect(find.byKey(const ValueKey('add_sample_support_fab')), findsOneWidget);

      // 3. Tap on the card to open Detail Screen
      await tester.tap(find.text('Human samples'));
      await tester.pumpAndSettle();

      // 4. Verify Detail API was called with sampleId: 1
      expect(mockApi.lastDetailRequestedId, 1);

      // 5. Verify Detail Card elements matching Screenshot 2
      expect(find.text('SMP-26-0001'), findsOneWidget);
      expect(find.text('Sample type'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('25 Oct 2026'), findsOneWidget);
      expect(find.text('Number facilitated'), findsOneWidget);
      expect(find.text('Village / ward'), findsOneWidget);
      expect(find.text('Amrabad'), findsOneWidget);
      expect(find.text('Verification'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Synchronisation'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('GPS location'), findsOneWidget);
      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.text('DOC'), findsOneWidget);

      // 6. Verify Outlined Back Button and tap it
      final backBtnFinder = find.byKey(const ValueKey('sample_detail_back_button'));
      expect(backBtnFinder, findsOneWidget);
      await tester.tap(backBtnFinder);
      await tester.pumpAndSettle();

      // 7. Verify back on listing screen
      expect(find.byKey(const ValueKey('add_sample_support_fab')), findsOneWidget);
    });
  });
}
