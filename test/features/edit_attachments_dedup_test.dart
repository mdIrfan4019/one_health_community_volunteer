import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';

void main() {
  group('Attachment Deduplication and Single Source of Truth Tests', () {
    test('AppAttachmentItem.isSameMedia correctly normalizes URLs and relative paths', () {
      const url1 = 'https://api.onehealth.gov.in/storage/uploads/events/banner.jpg?token=abc';
      const path1 = 'uploads/events/banner.jpg';
      const path2 = 'storage/uploads/events/banner.jpg';
      const encodedUrl = 'https://api.onehealth.gov.in/storage/uploads/events/my%20banner.jpg';
      const decodedPath = 'uploads/events/my banner.jpg';

      expect(AppAttachmentItem.isSameMedia(url1, path1), isTrue);
      expect(AppAttachmentItem.isSameMedia(url1, path2), isTrue);
      expect(AppAttachmentItem.isSameMedia(encodedUrl, decodedPath), isTrue);
      expect(AppAttachmentItem.isSameMedia(path1, 'uploads/referrals/banner.jpg'), isFalse);
    });

    test('Events: Ingestion from backend with both attachments and media_files produces no duplicates', () {
      final backendJson = {
        'id': 101,
        'event_id': 101,
        'event_title': 'OneHealth Camp',
        'event_date': '2026-10-26T10:00:00',
        'village_lgd_code': 580001,
        'photos': [
          'https://api.onehealth.gov.in/storage/uploads/events/banner.jpg',
        ],
        'videos': [
          'https://api.onehealth.gov.in/storage/uploads/events/summary.mp4',
        ],
        'documents': [
          'https://api.onehealth.gov.in/storage/uploads/events/attendance.pdf',
        ],
        'media_files': [
          'uploads/events/banner.jpg',
          'uploads/events/summary.mp4',
          'uploads/events/attendance.pdf',
        ],
        'attachments': [
          {
            'attachment_id': 501,
            'file_kind': 'IMAGE',
            'file_name': 'banner.jpg',
            'storage_path': 'uploads/events/banner.jpg',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/events/banner.jpg',
          },
          {
            'attachment_id': 502,
            'file_kind': 'VIDEO',
            'file_name': 'summary.mp4',
            'storage_path': 'uploads/events/summary.mp4',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/events/summary.mp4',
          },
          {
            'attachment_id': 503,
            'file_kind': 'DOCUMENT',
            'file_name': 'attendance.pdf',
            'storage_path': 'uploads/events/attendance.pdf',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/events/attendance.pdf',
          },
        ],
      };

      final event = EventReportItem.fromJson(backendJson);
      expect(event.attachments.length, 3);

      // Simulate form edit initialization
      final photos = <String>[];
      final videos = <String>[];
      final documents = <String>[];

      if (event.attachments.isNotEmpty) {
        for (final att in event.attachments) {
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

      // Expected: Exactly 1 Photo, 1 Video, 1 Document
      expect(photos.length, 1);
      expect(videos.length, 1);
      expect(documents.length, 1);

      // Re-opening edit mode (Test 3)
      final photosReopen = List<String>.from(photos);
      expect(photosReopen.length, 1);

      // Adding new image (Test 4)
      const newPhoto = '/local/cache/new_camera_photo.jpg';
      if (!AppAttachmentItem.containsMedia(photos, newPhoto)) photos.add(newPhoto);
      expect(photos.length, 2);

      // Removing attachment (Test 5)
      photos.removeAt(0);
      expect(photos.length, 1);
      expect(photos.first, newPhoto);
    });

    test('Referrals: Single source of truth ignores duplicate photos/videos arrays', () {
      final backendJson = {
        'id': 201,
        'referral_id': 201,
        'reason': 'High fever referral',
        'referral_date': '2026-10-26',
        'photos': [
          {'file_url': 'https://api.onehealth.gov.in/storage/uploads/referrals/patient.jpg'},
        ],
        'videos': [
          {'file_url': 'https://api.onehealth.gov.in/storage/uploads/referrals/gait.mp4'},
        ],
        'documents': [
          {'file_url': 'https://api.onehealth.gov.in/storage/uploads/referrals/prescription.pdf'},
        ],
        'attachments': [
          {
            'attachment_id': 601,
            'file_kind': 'IMAGE',
            'file_name': 'patient.jpg',
            'storage_path': 'uploads/referrals/patient.jpg',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/referrals/patient.jpg',
          },
          {
            'attachment_id': 602,
            'file_kind': 'VIDEO',
            'file_name': 'gait.mp4',
            'storage_path': 'uploads/referrals/gait.mp4',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/referrals/gait.mp4',
          },
          {
            'attachment_id': 603,
            'file_kind': 'DOCUMENT',
            'file_name': 'prescription.pdf',
            'storage_path': 'uploads/referrals/prescription.pdf',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/referrals/prescription.pdf',
          },
        ],
      };

      final referral = ReferralItem.fromJson(backendJson);
      expect(referral.attachments.length, 3);

      final photoFiles = <String>[];
      final videoFiles = <String>[];
      final documentFiles = <String>[];

      if (referral.attachments.isNotEmpty) {
        for (final att in referral.attachments) {
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

      expect(photoFiles.length, 1);
      expect(videoFiles.length, 1);
      expect(documentFiles.length, 1);
    });

    test('Sample Support: Stringified maps are sanitized and attachments array is prioritized', () {
      final backendJson = {
        'sample_id': 301,
        'sample_code': 'SMP-26-0301',
        'sample_type_id': 1,
        'sample_date': '2026-10-26',
        'photos': [
          {'attachment_id': 701, 'file_url': 'https://api.onehealth.gov.in/storage/uploads/samples/sample_vial.jpg'},
        ],
        'videos': [
          {'attachment_id': 702, 'file_url': 'https://api.onehealth.gov.in/storage/uploads/samples/proc.mp4'},
        ],
        'documents': [
          {'attachment_id': 703, 'file_url': 'https://api.onehealth.gov.in/storage/uploads/samples/chain.pdf'},
        ],
        'attachments': [
          {
            'attachment_id': 701,
            'file_kind': 'IMAGE',
            'file_name': 'sample_vial.jpg',
            'storage_path': 'uploads/samples/sample_vial.jpg',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/samples/sample_vial.jpg',
          },
          {
            'attachment_id': 702,
            'file_kind': 'VIDEO',
            'file_name': 'proc.mp4',
            'storage_path': 'uploads/samples/proc.mp4',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/samples/proc.mp4',
          },
          {
            'attachment_id': 703,
            'file_kind': 'DOCUMENT',
            'file_name': 'chain.pdf',
            'storage_path': 'uploads/samples/chain.pdf',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/samples/chain.pdf',
          },
        ],
      };

      final sample = SampleSupportRecordModel.fromJson(backendJson);
      expect(sample.attachments.length, 3);
      expect(sample.photos.every((p) => !p.startsWith('{')), isTrue);

      final photos = <String>[];
      final videos = <String>[];
      final documents = <String>[];

      if (sample.attachments.isNotEmpty) {
        for (final att in sample.attachments) {
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

      expect(photos.length, 1);
      expect(videos.length, 1);
      expect(documents.length, 1);
    });

    test('Success Stories: Does not duplicate attachments when both attachments and urls exist', () {
      final backendJson = {
        'id': 401,
        'title': 'Canine Rabies Eradication Success',
        'story_date': '2026-10-26',
        'photos': [
          {'attachment_id': 801, 'file_url': 'https://api.onehealth.gov.in/storage/uploads/stories/hero.jpg'},
        ],
        'videos': [
          {'attachment_id': 802, 'file_url': 'https://api.onehealth.gov.in/storage/uploads/stories/interview.mp4'},
        ],
        'documents': [
          {'attachment_id': 803, 'file_url': 'https://api.onehealth.gov.in/storage/uploads/stories/case_study.pdf'},
        ],
        'attachments': [
          {
            'attachment_id': 801,
            'file_kind': 'IMAGE',
            'file_name': 'hero.jpg',
            'storage_path': 'uploads/stories/hero.jpg',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/stories/hero.jpg',
          },
          {
            'attachment_id': 802,
            'file_kind': 'VIDEO',
            'file_name': 'interview.mp4',
            'storage_path': 'uploads/stories/interview.mp4',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/stories/interview.mp4',
          },
          {
            'attachment_id': 803,
            'file_kind': 'DOCUMENT',
            'file_name': 'case_study.pdf',
            'storage_path': 'uploads/stories/case_study.pdf',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/stories/case_study.pdf',
          },
        ],
      };

      final story = SuccessStoryRecordModel.fromJson(backendJson);
      expect(story.attachments.length, 3);

      final photos = <String>[];
      final videos = <String>[];
      final existingDocs = <String>[];

      if (story.attachments.isNotEmpty) {
        for (final att in story.attachments) {
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

      expect(photos.length, 1);
      expect(videos.length, 1);
      expect(existingDocs.length, 1);
    });

    test('Capacity Building (Imparted & Attended): richAttachments single source of truth', () {
      final impartedJson = {
        'training_imparted_id': 501,
        'training_id': 2,
        'training_name': 'Zoonotic Disease Surveillance',
        'training_date': '2026-10-26',
        'photos': ['https://api.onehealth.gov.in/storage/uploads/training/group.jpg'],
        'documents': ['https://api.onehealth.gov.in/storage/uploads/training/handout.pdf'],
        'attachments': [
          {
            'attachment_id': 901,
            'file_kind': 'IMAGE',
            'file_name': 'group.jpg',
            'storage_path': 'uploads/training/group.jpg',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/training/group.jpg',
          },
          {
            'attachment_id': 902,
            'file_kind': 'DOCUMENT',
            'file_name': 'handout.pdf',
            'storage_path': 'uploads/training/handout.pdf',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/training/handout.pdf',
          },
        ],
      };

      final imparted = TrainingImpartedRecordModel.fromJson(impartedJson);
      expect(imparted.richAttachments.length, 2);

      final existingPhotos = <String>[];
      final existingDocs = <String>[];

      if (imparted.richAttachments.isNotEmpty) {
        for (final att in imparted.richAttachments) {
          final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(existingPhotos, path)) existingPhotos.add(path);
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(existingDocs, path)) existingDocs.add(path);
            }
          }
        }
      }

      expect(existingPhotos.length, 1);
      expect(existingDocs.length, 1);

      // Now verify Training Attended model
      final attendedJson = {
        'training_attended_id': 601,
        'training_id': 2,
        'training_name': 'Zoonotic Disease Surveillance',
        'training_date': '2026-10-26',
        'photos': ['https://api.onehealth.gov.in/storage/uploads/training/cert.jpg'],
        'documents': ['https://api.onehealth.gov.in/storage/uploads/training/notes.pdf'],
        'attachments': [
          {
            'attachment_id': 951,
            'file_kind': 'IMAGE',
            'file_name': 'cert.jpg',
            'storage_path': 'uploads/training/cert.jpg',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/training/cert.jpg',
          },
          {
            'attachment_id': 952,
            'file_kind': 'DOCUMENT',
            'file_name': 'notes.pdf',
            'storage_path': 'uploads/training/notes.pdf',
            'file_url': 'https://api.onehealth.gov.in/storage/uploads/training/notes.pdf',
          },
        ],
      };

      final attended = TrainingAttendedRecordModel.fromJson(attendedJson);
      expect(attended.richAttachments.length, 2);

      final attendedPhotos = <String>[];
      final attendedDocs = <String>[];

      if (attended.richAttachments.isNotEmpty) {
        for (final att in attended.richAttachments) {
          final path = att.storagePath.isNotEmpty ? att.storagePath : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(attendedPhotos, path)) attendedPhotos.add(path);
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(attendedDocs, path)) attendedDocs.add(path);
            }
          }
        }
      }

      expect(attendedPhotos.length, 1);
      expect(attendedDocs.length, 1);
    });
  });
}
