import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EventReportsListScreen & Actions Workflow Widget Tests', () {
    testWidgets('Displays clean empty screen state when no events exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventReportsListScreen(
              volunteerId: 'COHV-26-0005',
              isStandalone: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Empty state container matching Image 2 reference screenshot
      expect(find.text('No events reported yet.'), findsOneWidget);
      expect(find.text('Use Report Event to file one.'), findsOneWidget);

      // Floating Action Button is visible on bottom right
      expect(find.byKey(const ValueKey('report_event_fab')), findsOneWidget);
      expect(find.text('Report Event'), findsOneWidget);

      // Global Notification and Synchronisation header buttons in AppBar
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);
    });

    testWidgets(
      'Renders submitted event cards when events are saved in SessionManager',
      (tester) async {
        final sampleEvents = [
          EventReportItem(
            id: 'VISIT-26-0011',
            volunteerId: 'COHV-26-0005',
            eventType: 'Animal-borne disease events',
            primarySector: 'Human Health',
            eventDate: DateTime(2026, 10, 13, 11, 33),
            village: 'Rampur',
            status: 'synced',
            isAlert: false,
            isFollowUp: true,
            verificationStatus: 'Submitted',
            totalVisits: 1,
            targetPopulation: 'General population',
            observations: 'Suspected fever cluster observed in domestic zone.',
            actionTaken: 'Notified local surveillance team.',
          ),
          EventReportItem(
            id: 'VISIT-26-0002',
            volunteerId: 'COHV-26-0005',
            eventType: 'Chemical exposure',
            primarySector: 'Human Health',
            eventDate: DateTime(2026, 10, 13, 10, 8),
            village: 'Amrabad',
            status: 'synced',
            isAlert: true,
            isFollowUp: true,
            verificationStatus: 'Submitted',
            totalVisits: 1,
            targetPopulation: 'General population',
            observations: 'Acute irritant exposure reported near local stream.',
            actionTaken: 'Advised protective measures and reported to CHC.',
          ),
        ];

        await SessionManager.saveSubmittedEventsList(sampleEvents);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EventReportsListScreen(volunteerId: 'COHV-26-0005'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check event titles
        expect(find.text('Animal-borne disease events'), findsOneWidget);
        expect(find.text('Chemical exposure'), findsOneWidget);

        // Check report IDs
        expect(
          find.textContaining('VISIT-26-0011', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('VISIT-26-0002', findRichText: true),
          findsOneWidget,
        );

        // Check badges
        expect(find.text('synced'), findsNWidgets(2));
        expect(find.text('alert'), findsOneWidget);

        // Check Report Event FAB exists
        expect(find.byKey(const ValueKey('report_event_fab')), findsOneWidget);
        expect(find.text('Report Event'), findsOneWidget);
      },
    );

    testWidgets('Tapping an event card opens event details bottom sheet', (
      tester,
    ) async {
      final sampleEvent = EventReportItem(
        id: 'VISIT-26-0011',
        volunteerId: 'COHV-26-0005',
        eventType: 'Animal-borne disease events',
        primarySector: 'Human Health',
        eventDate: DateTime(2026, 10, 13, 11, 33),
        village: 'Rampur',
        status: 'synced',
        isAlert: false,
        isFollowUp: true,
        verificationStatus: 'Submitted',
        totalVisits: 1,
        targetPopulation: 'General population',
        observations: 'Suspected fever cluster observed in domestic zone.',
        actionTaken: 'Notified local surveillance team.',
      );

      await SessionManager.saveSubmittedEventsList([sampleEvent]);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventReportsListScreen(volunteerId: 'COHV-26-0005'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the event card
      await tester.tap(find.text('Animal-borne disease events'));
      await tester.pumpAndSettle();

      // Details screen should show observations and action taken
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Observations'), findsOneWidget);
      expect(find.text('Immediate action taken'), findsOneWidget);

      // Close / Back button
      await tester.ensureVisible(find.text('Back'));
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsNothing);
    });

    testWidgets(
      'DashboardScreen Actions tab displays 6 action cards and navigates to Event Reports',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: DashboardScreen(
              volunteerId: 'COHV-26-0013',
              volunteerName: 'Ramu',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially on Dashboard
        expect(find.text('Dashboard'), findsWidgets);

        // Tap on Actions tab (index 1) in BottomNavigationBar
        await tester.tap(find.byIcon(Icons.grid_view_rounded));
        await tester.pumpAndSettle();

        // Title should now be 'Quick Actions'
        expect(find.text('Quick Actions'), findsOneWidget);

        // All 6 action cards must be present
        expect(find.text('Report Event'), findsOneWidget);
        expect(find.text('Referral'), findsOneWidget);
        expect(find.text('Awareness Activity'), findsOneWidget);
        expect(find.text('Sample Support'), findsOneWidget);
        expect(find.text('Capacity Building'), findsOneWidget);
        expect(find.text('Success Stories'), findsOneWidget);

        // Tap on 'Report Event' card
        await tester.tap(find.text('Report Event'));
        await tester.pumpAndSettle();

        // Navigates to Event Reports screen
        expect(find.text('Event Reports'), findsOneWidget);

        // Empty state visible when no reports have been submitted
        expect(find.text('No events reported yet.'), findsOneWidget);
        expect(find.text('Use Report Event to file one.'), findsOneWidget);

        // Report Event FAB is visible
        expect(find.byKey(const ValueKey('report_event_fab')), findsOneWidget);

        // Tap back button in AppBar to return to Quick Actions
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        // Should be back on Quick Actions screen
        expect(find.text('Quick Actions'), findsOneWidget);
      },
    );

    testWidgets(
      'Sample Support card navigates to Sample Support listing with empty state and FAB',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: DashboardScreen(
              volunteerId: 'COHV-26-0013',
              volunteerName: 'Ramu',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on Actions tab
        await tester.tap(find.byIcon(Icons.grid_view_rounded));
        await tester.pumpAndSettle();

        // Tap on 'Sample Support' card
        await tester.ensureVisible(find.text('Sample Support'));
        await tester.tap(find.text('Sample Support'));
        await tester.pumpAndSettle();

        // Navigates to Sample Support screen
        expect(find.text('Sample Support'), findsWidgets);
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);

        // Tap back button to return to Quick Actions
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Quick Actions'), findsOneWidget);
      },
    );

    test('EventReportItem.fromJson correctly maps sector_code: human to Public Health instead of Animal Health', () {
      final jsonHuman = {
        'event_report_id': 23,
        'event_report_code': 'VISIT-26-0009',
        'event_type_id': 2,
        'event_type_name': 'Human disease clusters',
        'sector_code': 'human',
        'population_type_id': 1,
        'population_type_name': 'General population',
        'event_date': '2026-10-25',
        'event_time': '02:28:00',
        'verification_status': 'SUBMITTED',
      };

      final itemHuman = EventReportItem.fromJson(jsonHuman);
      expect(itemHuman.primarySector, 'Public Health');
      expect(itemHuman.sectorCode, 'human');

      // Test animal mapping
      final jsonAnimal = {
        'event_report_id': 25,
        'event_report_code': 'VISIT-26-0012',
        'event_type_name': 'Unusual livestock morbidity',
        'sector_code': 'animal',
        'verification_status': 'SUBMITTED',
      };
      final itemAnimal = EventReportItem.fromJson(jsonAnimal);
      expect(itemAnimal.primarySector, 'Animal Health');
      expect(itemAnimal.sectorCode, 'animal');

      // Test environment mapping
      final jsonEnv = {
        'event_report_id': 19,
        'event_report_code': 'VISIT-26-0006',
        'event_type_name': 'Chemical exposure',
        'sector_code': 'environment',
        'verification_status': 'SUBMITTED',
      };
      final itemEnv = EventReportItem.fromJson(jsonEnv);
      expect(itemEnv.primarySector, 'Environment');
      expect(itemEnv.sectorCode, 'environment');

      // Test inference from human disease event type when sector_code is null
      final jsonInferred = {
        'event_report_id': 24,
        'event_report_code': 'VISIT-26-0010',
        'event_type_name': 'Human disease clusters',
        'verification_status': 'SUBMITTED',
      };
      final itemInferred = EventReportItem.fromJson(jsonInferred);
      expect(itemInferred.primarySector, 'Public Health');
    });

    testWidgets(
      'Event report card displays Public Health · Submitted for human health events',
      (tester) async {
        final sampleEvent = EventReportItem(
          id: 'VISIT-26-0009',
          volunteerId: 'COHV-26-0005',
          eventType: 'Human disease clusters',
          primarySector: 'Public Health',
          eventDate: DateTime(2026, 10, 25, 2, 29),
          village: 'Achampet',
          status: 'synced',
          isAlert: false,
          isFollowUp: false,
          verificationStatus: 'Submitted',
          totalVisits: 1,
          targetPopulation: 'General population',
        );

        await SessionManager.saveSubmittedEventsList([sampleEvent]);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EventReportsListScreen(volunteerId: 'COHV-26-0005'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check card title and code
        expect(find.text('Human disease clusters'), findsOneWidget);
        expect(find.textContaining('VISIT-26-0009', findRichText: true), findsOneWidget);

        // Subtitle row must show Public Health · Submitted (NOT Animal Health)
        expect(find.text('Public Health · Submitted'), findsOneWidget);
        expect(find.textContaining('Animal Health'), findsNothing);
      },
    );
  });
}
