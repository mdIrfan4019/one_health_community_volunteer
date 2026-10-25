import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reporting_screen.dart';
import 'package:cohv/features/reports/presentation/screen/reports_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthenticatedNavigation.resetLock();
  });

  group('DashboardScreen Redesign & Interaction Tests', () {
    testWidgets('Renders SETU FIELDSPACE hero card, field activity snapshot, and metric cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Alex',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. App Bar
      expect(find.text('Dashboard'), findsWidgets); // Title and Nav item

      // 2. SETU Fieldspace Hero Card
      expect(find.text('SETU FIELDSPACE'), findsOneWidget);
      expect(find.text('Good day, Alex 👋'), findsOneWidget);
      expect(find.text('Small actions. Healthier communities.'), findsOneWidget);
      expect(find.text('Public Health Department'), findsOneWidget);
      expect(find.text('Mannanur · Amrabad · Nagarkurnool'), findsOneWidget);
      expect(find.text('Report an event'), findsOneWidget);
      expect(find.text('Capture a field observation'), findsOneWidget);

      // 3. Snapshot section
      expect(find.text('YOUR SNAPSHOT'), findsOneWidget);
      expect(find.text('Field activity'), findsOneWidget);
      expect(find.text('View reports'), findsOneWidget);

      // 4. Metric cards
      expect(find.text('Total visits'), findsOneWidget);
      expect(find.text('Alerts generated'), findsOneWidget);
      expect(find.text('Referrals'), findsOneWidget);
      expect(find.text('Pending follow-ups'), findsOneWidget);
      expect(find.text('Awareness activities'), findsOneWidget);
      expect(find.text('Trainings imparted'), findsOneWidget);
      expect(find.text('Trainings attended'), findsOneWidget);
      expect(find.text('Data pending for synchronization'), findsOneWidget);

      // 5. Field location card
      expect(find.text('Field location'), findsOneWidget);
      expect(find.text('28.584065, 77.371091'), findsOneWidget);
      expect(find.text('Capture'), findsOneWidget);
      expect(
        find.text('Connected · reports save locally before sync'),
        findsOneWidget,
      );

      // 6. Bottom Navigation Bar
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Clicking "Report an event" opens EventReportingScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Alex',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reportAnEventBtn = find.text('Report an event');
      expect(reportAnEventBtn, findsOneWidget);

      await tester.tap(reportAnEventBtn);
      await tester.pumpAndSettle();

      // EventReportingScreen is now open
      expect(find.byType(EventReportingScreen), findsOneWidget);
    });

    testWidgets('Clicking "View reports" navigates to Reports tab screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Alex',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final viewReportsBtn = find.text('View reports');
      expect(viewReportsBtn, findsOneWidget);

      await tester.tap(viewReportsBtn);
      await tester.pumpAndSettle();

      // Third tab ReportsScreen is now active
      expect(find.byType(ReportsScreen), findsOneWidget);
      // App bar title updates to 'Reports'
      expect(find.widgetWithText(AppBar, 'Reports'), findsOneWidget);

      // Drain ReportsScreen history timer
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Tapping bottom nav tabs switches screens smoothly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Alex',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Actions tab
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Quick Actions'), findsOneWidget);

      // Tap Reports tab
      await tester.tap(find.byIcon(Icons.article_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(ReportsScreen), findsOneWidget);

      // Tap Dashboard tab to return
      await tester.tap(find.byIcon(Icons.home_rounded));
      await tester.pumpAndSettle();
      expect(find.text('SETU FIELDSPACE'), findsOneWidget);

      // Drain any pending timers
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
