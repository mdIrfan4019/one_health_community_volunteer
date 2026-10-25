import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:cohv/features/notifications/presentation/screen/notifications_screen.dart';
import 'package:cohv/features/sync/presentation/screen/sync_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
import 'package:cohv/features/awareness/presentation/screen/awareness_list_screen.dart';
import 'package:cohv/features/auth/presentation/screens/sign_in_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthenticatedNavigation.resetLock();
  });

  group('Global Authenticated Header & Navigation Verification Tests', () {
    testWidgets('Header icons appear on Dashboard tab with no fake badges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Asha Worker',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title shows Dashboard in AuthenticatedAppBar
      expect(
        find.descendant(of: find.byType(AuthenticatedAppBar), matching: find.text('Dashboard')),
        findsOneWidget,
      );

      // Notification and Synchronisation buttons are present in the header
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);

      // Verify no fake badges ('1', '2', '4', '5') in header
      expect(find.text('2'), findsNothing);
      expect(find.text('4'), findsNothing);
      expect(find.text('5'), findsNothing);
    });

    testWidgets('Header appears with both icons across Quick Actions, Reports, and Profile tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Asha Worker',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Switch to Actions tab
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);

      // 2. Switch to Reports tab
      await tester.tap(find.byIcon(Icons.article_outlined));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AuthenticatedAppBar), matching: find.text('Reports')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);

      // 3. Switch to Profile tab
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AuthenticatedAppBar), matching: find.text('Profile')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);
    });

    testWidgets('Header remains fixed while content scrolls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Asha Worker',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify buttons before scroll
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);

      // Drag/scroll content down
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Header and action buttons remain visible and pinned at top
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);
    });

    testWidgets('Tapping Notification button opens NotificationsScreen with empty state and no dummy records', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Asha Worker',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Notification button
      await tester.tap(find.byKey(const ValueKey('global_notification_button')));
      await tester.pumpAndSettle();

      // Verifies Notifications screen opened
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);

      // Verifies empty state displays genuine "No notifications available."
      expect(find.text('No notifications available.'), findsOneWidget);

      // Verifies no fabricated sample notification records
      expect(find.text('New high-priority rabies alert'), findsNothing);
      expect(find.text('Weekly report ready'), findsNothing);
      expect(find.text('Field survey scheduled'), findsNothing);

      // Back navigation returns to Dashboard
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AuthenticatedAppBar), matching: find.text('Dashboard')),
        findsOneWidget,
      );
      expect(find.byType(NotificationsScreen), findsNothing);
    });

    testWidgets('Tapping Synchronisation button opens existing SyncScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Asha Worker',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sync button
      await tester.tap(find.byKey(const ValueKey('global_sync_button')));
      await tester.pumpAndSettle();

      // Verifies SyncScreen opened
      expect(find.byType(SyncScreen), findsOneWidget);
      expect(find.text('Synchronisation'), findsOneWidget);
      expect(find.text('Offline & synchronisation'), findsOneWidget);
      expect(find.text('Total records'), findsOneWidget);

      // Back navigation returns to Dashboard
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AuthenticatedAppBar), matching: find.text('Dashboard')),
        findsOneWidget,
      );
      expect(find.byType(SyncScreen), findsNothing);
    });

    testWidgets('Tapping notification from SyncScreen navigates to NotificationsScreen without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SyncScreen(volunteerId: 'COHV-26-0005'),
        ),
      );
      await tester.pumpAndSettle();

      // Tap notification button in SyncScreen header
      await tester.tap(find.byKey(const ValueKey('global_notification_button')));
      await tester.pumpAndSettle();

      // Navigates to NotificationsScreen
      expect(find.byType(NotificationsScreen), findsOneWidget);

      // Back returns to SyncScreen
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SyncScreen), findsOneWidget);
    });

    testWidgets('Repeated rapid taps on Notification or Sync do not push duplicate screens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0005',
            volunteerName: 'Asha Worker',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rapidly double tap notification button
      await tester.tap(find.byKey(const ValueKey('global_notification_button')));
      await tester.tap(find.byKey(const ValueKey('global_notification_button')), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Exactly ONE NotificationsScreen instance is pushed
      expect(find.byType(NotificationsScreen), findsOneWidget);

      // Pop back
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Rapidly double tap sync button
      await tester.tap(find.byKey(const ValueKey('global_sync_button')));
      await tester.tap(find.byKey(const ValueKey('global_sync_button')), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Exactly ONE SyncScreen instance is pushed
      expect(find.byType(SyncScreen), findsOneWidget);
    });

    testWidgets('Header buttons are present on sub-screens like EventReportsListScreen, ReferralsListScreen, and AwarenessListScreen', (tester) async {
      // 1. EventReportsListScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: EventReportsListScreen(volunteerId: 'COHV-26-0005', isStandalone: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);

      // 2. ReferralsListScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: ReferralsListScreen(volunteerId: 'COHV-26-0005'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);

      // 3. AwarenessListScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: AwarenessListScreen(volunteerId: 'COHV-26-0005'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('global_notification_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_sync_button')), findsOneWidget);
    });

    testWidgets('Unauthenticated SignInScreen does not have global authenticated header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Global authenticated header buttons should NOT be on SignInScreen
      expect(find.byKey(const ValueKey('global_notification_button')), findsNothing);
      expect(find.byKey(const ValueKey('global_sync_button')), findsNothing);
      expect(find.byType(AuthenticatedAppBar), findsNothing);
    });
  });
}
