import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/events/data/event_api_service.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/referrals/data/referrals_api_service.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/sample_reprot/data/sample_support_api_service.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/capacity_building/data/capacity_building_api_service.dart';
import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';
import 'package:cohv/features/success_stories/data/success_story_api_service.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSession = UserSession(
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionManager.saveSession(testSession);
  });

  group('Part 3: Module Listing Screens Offline Access Tests', () {
    test('1. Event Reports: falls back to cached events when offline', () async {
      final List<EventReportItem> sampleEvents = [
        EventReportItem(
          id: 'VISIT-26-0099',
          volunteerId: 'COHV-26-0099',
          numericVolunteerId: 99,
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
          observations: 'Cluster observed in domestic zone.',
          actionTaken: 'Notified local surveillance team.',
        ),
      ];
      await SessionManager.saveSubmittedEventsList(
        sampleEvents,
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
      );

      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = EventApiService(client: offlineClient);

      // Verify fast getCachedEventReports
      final cachedList = await apiService.getCachedEventReports(volunteerId: 'COHV-26-0099');
      expect(cachedList.length, 1);
      expect(cachedList.first.id, 'VISIT-26-0099');

      // Verify fetchEventReports offline fallback
      final fetchedList = await apiService.fetchEventReports(
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
      );
      expect(fetchedList.length, 1);
      expect(fetchedList.first.id, 'VISIT-26-0099');
    });

    test('2. Referrals: falls back to cached referrals when offline', () async {
      final List<ReferralItem> sampleReferrals = [
        ReferralItem(
          id: 'REF-26-0042',
          volunteerId: 'COHV-26-0099',
          numericVolunteerId: 99,
          facilityName: 'Primary Health Center Amrabad',
          stream: 'HUMAN',
          referralType: 'Clinical',
          village: 'Amrabad',
          eventDate: DateTime(2026, 10, 11),
          referralDate: DateTime(2026, 10, 12),
          isFollowedUp: false,
          deviceId: 'device-123',
          status: 'completed',
          reason: 'Severe persistent fever cluster',
        ),
      ];
      await SessionManager.saveSubmittedReferralsList(
        sampleReferrals,
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
      );

      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = ReferralsApiService(client: offlineClient);

      // Verify fast getCachedReferrals
      final cachedList = await apiService.getCachedReferrals('COHV-26-0099', 99);
      expect(cachedList.length, 1);
      expect(cachedList.first.id, 'REF-26-0042');

      // Verify getReferrals offline fallback
      final fetchedList = await apiService.getReferrals('COHV-26-0099', 99);
      expect(fetchedList.length, 1);
      expect(fetchedList.first.id, 'REF-26-0042');
    });

    test('3. Awareness Activities: falls back to cached activities when offline', () async {
      final List<AwarenessItem> sampleActivities = [
        AwarenessItem(
          id: 'AW-26-0015',
          activityType: 'Community Awareness Workshop',
          date: DateTime(2026, 10, 14),
          village: 'Amrabad',
          peopleReached: 45,
          topicCovered: 'Zoonotic Disease Prevention',
          departmentInvolved: 'Health',
          status: 'submitted',
          verificationStatus: 'Submitted',
          volunteerId: 'COHV-26-0099',
          numericVolunteerId: 99,
          deviceId: 'device-123',
        ),
      ];
      await SessionManager.saveSubmittedAwarenessList(
        sampleActivities,
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
      );

      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = AwarenessApiService(client: offlineClient);

      // Verify fast getCachedAwarenessList
      final cachedList = await apiService.getCachedAwarenessList('COHV-26-0099', 99);
      expect(cachedList.length, 1);
      expect(cachedList.first.id, 'AW-26-0015');

      // Verify getAwarenessList offline fallback
      final fetchedList = await apiService.getAwarenessList('COHV-26-0099', 99);
      expect(fetchedList.length, 1);
      expect(fetchedList.first.id, 'AW-26-0015');
    });

    test('4. Sample Support: falls back to cached sample records when offline', () async {
      final List<SampleSupportRecordModel> sampleRecords = [
        const SampleSupportRecordModel(
          sampleId: 108,
          sampleCode: 'SMP-26-0108',
          volunteerId: 99,
          volunteerName: 'Ramesh Patel',
          sampleTypeId: 1,
          sampleTypeName: 'Blood Smear',
          sampleDate: '2026-10-15',
          sampleCount: 2,
          verificationStatus: 'VERIFIED',
          syncStatus: 'synced',
        ),
      ];
      await SessionManager.saveSubmittedSampleSupportList(sampleRecords);

      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = SampleSupportApiService(client: offlineClient);

      // Verify fast getCachedSampleSupportList
      final cachedList = await apiService.getCachedSampleSupportList(volunteerId: 'COHV-26-0099');
      expect(cachedList.length, 1);
      expect(cachedList.first.sampleId, 108);

      // Verify fetchSampleSupportList offline fallback
      final fetchedList = await apiService.fetchSampleSupportList(volunteerId: 99);
      expect(fetchedList.length, 1);
      expect(fetchedList.first.sampleId, 108);
    });

    test('5. Capacity Building: falls back to cached training lists when offline', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = CapacityBuildingApiService(client: offlineClient);

      // Verify offline calls return gracefully without uncaught exceptions
      final imparted = await apiService.fetchTrainingImpartedList();
      expect(imparted, isA<List<TrainingImpartedRecordModel>>());

      final attended = await apiService.fetchTrainingAttendedList();
      expect(attended, isA<List<TrainingAttendedRecordModel>>());

      final cachedImparted = await apiService.getCachedTrainingImpartedList(volunteerId: 'COHV-26-0099');
      expect(cachedImparted, isA<List<TrainingImpartedRecordModel>>());

      final cachedAttended = await apiService.getCachedTrainingAttendedList(volunteerId: 'COHV-26-0099');
      expect(cachedAttended, isA<List<TrainingAttendedRecordModel>>());
    });

    test('6. Success Stories: falls back to cached stories when offline', () async {
      final List<SuccessStoryRecordModel> sampleStories = [
        const SuccessStoryRecordModel(
          storyId: 55,
          storyCode: 'SS-26-0055',
          volunteerId: 99,
          volunteerName: 'Ramesh Patel',
          title: 'Early Zoonotic Containment in Amrabad',
          storyDate: '2026-10-10',
          locationText: 'Amrabad Village',
          oneHealthIssue: 'Rabies control',
          situation: 'Suspected outbreak averted',
          actionTaken: 'Immediate vaccination drive',
          outcome: 'Zero human rabies cases reported',
          verificationStatus: 'VERIFIED',
        ),
      ];
      await SessionManager.saveSubmittedSuccessStoriesList(
        sampleStories,
        volunteerId: 'COHV-26-0099',
      );

      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final apiService = SuccessStoryApiService(client: offlineClient);

      // Verify fast getCachedSuccessStoriesList
      final cachedList = await apiService.getCachedSuccessStoriesList(volunteerId: 'COHV-26-0099');
      expect(cachedList.length, 1);
      expect(cachedList.first.storyId, 55);

      // Verify fetchSuccessStoriesList offline fallback
      final fetchedList = await apiService.fetchSuccessStoriesList(
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
      );
      expect(fetchedList.length, 1);
      expect(fetchedList.first.storyId, 55);
    });
  });
}
