import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/dashboard/data/dashboard_api_service.dart';
import 'package:cohv/features/dashboard/domain/dashboard_models.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:cohv/features/events/presentation/screen/event_reports_list_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Part 2: Dashboard Metrics & Card Numbers Offline Tests', () {
    test('DashboardMetrics.copyWith produces updated instances with augmented counts', () {
      final base = DashboardMetrics(
        totalVisits: 10,
        referrals: 5,
        awarenessActivities: 3,
        samplesSupported: 2,
        trainingsImparted: 1,
        trainingsAttended: 4,
        successStories: 2,
        pendingSyncCount: 0,
      );

      final augmented = base.copyWith(
        totalVisits: base.totalVisits + 2,
        referrals: base.referrals + 1,
        pendingSyncCount: 3,
      );

      expect(augmented.totalVisits, 12);
      expect(augmented.referrals, 6);
      expect(augmented.awarenessActivities, 3);
      expect(augmented.pendingSyncCount, 3);
    });

    test('DashboardApiService.getDashboardMetrics falls back to cached metrics when offline', () async {
      final cachedMetrics = DashboardMetrics(
        volunteerCode: 'COHV-26-0099',
        volunteerName: 'Ramesh Patel',
        totalVisits: 14,
        referrals: 8,
        pendingFollowUps: 3,
        awarenessActivities: 5,
        trainingsImparted: 2,
        trainingsAttended: 3,
        pendingSyncCount: 1,
      );

      await SessionManager.saveDashboardMetrics('COHV-26-0099', cachedMetrics);

      // Mock client that always throws network exception
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = DashboardApiService(client: offlineClient);
      final result = await apiService.getDashboardMetrics('COHV-26-0099');

      expect(result.totalVisits, greaterThanOrEqualTo(14));
      expect(result.referrals, greaterThanOrEqualTo(8));
      expect(result.awarenessActivities, greaterThanOrEqualTo(5));
      expect(result.volunteerName, 'Ramesh Patel');
    });

    test('DashboardApiService.getVolunteerProfile loads hero identity from cached session offline', () async {
      final session = UserSession(
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
        fullName: 'Ramesh Patel',
        mobile: '9876543210',
        sector: 'Public Health Department',
        departmentName: 'Public Health Department',
        status: 'ACTIVE',
        token: 'mock_token',
        villageName: 'Amrabad',
        blockName: 'Amrabad',
        districtName: 'Nagarkurnool',
      );

      await SessionManager.saveSession(session);

      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = DashboardApiService(client: offlineClient);
      final profile = await apiService.getVolunteerProfile('COHV-26-0099');

      expect(profile.fullName, 'Ramesh Patel');
      expect(profile.volunteerId, 'COHV-26-0099');
      expect(profile.status, 'Active');
      expect(profile.departmentName, 'Public Health Department');
    });

    testWidgets('Tapping Total Visits card navigates to EventReportsListScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cachedMetrics = DashboardMetrics(
        volunteerCode: 'COHV-26-0099',
        volunteerName: 'Ramesh Patel',
        totalVisits: 14,
      );
      await SessionManager.saveDashboardMetrics('COHV-26-0099', cachedMetrics);

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0099',
            volunteerName: 'Ramesh Patel',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the Total visits card
      final totalVisitsFinder = find.text('Total visits');
      expect(totalVisitsFinder, findsOneWidget);

      await tester.ensureVisible(totalVisitsFinder);
      await tester.tap(totalVisitsFinder);
      await tester.pumpAndSettle();

      // Verify EventReportsListScreen was pushed onto Navigator
      expect(find.byType(EventReportsListScreen), findsOneWidget);
    });

    testWidgets('Tapping Referrals card navigates to ReferralsListScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cachedMetrics = DashboardMetrics(
        volunteerCode: 'COHV-26-0099',
        volunteerName: 'Ramesh Patel',
        referrals: 8,
      );
      await SessionManager.saveDashboardMetrics('COHV-26-0099', cachedMetrics);

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0099',
            volunteerName: 'Ramesh Patel',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the Referrals card
      final referralsFinder = find.text('Referrals');
      expect(referralsFinder, findsOneWidget);

      await tester.ensureVisible(referralsFinder);
      await tester.tap(referralsFinder);
      await tester.pumpAndSettle();

      // Verify ReferralsListScreen was pushed onto Navigator
      expect(find.byType(ReferralsListScreen), findsOneWidget);
    });
  });
}
