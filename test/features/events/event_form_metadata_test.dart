import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/events/data/event_api_service.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/events/presentation/screen/event_reporting_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockMetadataJson = {
    "primary_sector": {
      "sector_code": "human",
      "sector_name": "Human Health"
    },
    "event_types": [
      {
        "id": 1,
        "name": "Suspected disease outbreaks",
        "is_other": false
      },
      {
        "id": 2,
        "name": "Human disease clusters",
        "is_other": false
      },
      {
        "id": 5,
        "name": "Food poisoning events",
        "is_other": false
      },
      {
        "id": 68,
        "name": "Other",
        "is_other": true
      }
    ],
    "population": {
      "label": "Human Population",
      "options": [
        {
          "id": 1,
          "name": "General population",
          "is_other": false
        },
        {
          "id": 2,
          "name": "Children (under 5)",
          "is_other": false
        },
        {
          "id": 7,
          "name": "Other",
          "is_other": true
        }
      ]
    },
    "location_types": [
      "Urban",
      "Rural"
    ],
    "villages": [
      {
        "village_lgd_code": 90000007,
        "village_name": "Achampet",
        "gram_panchayat_name": "Achampet",
        "block_name": "Achampeta"
      },
      {
        "village_lgd_code": 90000004,
        "village_name": "Amrabad",
        "gram_panchayat_name": "Amrabad",
        "block_name": "Amrabad"
      }
    ],
    "upload_limits": {
      "photos": {
        "max": 5,
        "mb": 5,
        "label": "Photographs"
      },
      "videos": {
        "max": 2,
        "mb": 25,
        "label": "Videos"
      },
      "documents": {
        "max": 4,
        "mb": 10,
        "label": "Documents"
      }
    },
    "min_date": "2026-10-03",
    "max_date": "2026-10-17"
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EventFormMetadata Domain Models', () {
    test('Correctly parses backend JSON structure from /api/events/form-metadata', () {
      final metadata = EventFormMetadata.fromJson(mockMetadataJson);

      expect(metadata.primarySector.sectorCode, 'human');
      expect(metadata.primarySector.sectorName, 'Human Health');

      expect(metadata.eventTypes.length, 4);
      expect(metadata.eventTypes[0].name, 'Suspected disease outbreaks');
      expect(metadata.eventTypes[3].name, 'Other');
      expect(metadata.eventTypes[3].isOther, true);

      expect(metadata.population.label, 'Human Population');
      expect(metadata.population.options.length, 3);
      expect(metadata.population.options[2].isOther, true);

      expect(metadata.locationTypes, ['Urban', 'Rural']);

      expect(metadata.villages.length, 2);
      expect(metadata.villages[0].villageName, 'Achampet');
      expect(metadata.villages[0].villageLgdCode, 90000007);
      expect(metadata.villages[1].blockName, 'Amrabad');

      expect(metadata.uploadLimits.photos.max, 5);
      expect(metadata.uploadLimits.photos.mb, 5);
      expect(metadata.uploadLimits.videos.max, 2);
      expect(metadata.uploadLimits.documents.max, 4);

      expect(metadata.minDate, '2026-10-03');
      expect(metadata.maxDate, '2026-10-17');
      expect(metadata.minDateTime, DateTime(2026, 10, 3));
      expect(metadata.maxDateTime, DateTime(2026, 10, 17));
    });

    test('Fallback metadata provides complete defaults matching schema', () {
      final fallback = EventFormMetadata.fallback();
      expect(fallback.eventTypes.isNotEmpty, true);
      expect(fallback.villages.isNotEmpty, true);
      expect(fallback.population.options.isNotEmpty, true);
      expect(fallback.locationTypes.contains('Urban'), true);
      expect(fallback.locationTypes.contains('Rural'), true);
    });
  });

  group('EventApiService and SessionManager Cache', () {
    test('Caches metadata locally in SessionManager and retrieves successfully', () async {
      await SessionManager.saveEventFormMetadata(mockMetadataJson);

      final cached = await SessionManager.getEventFormMetadata();
      expect(cached != null, true);
      expect(cached!['primary_sector']['sector_name'], 'Human Health');
    });

    test('EventApiService.getEventFormMetadata handles HTTP 200 with Bearer token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), ApiConstants.endpointEventFormMetadata);
        expect(request.headers['Accept'], 'application/json');
        return http.Response(jsonEncode(mockMetadataJson), 200);
      });

      final service = EventApiService(client: mockClient);
      final metadata = await service.getEventFormMetadata(forceRefresh: true);

      expect(metadata.primarySector.sectorName, 'Human Health');
      expect(metadata.eventTypes.length, 4);
      expect(metadata.villages.length, 2);

      // Verify that SessionManager cached the response
      final cached = await SessionManager.getEventFormMetadata();
      expect(cached, isNotNull);
    });

    test('EventApiService returns cached data or fallback on network failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = EventApiService(client: mockClient);
      final metadata = await service.getEventFormMetadata(forceRefresh: true);

      // Should return fallback when server fails and cache is empty
      expect(metadata.eventTypes.isNotEmpty, true);
      expect(metadata.villages.isNotEmpty, true);
    });

    test('EventApiService.submitEventReport posts multipart form data with Bearer token', () async {
      await SessionManager.saveSession(
        UserSession(
          token: 'mock_bearer_jwt_token',
          volunteerId: 'COHV-26-0005',
          fullName: 'Rajan',
          mobile: '9568452369',
          email: 'rajan123@gmail.com',
          sector: 'Human Health',
          status: 'ACTIVE',
        ),
      );

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), ApiConstants.endpointEvents);
        expect(request.headers['Authorization'], 'Bearer mock_bearer_jwt_token');

        final responseJson = {
          "message": "Event report submitted successfully.",
          "event_report_id": 15,
          "event_report_code": "EVT-26-0015",
          "verification_status": "PENDING",
          "alert_code": "ALT-26-0004",
          "attachments": 1,
          "duplicate": false
        };

        return http.Response(jsonEncode(responseJson), 201);
      });

      final service = EventApiService(client: mockClient);
      final request = EventReportRequest(
        eventTypeId: 1,
        eventType: 'Suspected disease outbreaks',
        primarySector: 'Human Health',
        primarySectorCode: 'human',
        date: DateTime(2026, 10, 17),
        time: '14:30:00',
        villageLgdCode: 90000004,
        village: 'Amrabad',
        gramPanchayat: 'Amrabad',
        blockName: 'Amrabad',
        isOutOfAreaVisit: false,
        purposeOfVisit: 'Routine household surveillance',
        locationType: 'Urban',
        totalVisits: 5,
        populationTypeId: 1,
        targetPopulation: 'General population',
        observations: 'Three individuals with high-grade fever.',
        actionTaken: 'Advised isolation and informed CHC supervisor.',
        description: 'Photo of household visit',
        isReferralGenerated: true,
        isAlertGenerated: true,
        isFollowUpRequired: true,
        latitude: 28.60928,
        longitude: 77.367449,
        accuracy: 18,
        volunteerId: 'COHV-26-0005',
        deviceId: 'DEV-C0YBZ9WK',
      );

      final result = await service.submitEventReport(request);

      expect(result.reportId, 'EVT-26-0015');
      expect(result.eventReportId, 15);
      expect(result.verificationStatus, 'PENDING');
      expect(result.alertId, 'ALT-26-0004');
      expect(result.status, 'synced');
    });

    test('EventApiService.submitEventReport queues offline when network fails', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = EventApiService(client: mockClient);
      final request = EventReportRequest(
        eventTypeId: 2,
        eventType: 'Human disease clusters',
        primarySector: 'Human Health',
        date: DateTime(2026, 10, 17),
        time: '10:00:00',
        villageLgdCode: 90000004,
        village: 'Amrabad',
        isOutOfAreaVisit: false,
        purposeOfVisit: 'Investigate cluster',
        locationType: 'Rural',
        totalVisits: 2,
        populationTypeId: 2,
        targetPopulation: 'Children (under 5)',
        observations: 'Two children with rash.',
        actionTaken: 'Notified supervisor.',
        isReferralGenerated: false,
        isAlertGenerated: false,
        isFollowUpRequired: true,
        latitude: 28.60928,
        longitude: 77.367449,
        accuracy: 25,
        volunteerId: 'COHV-26-0005',
        deviceId: 'DEV-C0YBZ9WK',
      );

      final result = await service.submitEventReport(request);

      expect(result.status, 'queued_offline');
      expect(result.reportId.startsWith('OFFLINE-EVT-'), true);
      expect(result.message.contains('saved locally'), true);
    });
  });

  group('EventReportingScreen Dynamic Rendering Widget Test', () {
    testWidgets('Renders dynamic event dropdowns, villages, and population from metadata', (tester) async {
      // Pre-seed SessionManager with mock metadata
      await SessionManager.saveEventFormMetadata(mockMetadataJson);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventReportingScreen(volunteerId: 'COHV-26-0005'),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Event Reporting'), findsOneWidget);

      // Verify Dynamic Primary Sector
      expect(find.text('Human Health'), findsOneWidget);
      expect(find.text('HUMAN'), findsOneWidget);

      // Verify Dynamic Target Population label from backend
      expect(find.text('Human Population *'), findsOneWidget);

      // Verify Upload Limits text is dynamically generated
      expect(find.textContaining('Up to 5 photographs (5 MB each)'), findsOneWidget);
    });

    testWidgets('Opens searchable event dropdown, filters items, and selects option', (tester) async {
      await SessionManager.saveEventFormMetadata(mockMetadataJson);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventReportingScreen(volunteerId: 'COHV-26-0005'),
        ),
      );

      await tester.pumpAndSettle();

      // Find the 'Select event type' dropdown field
      final eventDropdownFinder = find.widgetWithText(TextFormField, 'Select event type');
      expect(eventDropdownFinder, findsOneWidget);

      // Tap to focus and open inline overlay
      await tester.tap(eventDropdownFinder);
      await tester.pumpAndSettle();

      // Verify options appear in the floating overlay
      expect(find.text('Suspected disease outbreaks'), findsOneWidget);
      expect(find.text('Human disease clusters'), findsOneWidget);

      // Filter by typing 'clusters' directly in the field
      await tester.enterText(eventDropdownFinder, 'clusters');
      await tester.pumpAndSettle();

      expect(find.text('Human disease clusters'), findsOneWidget);
      expect(find.text('Suspected disease outbreaks'), findsNothing);

      // Select 'Human disease clusters'
      await tester.tap(find.text('Human disease clusters'));
      await tester.pumpAndSettle();

      // The selected value should now be rendered on the form field
      expect(find.text('Human disease clusters'), findsOneWidget);
    });
  });
}
