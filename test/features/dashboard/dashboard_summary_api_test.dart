import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/dashboard/data/dashboard_api_service.dart';
import 'package:cohv/features/dashboard/domain/dashboard_models.dart';
import 'package:cohv/features/dashboard/presentation/screen/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleApiResponse = {
    "success": true,
    "message": "Volunteer summary fetched successfully",
    "data": {
      "volunteer_id": 52,
      "volunteer_code": "COHV-26-0018",
      "volunteer_name": "Abdul",
      "total_visits": 5,
      "alerts_generated": 0,
      "open_alerts": 0,
      "referrals": 6,
      "referrals_followup": 2,
      "pending_follow_ups": 2,
      "pending_followups": 2,
      "awareness": 1,
      "awareness_activities": 1,
      "trainings_imparted": 0,
      "trainings_attended": 0,
      "meetings": 0,
      "samples": 2,
      "samples_supported": 2,
      "success_stories": 2,
    },
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dashboard Summary API & Model Tests', () {
    test('DashboardMetrics.fromJson correctly parses full backend response payload', () {
      final metrics = DashboardMetrics.fromJson(sampleApiResponse);

      expect(metrics.volunteerId, 52);
      expect(metrics.volunteerCode, 'COHV-26-0018');
      expect(metrics.volunteerName, 'Abdul');
      expect(metrics.totalVisits, 5);
      expect(metrics.alertsGenerated, 0);
      expect(metrics.openAlerts, 0);
      expect(metrics.referrals, 6);
      expect(metrics.referralsFollowup, 2);
      expect(metrics.pendingFollowUps, 2);
      expect(metrics.awarenessActivities, 1);
      expect(metrics.trainingsImparted, 0);
      expect(metrics.trainingsAttended, 0);
      expect(metrics.meetings, 0);
      expect(metrics.samplesSupported, 2);
      expect(metrics.successStories, 2);
      expect(metrics.pendingSyncCount, 0);
    });

    test('DashboardApiService.getDashboardMetrics fetches and parses data via HTTP', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/volunteers/summary'));
        expect(request.url.queryParameters['volunteer_id'], '52');
        return http.Response(jsonEncode(sampleApiResponse), 200);
      });

      final apiService = DashboardApiService(client: mockClient);
      final metrics = await apiService.getDashboardMetrics('52');

      expect(metrics.totalVisits, 5);
      expect(metrics.referrals, 6);
      expect(metrics.pendingFollowUps, 2);
      expect(metrics.awarenessActivities, 1);
      expect(metrics.volunteerName, 'Abdul');
    });

    test('SessionManager saves and recovers cached dashboard metrics', () async {
      final metrics = DashboardMetrics.fromJson(sampleApiResponse);
      await SessionManager.saveDashboardMetrics('COHV-26-0018', metrics);

      final cached = await SessionManager.getCachedDashboardMetrics('COHV-26-0018');
      expect(cached, isNotNull);
      expect(cached!.totalVisits, 5);
      expect(cached.referrals, 6);
      expect(cached.pendingFollowUps, 2);
      expect(cached.awarenessActivities, 1);
    });

    testWidgets('DashboardScreen displays cached metrics immediately without dummy counts', (tester) async {
      // Pre-seed cached metrics in SessionManager
      final metrics = DashboardMetrics.fromJson(sampleApiResponse);
      await SessionManager.saveDashboardMetrics('COHV-26-0018', metrics);

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            volunteerId: 'COHV-26-0018',
            volunteerName: 'Abdul',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check greeting has user name
      expect(find.text('Good day, Abdul 👋'), findsOneWidget);

      // Verify the dynamic values are rendered on the cards
      expect(find.text('5'), findsOneWidget); // Total visits
      expect(find.text('6'), findsOneWidget); // Referrals
      expect(find.text('2'), findsOneWidget); // Pending follow-ups
      expect(find.text('1'), findsOneWidget); // Awareness activities
    });
  });
}
