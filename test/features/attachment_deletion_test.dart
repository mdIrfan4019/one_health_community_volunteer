import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';

void main() {
  group('Option B Attachment Deletion Unit Tests Across All 6 Modules', () {
    test('1. EventReportRequest serializes removedAttachmentIds correctly', () {
      final reqWithout = EventReportRequest(
        eventTypeId: 1,
        eventType: 'Fever cases identified',
        date: DateTime(2026, 10, 31),
        time: '10:00:00',
        villageLgdCode: 90000004,
        village: 'Amrabad',
        isOutOfAreaVisit: false,
        purposeOfVisit: 'Surveillance',
        locationType: 'Rural',
        totalVisits: 1,
        populationTypeId: 1,
        primarySector: 'human',
        targetPopulation: 'General',
        observations: 'Routine check',
        actionTaken: 'Advised rest',
        isReferralGenerated: false,
        isAlertGenerated: false,
        isFollowUpRequired: false,
        volunteerId: '26',
        deviceId: 'DEV-001',
      );
      final jsonWithout = reqWithout.toJson();
      expect(jsonWithout.containsKey('removed_attachment_ids'), isFalse);

      final reqWith = EventReportRequest(
        eventTypeId: 1,
        eventType: 'Fever cases identified',
        date: DateTime(2026, 10, 31),
        time: '10:00:00',
        villageLgdCode: 90000004,
        village: 'Amrabad',
        isOutOfAreaVisit: false,
        purposeOfVisit: 'Surveillance',
        locationType: 'Rural',
        totalVisits: 1,
        populationTypeId: 1,
        primarySector: 'human',
        targetPopulation: 'General',
        observations: 'Routine check',
        actionTaken: 'Advised rest',
        isReferralGenerated: false,
        isAlertGenerated: false,
        isFollowUpRequired: false,
        volunteerId: '26',
        deviceId: 'DEV-001',
        removedAttachmentIds: [301, 302],
      );
      final jsonWith = reqWith.toJson();
      expect(jsonWith['removed_attachment_ids'], equals([301, 302]));
    });

    test('2. ReferralCreateRequest serializes removedAttachmentIds correctly', () {
      final reqWithout = ReferralCreateRequest(
        volunteerId: 26,
        referralStream: 'HUMAN',
        referralFacilityId: 1,
        villageLgdCode: 90000004,
        eventDate: DateTime(2026, 10, 31),
        referralDate: DateTime(2026, 10, 31),
        reason: 'Fever',
      );
      expect(reqWithout.toJson().containsKey('removed_attachment_ids'), isFalse);

      final reqWith = ReferralCreateRequest(
        volunteerId: 26,
        referralStream: 'HUMAN',
        referralFacilityId: 1,
        villageLgdCode: 90000004,
        eventDate: DateTime(2026, 10, 31),
        referralDate: DateTime(2026, 10, 31),
        reason: 'Fever',
        removedAttachmentIds: [303],
      );
      expect(reqWith.toJson()['removed_attachment_ids'], equals([303]));
    });

    test('3. SampleSupportCreateRequest serializes removedAttachmentIds correctly', () {
      final reqWithout = SampleSupportCreateRequest(
        volunteerId: 26,
        sampleTypeId: 1,
        sampleDate: '2026-10-31',
        villageLgdCode: 90000004,
        sampleCount: 2,
        clientRef: 'SMP-001',
        deviceId: 'DEV-001',
        capturedAt: '2026-10-31T10:00:00Z',
      );
      expect(reqWithout.toJson().containsKey('removed_attachment_ids'), isFalse);

      final reqWith = SampleSupportCreateRequest(
        volunteerId: 26,
        sampleTypeId: 1,
        sampleDate: '2026-10-31',
        villageLgdCode: 90000004,
        sampleCount: 2,
        clientRef: 'SMP-001',
        deviceId: 'DEV-001',
        capturedAt: '2026-10-31T10:00:00Z',
        removedAttachmentIds: [304, 305],
      );
      expect(reqWith.toJson()['removed_attachment_ids'], equals([304, 305]));
    });

    test('4. SuccessStoryCreateRequest serializes removedAttachmentIds correctly', () {
      final reqWithout = SuccessStoryCreateRequest(
        volunteerId: 26,
        title: 'Story',
        storyDate: '2026-10-31',
        locationText: 'Amrabad',
        oneHealthIssue: 'Zoonotic',
        situation: 'Sit',
        actionTaken: 'Act',
        departmentId: 1,
        outcome: 'Good',
        clientRef: 'ST-001',
        deviceId: 'DEV-001',
      );
      expect(reqWithout.toJson().containsKey('removed_attachment_ids'), isFalse);

      final reqWith = SuccessStoryCreateRequest(
        volunteerId: 26,
        title: 'Story',
        storyDate: '2026-10-31',
        locationText: 'Amrabad',
        oneHealthIssue: 'Zoonotic',
        situation: 'Sit',
        actionTaken: 'Act',
        departmentId: 1,
        outcome: 'Good',
        clientRef: 'ST-001',
        deviceId: 'DEV-001',
        removedAttachmentIds: [306],
      );
      expect(reqWith.toJson()['removed_attachment_ids'], equals([306]));
    });

    test('5. TrainingImpartedCreateRequest serializes removedAttachmentIds correctly', () {
      final reqWithout = TrainingImpartedCreateRequest(
        trainingId: 1,
        trainingDate: '2026-10-31',
      );
      expect(reqWithout.toJson().containsKey('removed_attachment_ids'), isFalse);

      final reqWith = TrainingImpartedCreateRequest(
        trainingId: 1,
        trainingDate: '2026-10-31',
        removedAttachmentIds: [307],
      );
      expect(reqWith.toJson()['removed_attachment_ids'], equals([307]));
    });

    test('6. TrainingAttendedCreateRequest serializes removedAttachmentIds correctly', () {
      final reqWithout = TrainingAttendedCreateRequest(
        trainingId: 1,
        trainingDate: '2026-10-31',
      );
      expect(reqWithout.toJson().containsKey('removed_attachment_ids'), isFalse);

      final reqWith = TrainingAttendedCreateRequest(
        trainingId: 1,
        trainingDate: '2026-10-31',
        removedAttachmentIds: [308, 309],
      );
      expect(reqWith.toJson()['removed_attachment_ids'], equals([308, 309]));
    });

    test('7. AppAttachmentItem tracks ID only for persisted server attachments', () {
      final serverAttachments = [
        AppAttachmentItem(
          attachmentId: 321,
          fileKind: 'IMAGE',
          fileName: 'photo.jpg',
          storagePath: 'storage/uploads/events/photo.jpg',
          fileUrl: 'https://staging.domain/storage/uploads/events/photo.jpg',
        ),
        AppAttachmentItem(
          attachmentId: 322,
          fileKind: 'DOCUMENT',
          fileName: 'doc.pdf',
          storagePath: 'storage/uploads/events/doc.pdf',
          fileUrl: 'https://staging.domain/storage/uploads/events/doc.pdf',
        ),
      ];

      final removedIds = <int>[];
      void trackRemoved(String path) {
        for (final att in serverAttachments) {
          if (att.attachmentId > 0 &&
              (AppAttachmentItem.isSameMedia(path, att.storagePath) ||
                  (att.fileUrl != null && AppAttachmentItem.isSameMedia(path, att.fileUrl!)) ||
                  path == att.storagePath ||
                  path == att.fileUrl ||
                  (att.storagePath.isNotEmpty && path.endsWith(att.storagePath)) ||
                  (att.fileName.isNotEmpty && path.endsWith(att.fileName)))) {
            if (!removedIds.contains(att.attachmentId)) {
              removedIds.add(att.attachmentId);
            }
            break;
          }
        }
      }

      // Deleting a local temporary file not on server
      trackRemoved('/data/user/0/cache/temp_picker_123.jpg');
      expect(removedIds, isEmpty);

      // Deleting server photo
      trackRemoved('https://staging.domain/storage/uploads/events/photo.jpg');
      expect(removedIds, equals([321]));

      // Deleting server document
      trackRemoved('storage/uploads/events/doc.pdf');
      expect(removedIds, equals([321, 322]));

      // Removing duplicate call does not duplicate ID
      trackRemoved('storage/uploads/events/doc.pdf');
      expect(removedIds, equals([321, 322]));
    });

    test('8. Atomic Add + Delete representation in PUT payload', () {
      final newLocalPhoto = '/data/user/0/cache/new_capture.jpg';
      final existingPhotoUrl = 'https://staging.domain/storage/uploads/events/photo.jpg';

      final request = EventReportRequest(
        eventTypeId: 1,
        eventType: 'Fever cases identified',
        date: DateTime(2026, 10, 31),
        time: '10:00:00',
        villageLgdCode: 90000004,
        village: 'Amrabad',
        isOutOfAreaVisit: false,
        purposeOfVisit: 'Surveillance',
        locationType: 'Rural',
        totalVisits: 1,
        populationTypeId: 1,
        primarySector: 'human',
        targetPopulation: 'General',
        observations: 'Routine check',
        actionTaken: 'Advised rest',
        isReferralGenerated: false,
        isAlertGenerated: false,
        isFollowUpRequired: false,
        volunteerId: '26',
        deviceId: 'DEV-001',
        photos: [existingPhotoUrl, newLocalPhoto],
        documents: [],
        removedAttachmentIds: [322],
      );

      final json = request.toJson();
      expect(json['removed_attachment_ids'], equals([322]));
      expect(request.photos, contains(newLocalPhoto));
      expect(request.documents, isEmpty);
    });

    test('9. Test D: Reopening Edit form recreates remaining attachments without duplicates', () {
      final updatedBackendJson = {
        'id': 201,
        'event_id': 201,
        'event_title': 'OneHealth Camp',
        'event_date': '2026-10-31T10:00:00',
        'village_lgd_code': 90000004,
        'photos': [],
        'documents': [
          'https://staging.domain/storage/uploads/events/doc.pdf',
        ],
        'media_files': [
          'storage/uploads/events/doc.pdf',
        ],
        'attachments': [
          {
            'attachment_id': 322,
            'file_kind': 'DOCUMENT',
            'file_name': 'doc.pdf',
            'storage_path': 'storage/uploads/events/doc.pdf',
            'file_url': 'https://staging.domain/storage/uploads/events/doc.pdf',
          }
        ],
      };

      final record = EventReportItem.fromJson(updatedBackendJson);
      expect(record.attachments.length, equals(1));
      expect(record.attachments.first.attachmentId, equals(322));

      final existingPhotos = <String>[];
      final existingDocs = <String>[];
      for (final att in record.attachments) {
        final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
        if (att.isImage) {
          if (!AppAttachmentItem.containsMedia(existingPhotos, path)) existingPhotos.add(path);
        } else if (att.isDocument) {
          if (!AppAttachmentItem.containsMedia(existingDocs, path)) existingDocs.add(path);
        }
      }

      expect(existingPhotos, isEmpty);
      expect(existingDocs.length, equals(1));
      expect(existingDocs.first, contains('doc.pdf'));
    });
  });
}
