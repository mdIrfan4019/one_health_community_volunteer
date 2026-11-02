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
    token: 'test-offline-token',
    villageName: 'Amrabad',
    blockName: 'Amrabad',
    districtName: 'Nagarkurnool',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionManager.saveSession(testSession);
  });

  group('Part 4: Card Element Descriptions & Full Detail Views Offline Tests', () {
    test('1. Event Reports Detail: fetchEventDetail falls back to cached event when offline', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = EventApiService(client: offlineClient);

      final sampleEvent = EventReportItem(
        id: 'EVT-26-0088',
        numericId: 88,
        eventType: 'Suspected disease outbreaks',
        eventDate: DateTime(2026, 10, 15, 10, 30),
        village: 'Amrabad',
        primarySector: 'Public Health',
        observations: 'Severe flu symptoms observed across 3 households.',
        actionTaken: 'Distributed medicine and advised isolation.',
        purposeOfVisit: 'Routine surveillance',
        locationType: 'Rural',
        totalVisits: 3,
        targetPopulation: 'General population',
        description: 'Detailed field observation description.',
        isAlert: true,
        status: 'synced',
        verificationStatus: 'PENDING',
      );

      await SessionManager.saveSubmittedEvent(sampleEvent);

      final detail = await service.fetchEventDetail(88);

      expect(detail, isNotNull);
      expect(detail!.id, 'EVT-26-0088');
      expect(detail.numericId, 88);
      expect(detail.eventType, 'Suspected disease outbreaks');
      expect(detail.observations, 'Severe flu symptoms observed across 3 households.');
      expect(detail.actionTaken, 'Distributed medicine and advised isolation.');
      expect(detail.description, 'Detailed field observation description.');
      expect(detail.isAlert, true);
    });

    test('2. Referrals Detail: fetchReferralDetail falls back to cached referral when offline', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = ReferralsApiService(client: offlineClient);

      final sampleReferral = ReferralItem(
        id: 'REF-26-0077',
        referralId: 77,
        facilityName: 'Community Health Center',
        stream: 'Human Health',
        referralType: 'Suspected Anthrax',
        village: 'Amrabad',
        eventDate: DateTime(2026, 10, 15),
        referralDate: DateTime(2026, 10, 18),
        reason: 'Acute respiratory distress',
        isFollowedUp: false,
        status: 'synced',
        verificationStatus: 'PENDING',
        deviceId: 'DEV-TEST',
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
      );

      await SessionManager.saveSubmittedReferralsList([sampleReferral]);

      final detail = await service.fetchReferralDetail(77);

      expect(detail, isNotNull);
      expect(detail!.id, 'REF-26-0077');
      expect(detail.referralId, 77);
      expect(detail.reason, 'Acute respiratory distress');
      expect(detail.facilityName, 'Community Health Center');
      expect(detail.referralType, 'Suspected Anthrax');
    });

    test('3. Awareness Activities Detail: fetchAwarenessDetail falls back to cached activity when offline', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = AwarenessApiService(client: offlineClient);

      final sampleActivity = AwarenessItem(
        id: 'AWR-26-0066',
        awarenessId: 66,
        activityType: 'Community Awareness Workshop',
        date: DateTime(2026, 10, 20),
        peopleReached: 45,
        topicCovered: 'Hand Hygiene and Sanitation',
        departmentInvolved: 'Health',
        village: 'Amrabad',
        mediaCaption: 'Demonstrated proper handwashing techniques to village elders.',
        status: 'synced',
        verificationStatus: 'VERIFIED',
        deviceId: 'DEV-TEST',
        volunteerId: 'COHV-26-0099',
        numericVolunteerId: 99,
      );

      await SessionManager.saveSubmittedAwarenessList([sampleActivity]);

      final detail = await service.fetchAwarenessDetail(66);

      expect(detail, isNotNull);
      expect(detail!.id, 'AWR-26-0066');
      expect(detail.awarenessId, 66);
      expect(detail.peopleReached, 45);
      expect(detail.mediaCaption, 'Demonstrated proper handwashing techniques to village elders.');
      expect(detail.topicCovered, 'Hand Hygiene and Sanitation');
    });

    test('4. Sample Support Detail: fetchSampleSupportDetail falls back to cached sample when offline', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = SampleSupportApiService(client: offlineClient);

      final sampleRecord = SampleSupportRecordModel(
        sampleId: 55,
        sampleCode: 'SMP-26-0055',
        sampleTypeId: 1,
        sampleTypeName: 'Blood Smear',
        sampleDate: '2026-10-21',
        sampleCount: 12,
        volunteerId: 99,
        volunteerName: 'Ramesh Patel',
        syncStatus: 'synced',
        verificationStatus: 'PENDING',
        description: 'Sample collected from suspected livestock herd',
      );

      await SessionManager.saveSubmittedSampleSupport(sampleRecord);

      final detail = await service.fetchSampleSupportDetail(55);

      expect(detail, isNotNull);
      expect(detail!.sampleId, 55);
      expect(detail.sampleCode, 'SMP-26-0055');
      expect(detail.sampleTypeName, 'Blood Smear');
      expect(detail.sampleCount, 12);
      expect(detail.description, 'Sample collected from suspected livestock herd');
    });

    test('5. Capacity Building Detail: fetch training details falls back to cache when offline', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = CapacityBuildingApiService(client: offlineClient);

      final impartedRecord = TrainingImpartedRecordModel(
        trainingImpartedId: 44,
        trainingImpartedCode: 'TRN-IMP-26-0044',
        trainingId: 1,
        trainingName: 'Zoonotic Disease Prevention Workshop',
        trainingDate: '2026-10-22',
        duration: '3 hours',
        organisedBy: 'Community Health Unit',
        remarks: 'Active participation from local volunteers.',
        caption: 'Field session with interactive Q&A.',
        verificationStatus: 'SUBMITTED',
      );

      final attendedRecord = TrainingAttendedRecordModel(
        trainingAttendedId: 33,
        trainingAttendedCode: 'TRN-ATT-26-0033',
        trainingId: 2,
        trainingName: 'One Health Surveillance Protocols',
        trainingDate: '2026-10-23',
        venue: 'State Health Institute',
        chairedBy: 'Dr. Mukherjee',
        keyPoints: 'Early warning signals and sample transport protocols.',
        verificationStatus: 'SUBMITTED',
      );

      await SessionManager.saveSubmittedTrainingImparted(impartedRecord);
      await SessionManager.saveSubmittedTrainingAttended(attendedRecord);

      final impartedDetail = await service.fetchTrainingImpartedDetail(44);
      expect(impartedDetail, isNotNull);
      expect(impartedDetail!.trainingImpartedId, 44);
      expect(impartedDetail.trainingName, 'Zoonotic Disease Prevention Workshop');
      expect(impartedDetail.organisedBy, 'Community Health Unit');
      expect(impartedDetail.remarks, 'Active participation from local volunteers.');

      final attendedDetail = await service.fetchTrainingAttendedDetail(33);
      expect(attendedDetail, isNotNull);
      expect(attendedDetail!.trainingAttendedId, 33);
      expect(attendedDetail.trainingName, 'One Health Surveillance Protocols');
      expect(attendedDetail.venue, 'State Health Institute');
      expect(attendedDetail.keyPoints, 'Early warning signals and sample transport protocols.');
    });

    test('6. Success Stories Detail: fetchSuccessStoryDetail falls back to cached story when offline', () async {
      final offlineClient = MockClient((request) async {
        throw http.ClientException('No Internet Connection');
      });

      final service = SuccessStoryApiService(client: offlineClient);

      final sampleStory = SuccessStoryRecordModel(
        storyId: 22,
        storyCode: 'STY-26-0022',
        title: 'Rabies Awareness Drive Success',
        storyDate: '2026-10-24',
        locationText: 'Amrabad Gram Panchayat',
        oneHealthIssue: 'Rabies prevention and stray management',
        situation: 'Elevated dog bite cases in neighboring areas.',
        actionTaken: '100% vaccination coverage for domestic dogs across two villages with full community cooperation.',
        outcome: 'Zero rabies transmission reported in the following six months.',
        volunteerName: 'Ramesh Patel',
        volunteerId: 99,
        verificationStatus: 'APPROVED',
      );

      await SessionManager.saveSubmittedSuccessStory(sampleStory);

      final detail = await service.fetchSuccessStoryDetail(22);

      expect(detail, isNotNull);
      expect(detail!.storyId, 22);
      expect(detail.storyCode, 'STY-26-0022');
      expect(detail.title, 'Rabies Awareness Drive Success');
      expect(detail.situation, 'Elevated dog bite cases in neighboring areas.');
      expect(detail.actionTaken.contains('100% vaccination coverage'), true);
      expect(detail.outcome.contains('Zero rabies'), true);
      expect(detail.locationText, 'Amrabad Gram Panchayat');
    });
  });
}
