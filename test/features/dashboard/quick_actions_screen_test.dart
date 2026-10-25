import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/dashboard/presentation/screen/quick_actions_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
import 'package:cohv/features/sample_reprot/screens/sample_support_screen.dart';
import 'package:cohv/features/capacity_building/capacity_building_screen.dart';
import 'package:cohv/features/success_stories/screens/success_stories_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuickActionsScreen UI Redesign Tests', () {
    testWidgets('Renders Toolkit hero card, Start Here section, 5 action cards, and offline banner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsScreen(volunteerId: 'COHV-26-0013'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Toolkit Hero Card
      expect(find.text('YOUR FIELD TOOLKIT'), findsOneWidget);
      expect(find.text('People first'), findsOneWidget);
      expect(find.text('Capture health concerns and community needs.'), findsOneWidget);
      expect(find.text('Ready when you are'), findsOneWidget);

      // 2. Start Here Section
      expect(find.text('START HERE'), findsOneWidget);
      expect(find.text('01 / QUICK CAPTURE'), findsOneWidget);
      expect(find.text('Report an event'), findsOneWidget);
      expect(find.text('Open this field workflow'), findsOneWidget);

      // 3. More Ways to Help Section
      expect(find.text('MORE WAYS TO HELP'), findsOneWidget);
      expect(find.text('05 ACTIONS'), findsOneWidget);

      // 5 Action cards with their respective subtitles
      expect(find.text('Referral'), findsOneWidget);
      expect(find.text('Connect someone to care'), findsOneWidget);

      expect(find.text('Awareness Activity'), findsOneWidget);
      expect(find.text('Share useful information'), findsOneWidget);

      expect(find.text('Sample Support'), findsOneWidget);
      expect(find.text('Track sample collection'), findsOneWidget);

      expect(find.text('Capacity Building'), findsOneWidget);
      expect(find.text('Record learning and training'), findsOneWidget);

      expect(find.text('Success Stories'), findsOneWidget);
      expect(find.text('Capture a positive change'), findsOneWidget);

      // 4. Offline banner
      expect(find.text('Out in the field?'), findsOneWidget);
      expect(
        find.text('Your work can be saved offline and synced when you reconnect.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping "Report an event" navigates to EventReportsListScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsScreen(volunteerId: 'COHV-26-0013'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Report an event'));
      await tester.pumpAndSettle();

      expect(find.byType(EventReportsListScreen), findsOneWidget);
    });

    testWidgets('Tapping "Referral" navigates to ReferralsListScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsScreen(volunteerId: 'COHV-26-0013'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Referral'));
      await tester.pumpAndSettle();

      expect(find.byType(ReferralsListScreen), findsOneWidget);
    });

    testWidgets('Tapping "Sample Support" navigates to SampleSupportScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsScreen(volunteerId: 'COHV-26-0013'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sample Support'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sample Support'));
      await tester.pumpAndSettle();

      expect(find.byType(SampleSupportScreen), findsOneWidget);
    });

    testWidgets('Tapping "Capacity Building" navigates to CapacityBuildingScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsScreen(volunteerId: 'COHV-26-0013'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Capacity Building'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Capacity Building'));
      await tester.pumpAndSettle();

      expect(find.byType(CapacityBuildingScreen), findsOneWidget);
    });

    testWidgets('Tapping "Success Stories" navigates to SuccessStoriesScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsScreen(volunteerId: 'COHV-26-0013'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Success Stories'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Success Stories'));
      await tester.pumpAndSettle();

      expect(find.byType(SuccessStoriesScreen), findsOneWidget);
    });
  });
}
