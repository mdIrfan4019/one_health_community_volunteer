import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EventReportsListScreen Widget Tests', () {
    testWidgets('Renders submitted event cards with prototype details and badges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventReportsListScreen(volunteerId: 'COHV-26-0005'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check event titles from prototype reference image
      expect(find.text('Animal-borne disease events'), findsOneWidget);
      expect(find.text('Chemical exposure'), findsOneWidget);

      // Check report IDs
      expect(find.textContaining('VISIT-26-0011', findRichText: true), findsOneWidget);
      expect(find.textContaining('VISIT-26-0002', findRichText: true), findsOneWidget);

      // Check badges
      expect(find.text('synced'), findsNWidgets(2));
      expect(find.text('alert'), findsOneWidget);

      // Check Report Event FAB exists
      expect(find.byKey(const ValueKey('report_event_fab')), findsOneWidget);
      expect(find.text('Report Event'), findsOneWidget);
    });

    testWidgets('Tapping an event card opens event details bottom sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventReportsListScreen(volunteerId: 'COHV-26-0005'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the first card
      await tester.tap(find.text('Animal-borne disease events'));
      await tester.pumpAndSettle();

      // Details bottom sheet should show observations and action taken
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Observations:'), findsOneWidget);
      expect(find.text('Action Taken:'), findsOneWidget);

      // Close bottom sheet
      await tester.ensureVisible(find.text('Close'));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
    });

    testWidgets('Displays clean empty screen state when no events exist', (tester) async {
      final key = GlobalKey<EventReportsListScreenState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventReportsListScreen(
              key: key,
              volunteerId: 'COHV-26-0005',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear events to simulate zero submitted events
      key.currentState?.clearEvents();
      await tester.pumpAndSettle();

      // Empty state should be visible
      expect(find.text('No Event Reports Yet'), findsOneWidget);
      expect(find.text('Report First Event'), findsOneWidget);

      // Floating Action Button is still visible on bottom right
      expect(find.byKey(const ValueKey('report_event_fab')), findsOneWidget);
    });

    testWidgets('DashboardScreen Actions tab switches to Event Reports screen with Report Event button', (tester) async {
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

      // Title should now be 'Event Reports'
      expect(find.text('Event Reports'), findsOneWidget);

      // Back button should appear in AppBar
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Event Reports list and FAB are visible
      expect(find.text('Animal-borne disease events'), findsOneWidget);
      expect(find.byKey(const ValueKey('report_event_fab')), findsOneWidget);

      // Tap back button to return to Dashboard
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsWidgets);
    });
  });
}
