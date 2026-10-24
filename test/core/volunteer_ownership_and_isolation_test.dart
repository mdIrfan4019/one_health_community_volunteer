import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
import 'package:cohv/features/awareness/presentation/screen/awareness_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. VolunteerOwnershipFilter Unit Tests (Fail-Closed & Isolation)', () {
    test('Correctly identifies matching numeric volunteer ID', () {
      final isOwned = VolunteerOwnershipFilter.isOwnedByVolunteer(
        recordNumericVolunteerId: 50,
        authNumericVolunteerId: 50,
        authVolunteerCode: 'COHV-26-0016',
      );
      expect(isOwned, isTrue);
    });

    test('Correctly identifies matching string volunteer code', () {
      final isOwned = VolunteerOwnershipFilter.isOwnedByVolunteer(
        recordVolunteerCode: 'COHV-26-0016',
        authVolunteerCode: 'COHV-26-0016',
      );
      expect(isOwned, isTrue);
    });

    test('Extracts numeric suffix from formatted volunteer code', () {
      expect(VolunteerOwnershipFilter.extractNumericSuffix('COHV-26-0016'), equals(16));
      expect(VolunteerOwnershipFilter.extractNumericSuffix('COHV-26-0005'), equals(5));
      expect(VolunteerOwnershipFilter.extractNumericSuffix('50'), equals(50));
      expect(VolunteerOwnershipFilter.extractNumericSuffix(''), isNull);
      expect(VolunteerOwnershipFilter.extractNumericSuffix(null), isNull);
    });

    test('Matches when record has numeric suffix matching auth volunteer code suffix', () {
      final isOwned = VolunteerOwnershipFilter.isOwnedByVolunteer(
        recordNumericVolunteerId: 16,
        authVolunteerCode: 'COHV-26-0016',
      );
      expect(isOwned, isTrue);
    });

    test('Rejects foreign records belonging to another volunteer in the SAME department', () {
      // Both volunteers are in Public Health department, but have different IDs
      const authVolunteerCode = 'COHV-26-0001';
      const foreignVolunteerCode = 'COHV-26-0002';

      final isOwned = VolunteerOwnershipFilter.isOwnedByVolunteer(
        recordVolunteerCode: foreignVolunteerCode,
        recordNumericVolunteerId: 2,
        authVolunteerCode: authVolunteerCode,
        authNumericVolunteerId: 1,
      );
      expect(isOwned, isFalse);
    });

    test('Rejects foreign records belonging to another volunteer in a DIFFERENT department', () {
      // Animal Department (id: 48) vs Urban Department (id: 50)
      const authVolunteerCode = 'COHV-26-0016';
      const foreignVolunteerCode = 'COHV-26-0001';

      final isOwned = VolunteerOwnershipFilter.isOwnedByVolunteer(
        recordVolunteerCode: foreignVolunteerCode,
        recordNumericVolunteerId: 48,
        authVolunteerCode: authVolunteerCode,
        authNumericVolunteerId: 50,
      );
      expect(isOwned, isFalse);
    });

    test('Rejects records across all six departments when volunteer identity differs', () {
      // 1. Public Health
      // 2. Animal
      // 3. Wildlife
      // 4. Environment
      // 5. Rural
      // 6. Urban
      final departments = [
        {'dept': 'Public Health', 'volCode': 'COHV-26-0001', 'volId': 10},
        {'dept': 'Animal', 'volCode': 'COHV-26-0002', 'volId': 20},
        {'dept': 'Wildlife', 'volCode': 'COHV-26-0003', 'volId': 30},
        {'dept': 'Environment', 'volCode': 'COHV-26-0004', 'volId': 40},
        {'dept': 'Rural', 'volCode': 'COHV-26-0005', 'volId': 50},
        {'dept': 'Urban', 'volCode': 'COHV-26-0006', 'volId': 60},
      ];

      for (int i = 0; i < departments.length; i++) {
        final current = departments[i];
        for (int j = 0; j < departments.length; j++) {
          if (i == j) continue;
          final other = departments[j];

          final isOwned = VolunteerOwnershipFilter.isOwnedByVolunteer(
            recordVolunteerCode: other['volCode'] as String,
            recordNumericVolunteerId: other['volId'] as int,
            authVolunteerCode: current['volCode'] as String,
            authNumericVolunteerId: current['volId'] as int,
          );
          expect(isOwned, isFalse, reason: '${current['dept']} saw record from ${other['dept']}');
        }
      }
    });

    test('Fail-closed security: Missing or ambiguous ownership fields are rejected', () {
      final isOwnedMissing = VolunteerOwnershipFilter.isOwnedByVolunteer(
        recordVolunteerCode: null,
        recordNumericVolunteerId: null,
        recordVolunteerId: null,
        authVolunteerCode: 'COHV-26-0016',
        authNumericVolunteerId: 50,
      );
      expect(isOwnedMissing, isFalse);
    });

    test('Fail-closed security: Missing authenticated session identity rejects all records', () {
      final isOwnedNoSession = VolunteerOwnershipFilter.isOwnedByVolunteer(
        recordVolunteerCode: 'COHV-26-0016',
        recordNumericVolunteerId: 50,
        authVolunteerCode: null,
        authNumericVolunteerId: null,
      );
      expect(isOwnedNoSession, isFalse);
    });
  });

  group('2. Domain Model Parsing & Dynamic Ownership Mapping', () {
    test('EventReportItem parses volunteer ownership fields dynamically from JSON', () {
      final json = {
        'id': 'VISIT-26-0099',
        'event_id': 99,
        'volunteer_id': 50,
        'volunteer_code': 'COHV-26-0016',
        'volunteer_name': 'Urban Volunteer',
        'event_type': 'Suspected Outbreak',
        'primary_sector': 'Urban Health',
        'date': '2026-10-25T10:00:00Z',
        'village': 'Sector 4',
        'status': 'synced',
      };

      final item = EventReportItem.fromJson(json);
      expect(item.numericVolunteerId, equals(50));
      expect(item.volunteerId, equals('COHV-26-0016'));
      expect(item.volunteerName, equals('Urban Volunteer'));
    });

    test('ReferralItem parses ownership fields without falling back to hardcoded volunteer', () {
      final json = {
        'id': 'REF-26-0099',
        'referral_id': 99,
        'volunteer_id': 50,
        'volunteer_code': 'COHV-26-0016',
        'volunteer_name': 'Urban Volunteer',
        'suspected_disease': 'Dengue',
        'symptoms': 'High fever',
        'created_at': '2026-10-25T10:00:00Z',
        'status': 'Pending',
      };

      final item = ReferralItem.fromJson(json);
      expect(item.numericVolunteerId, equals(50));
      expect(item.volunteerCode, equals('COHV-26-0016'));
      expect(item.volunteerName, equals('Urban Volunteer'));
    });

    test('AwarenessItem parses ownership fields without falling back to hardcoded volunteer', () {
      final json = {
        'id': 'AWR-26-0099',
        'awareness_id': 99,
        'volunteer_id': 50,
        'volunteer_code': 'COHV-26-0016',
        'volunteer_name': 'Urban Volunteer',
        'activity_type': 'Community Workshop',
        'date': '2026-10-25T10:00:00Z',
        'village': 'Sector 4',
        'people_reached': 25,
        'topic_covered': 'Sanitation',
        'department_involved': 'Urban Department',
        'latitude': 28.5,
        'longitude': 77.2,
        'accuracy': 10.0,
        'device_id': 'TEST_DEVICE',
      };

      final item = AwarenessItem.fromJson(json);
      expect(item.numericVolunteerId, equals(50));
      expect(item.volunteerCode, equals('COHV-26-0016'));
      expect(item.volunteerName, equals('Urban Volunteer'));
    });
  });

  group('3. Volunteer-Scoped Session and Cache Isolation', () {
    test('Scoped storage isolates records between Volunteer A and Volunteer B', () async {
      const volA = 'COHV-26-0001';
      const volB = 'COHV-26-0002';

      final eventA = EventReportItem(
        id: 'VISIT-A-001',
        volunteerId: volA,
        numericVolunteerId: 1,
        eventType: 'Flu Outbreak',
        primarySector: 'Public Health',
        eventDate: DateTime(2026, 10, 25),
        village: 'Village A',
      );

      final eventB = EventReportItem(
        id: 'VISIT-B-001',
        volunteerId: volB,
        numericVolunteerId: 2,
        eventType: 'Rabies Alert',
        primarySector: 'Animal Health',
        eventDate: DateTime(2026, 10, 25),
        village: 'Village B',
      );

      // Save events for Volunteer A
      await SessionManager.saveSubmittedEventsList([eventA], volunteerId: volA, numericVolunteerId: 1);

      // Query as Volunteer A: should see eventA only
      final listForA = await SessionManager.getSubmittedEvents(volunteerId: volA, numericVolunteerId: 1);
      expect(listForA.length, equals(1));
      expect(listForA.first.id, equals('VISIT-A-001'));

      // Query as Volunteer B: should see empty list (0 events from Volunteer A)
      final listForB = await SessionManager.getSubmittedEvents(volunteerId: volB, numericVolunteerId: 2);
      expect(listForB, isEmpty);

      // Save events for Volunteer B
      await SessionManager.saveSubmittedEventsList([eventB], volunteerId: volB, numericVolunteerId: 2);

      // Now B sees only eventB, A sees only eventA
      final updatedB = await SessionManager.getSubmittedEvents(volunteerId: volB, numericVolunteerId: 2);
      expect(updatedB.length, equals(1));
      expect(updatedB.first.id, equals('VISIT-B-001'));

      final updatedA = await SessionManager.getSubmittedEvents(volunteerId: volA, numericVolunteerId: 1);
      expect(updatedA.length, equals(1));
      expect(updatedA.first.id, equals('VISIT-A-001'));
    });

    test('clearSession purges active credentials and listings', () async {
      const volA = 'COHV-26-0001';
      final eventA = EventReportItem(
        id: 'VISIT-A-001',
        volunteerId: volA,
        numericVolunteerId: 1,
        eventType: 'Flu Outbreak',
        primarySector: 'Public Health',
        eventDate: DateTime(2026, 10, 25),
        village: 'Village A',
      );

      await SessionManager.saveSubmittedEventsList([eventA], volunteerId: volA, numericVolunteerId: 1);
      await SessionManager.clearSession();

      final listAfterClear = await SessionManager.getSubmittedEvents(volunteerId: volA, numericVolunteerId: 1);
      expect(listAfterClear, isEmpty);
    });
  });

  group('4. Listing Screens Display Isolation Widget Tests', () {
    testWidgets('EventReportsListScreen renders empty state when no events belong to volunteer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventReportsListScreen(
              volunteerId: 'COHV-26-0016',
              isStandalone: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No events reported yet.'), findsOneWidget);
      expect(find.text('Use Report Event to file one.'), findsOneWidget);
    });

    testWidgets('ReferralsListScreen renders empty state when no referrals belong to volunteer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReferralsListScreen(
              volunteerId: 'COHV-26-0016',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No referrals recorded yet.'), findsOneWidget);
    });

    testWidgets('AwarenessListScreen renders empty state when no activities belong to volunteer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AwarenessListScreen(
              volunteerId: 'COHV-26-0016',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No awareness activities recorded yet.'), findsOneWidget);
    });
  });
}
