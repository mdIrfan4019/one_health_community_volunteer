import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';

void main() {
  group('Live Staging Payloads - Attachment Deduplication Verification', () {
    test('1. Events: Live staging GET /api/events/57 parses cleanly without duplicates', () {
      final stagingJson = {
        'event_report_id': 57,
        'event_report_code': 'VISIT-26-0043',
        'volunteer_id': 26,
        'volunteer_name': 'Madhav Photo Test',
        'village_lgd_code': 90000004,
        'event_type_id': 1,
        'event_type_name': 'Fever cases identified',
        'sector_code': 'human',
        'event_date': '2026-10-31',
        'event_time': '10:00:00',
        'location_type': 'RURAL',
        'description': 'Test event with 1 photo 1 video 1 doc',
        'photos': [
          {
            'attachment_id': 295,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'events/VISIT-26-0043/image_1.jpeg',
            'file_url': '/api/attachments/295',
            'url': '/uploads/events/VISIT-26-0043/image_1.jpeg'
          }
        ],
        'videos': [
          {
            'attachment_id': 296,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'events/VISIT-26-0043/video_2.mp4',
            'file_url': '/api/attachments/296',
            'url': '/uploads/events/VISIT-26-0043/video_2.mp4'
          }
        ],
        'documents': [
          {
            'attachment_id': 297,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'events/VISIT-26-0043/document_3.pdf',
            'file_url': '/api/attachments/297',
            'url': '/uploads/events/VISIT-26-0043/document_3.pdf'
          }
        ],
        'attachments': [
          {
            'attachment_id': 295,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'events/VISIT-26-0043/image_1.jpeg',
            'file_url': '/api/attachments/295',
            'url': '/uploads/events/VISIT-26-0043/image_1.jpeg'
          },
          {
            'attachment_id': 296,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'events/VISIT-26-0043/video_2.mp4',
            'file_url': '/api/attachments/296',
            'url': '/uploads/events/VISIT-26-0043/video_2.mp4'
          },
          {
            'attachment_id': 297,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'events/VISIT-26-0043/document_3.pdf',
            'file_url': '/api/attachments/297',
            'url': '/uploads/events/VISIT-26-0043/document_3.pdf'
          }
        ]
      };

      final eventItem = EventReportItem.fromJson(stagingJson);
      expect(eventItem.attachments.length, equals(3));

      // Simulate EventReportingScreen initState attachment loading
      final photos = <String>[];
      final videos = <String>[];
      final documents = <String>[];

      if (eventItem.attachments.isNotEmpty) {
        for (final att in eventItem.attachments) {
          final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(photos, path)) photos.add(path);
            } else if (att.isVideo) {
              if (!AppAttachmentItem.containsMedia(videos, path)) videos.add(path);
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(documents, path)) documents.add(path);
            }
          }
        }
      }

      expect(photos.length, equals(1), reason: 'Exactly 1 image should be present');
      expect(videos.length, equals(1), reason: 'Exactly 1 video should be present');
      expect(documents.length, equals(1), reason: 'Exactly 1 document should be present');
      expect(photos.first, contains('image_1.jpeg'));
    });

    test('2. Referrals: Live staging GET /api/referrals/39 parses cleanly without duplicates', () {
      final stagingJson = {
        'referral_id': 39,
        'referral_code': 'REF-26-0031',
        'volunteer_id': 26,
        'referral_stream': 'HUMAN',
        'referral_facility_id': 1,
        'village_lgd_code': 90000004,
        'event_date': '2026-10-31',
        'referral_date': '2026-10-31',
        'reason': 'Staging test referral',
        'description': 'Test referral with 1 photo 1 video 1 doc',
        'photos': [
          {
            'attachment_id': 299,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'referrals/REF-26-0031/image_1.jpeg',
            'file_url': '/api/attachments/299'
          }
        ],
        'videos': [
          {
            'attachment_id': 300,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'referrals/REF-26-0031/video_2.mp4',
            'file_url': '/api/attachments/300'
          }
        ],
        'documents': [
          {
            'attachment_id': 301,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'referrals/REF-26-0031/document_3.pdf',
            'file_url': '/api/attachments/301'
          }
        ],
        'attachments': [
          {
            'attachment_id': 299,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'referrals/REF-26-0031/image_1.jpeg',
            'file_url': '/api/attachments/299'
          },
          {
            'attachment_id': 300,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'referrals/REF-26-0031/video_2.mp4',
            'file_url': '/api/attachments/300'
          },
          {
            'attachment_id': 301,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'referrals/REF-26-0031/document_3.pdf',
            'file_url': '/api/attachments/301'
          }
        ]
      };

      final referralItem = ReferralItem.fromJson(stagingJson);
      expect(referralItem.attachments.length, equals(3));

      // Simulate NewReferralScreen initState attachment loading
      final photoFiles = <String>[];
      final videoFiles = <String>[];
      final documentFiles = <String>[];

      if (referralItem.attachments.isNotEmpty) {
        for (final att in referralItem.attachments) {
          final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            final kind = att.fileKind.toUpperCase();
            if (kind == 'IMAGE' || kind == 'PHOTO') {
              if (!AppAttachmentItem.containsMedia(photoFiles, path)) photoFiles.add(path);
            } else if (kind == 'VIDEO') {
              if (!AppAttachmentItem.containsMedia(videoFiles, path)) videoFiles.add(path);
            } else if (kind == 'DOCUMENT' || kind == 'PDF') {
              if (!AppAttachmentItem.containsMedia(documentFiles, path)) documentFiles.add(path);
            }
          }
        }
      }

      expect(photoFiles.length, equals(1));
      expect(videoFiles.length, equals(1));
      expect(documentFiles.length, equals(1));
      expect(photoFiles.first, contains('image_1.jpeg'));
    });

    test('3. Sample Support: Live staging GET /api/sample-support/21 maps cleanly without stringified maps', () {
      final stagingJson = {
        'sample_id': 21,
        'sample_code': 'SMP-26-0021',
        'volunteer_id': 26,
        'sample_type_id': 1,
        'sample_date': '2026-10-31',
        'sample_count': 2,
        'village_lgd_code': 90000004,
        'description': 'Test sample support with 1 photo 1 video 1 doc',
        'photos': [
          {
            'attachment_id': 303,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'samples/SMP-26-0021/image_1.jpeg',
            'file_url': '/api/attachments/303'
          }
        ],
        'videos': [
          {
            'attachment_id': 304,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'samples/SMP-26-0021/video_2.mp4',
            'file_url': '/api/attachments/304'
          }
        ],
        'documents': [
          {
            'attachment_id': 305,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'samples/SMP-26-0021/document_3.pdf',
            'file_url': '/api/attachments/305'
          }
        ],
        'attachments': [
          {
            'attachment_id': 303,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'samples/SMP-26-0021/image_1.jpeg',
            'file_url': '/api/attachments/303'
          },
          {
            'attachment_id': 304,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'samples/SMP-26-0021/video_2.mp4',
            'file_url': '/api/attachments/304'
          },
          {
            'attachment_id': 305,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'samples/SMP-26-0021/document_3.pdf',
            'file_url': '/api/attachments/305'
          }
        ]
      };

      final sampleRecord = SampleSupportRecordModel.fromJson(stagingJson);
      expect(sampleRecord.attachments.length, equals(3));

      // Simulate SampleSupportFormScreen initState
      final photos = <String>[];
      final videos = <String>[];
      final documents = <String>[];

      if (sampleRecord.attachments.isNotEmpty) {
        for (final att in sampleRecord.attachments) {
          final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(photos, path)) photos.add(path);
            } else if (att.isVideo) {
              if (!AppAttachmentItem.containsMedia(videos, path)) videos.add(path);
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(documents, path)) documents.add(path);
            }
          }
        }
      }

      expect(photos.length, equals(1));
      expect(videos.length, equals(1));
      expect(documents.length, equals(1));
      expect(photos.first, contains('image_1.jpeg'));
      expect(photos.first.startsWith('{'), isFalse, reason: 'Never stringify maps into "{attachment_id: ...}"');
    });

    test('4. Success Stories: Live staging GET /api/success-stories/17 initializes without duplicate attachments', () {
      final stagingJson = {
        'story_id': 17,
        'story_code': 'STY-26-0017',
        'volunteer_id': 26,
        'title': 'Staging Test Story',
        'story_date': '2026-10-31',
        'location_text': 'Amrabad Village',
        'one_health_issue': 'Zoonotic surveillance success',
        'situation': 'Outbreak prevented early',
        'action_taken': 'Inter-departmental rapid response',
        'department_ids': [1],
        'outcome': 'Zero hospitalizations',
        'caption': 'Test story with 1 photo 1 video 1 doc',
        'photos': [],
        'videos': [],
        'documents': [],
        'attachments': [
          {
            'attachment_id': 307,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'success_stories/STY-26-0017/image_1.jpeg',
            'url': '/uploads/success_stories/STY-26-0017/image_1.jpeg',
            'file_url': '/api/attachments/307'
          },
          {
            'attachment_id': 308,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'success_stories/STY-26-0017/video_2.mp4',
            'url': '/uploads/success_stories/STY-26-0017/video_2.mp4',
            'file_url': '/api/attachments/308'
          },
          {
            'attachment_id': 309,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'success_stories/STY-26-0017/document_3.pdf',
            'url': '/uploads/success_stories/STY-26-0017/document_3.pdf',
            'file_url': '/api/attachments/309'
          }
        ]
      };

      final storyItem = SuccessStoryRecordModel.fromJson(stagingJson);
      expect(storyItem.attachments.length, equals(3));

      // Simulate NewSuccessStoryScreen initState
      final photos = <String>[];
      final videos = <String>[];
      final existingDocs = <String>[];

      if (storyItem.attachments.isNotEmpty) {
        for (final att in storyItem.attachments) {
          final path = att.fileUrl?.isNotEmpty == true
              ? att.fileUrl!
              : (att.storagePath.isNotEmpty ? att.storagePath : '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(photos, path)) photos.add(path);
            } else if (att.isVideo) {
              if (!AppAttachmentItem.containsMedia(videos, path)) videos.add(path);
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(existingDocs, path)) existingDocs.add(path);
            }
          }
        }
      }

      expect(photos.length, equals(1));
      expect(videos.length, equals(1));
      expect(existingDocs.length, equals(1));
    });

    test('5. Capacity Building: Live staging GET /api/capacity-building/training-imparted/21 single source of truth', () {
      final stagingJson = {
        'training_imparted_id': 21,
        'training_imparted_code': 'TRI-26-0021',
        'volunteer_id': 26,
        'training_id': 1,
        'training_name': 'Rabies first aid and bite management',
        'training_date': '2026-10-31',
        'duration': '2 hours',
        'remarks': 'Staging test imparted',
        'photos': [],
        'videos': [],
        'documents': [],
        'attachments': [
          {
            'attachment_id': 314,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'training_imparted/TRI-26-0021/image_1.jpeg',
            'url': '/uploads/training_imparted/TRI-26-0021/image_1.jpeg',
            'file_url': '/api/attachments/314'
          },
          {
            'attachment_id': 315,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'training_imparted/TRI-26-0021/video_2.mp4',
            'url': '/uploads/training_imparted/TRI-26-0021/video_2.mp4',
            'file_url': '/api/attachments/315'
          },
          {
            'attachment_id': 316,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'training_imparted/TRI-26-0021/document_3.pdf',
            'url': '/uploads/training_imparted/TRI-26-0021/document_3.pdf',
            'file_url': '/api/attachments/316'
          }
        ]
      };

      final record = TrainingImpartedRecordModel.fromJson(stagingJson);
      expect(record.richAttachments.length, equals(3));

      // Simulate NewTrainingScreen initState
      final existingPhotos = <String>[];
      final existingDocuments = <String>[];

      if (record.richAttachments.isNotEmpty) {
        for (final att in record.richAttachments) {
          final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(existingPhotos, path)) existingPhotos.add(path);
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(existingDocuments, path)) existingDocuments.add(path);
            }
          }
        }
      }

      expect(existingPhotos.length, equals(1));
      expect(existingDocuments.length, equals(1));
    });

    test('6. Capacity Building: Live staging GET /api/capacity-building/training-attended/22 single source of truth', () {
      final stagingJson = {
        'training_attended_id': 22,
        'training_attended_code': 'TRN-26-0022',
        'volunteer_id': 26,
        'training_id': 1,
        'training_name': 'Rabies first aid and bite management',
        'training_date': '2026-10-31',
        'venue': 'Nagarkurnool District Center',
        'certificate_issued': true,
        'photos': [],
        'videos': [],
        'documents': [],
        'attachments': [
          {
            'attachment_id': 318,
            'file_kind': 'IMAGE',
            'file_name': 'logo.jpeg',
            'storage_path': 'training_attended/TRN-26-0022/image_1.jpeg',
            'url': '/uploads/training_attended/TRN-26-0022/image_1.jpeg',
            'file_url': '/api/attachments/318'
          },
          {
            'attachment_id': 319,
            'file_kind': 'VIDEO',
            'file_name': 'valid_test.mp4',
            'storage_path': 'training_attended/TRN-26-0022/video_2.mp4',
            'url': '/uploads/training_attended/TRN-26-0022/video_2.mp4',
            'file_url': '/api/attachments/319'
          },
          {
            'attachment_id': 320,
            'file_kind': 'DOCUMENT',
            'file_name': 'valid_test.pdf',
            'storage_path': 'training_attended/TRN-26-0022/document_3.pdf',
            'url': '/uploads/training_attended/TRN-26-0022/document_3.pdf',
            'file_url': '/api/attachments/320'
          }
        ]
      };

      final record = TrainingAttendedRecordModel.fromJson(stagingJson);
      expect(record.richAttachments.length, equals(3));

      // Simulate NewTrainingAttendedScreen initState
      final existingPhotos = <String>[];
      final existingDocuments = <String>[];

      if (record.richAttachments.isNotEmpty) {
        for (final att in record.richAttachments) {
          final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(existingPhotos, path)) existingPhotos.add(path);
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(existingDocuments, path)) existingDocuments.add(path);
            }
          }
        }
      }

      expect(existingPhotos.length, equals(1));
      expect(existingDocuments.length, equals(1));
    });
  });
}
