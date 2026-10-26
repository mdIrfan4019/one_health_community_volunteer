import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/services/attachment_api_service.dart';
import 'package:cohv/core/widgets/attachments/attachment_preview_dialog.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';

import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/sample_reprot/data/sample_support_api_service.dart';
import 'package:cohv/features/sample_reprot/screens/sample_support_screen.dart';

import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/success_stories/data/success_story_api_service.dart';
import 'package:cohv/features/success_stories/screens/success_story_detail_screen.dart';

import 'package:cohv/features/capacity_building/domain/capacity_building_models.dart';
import 'package:cohv/features/capacity_building/data/capacity_building_api_service.dart';
import 'package:cohv/features/capacity_building/screens/training_imparted_detail_screen.dart';
import 'package:cohv/features/capacity_building/screens/training_attended_detail_screen.dart';

import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test_auth_token_jwt',
      'user_id': '4',
      'volunteer_id': 'COHV-26-0004',
    });
  });

  group('Awareness Activity Video Upload Fix Tests', () {
    test('AwarenessActivityCreateRequest retains and passes videos list', () {
      final req = AwarenessActivityCreateRequest(
        awarenessActivityId: 1,
        activityDate: DateTime(2026, 10, 26),
        villageLgdCode: 580001,
        photos: ['photo1.jpg'],
        videos: ['video1.mp4', 'video2.mov'],
        documents: ['doc1.pdf'],
      );

      expect(req.videos.length, 2);
      expect(req.videos.first, 'video1.mp4');
    });

    test('AwarenessApiService attaches videos to multipart request', () async {
      final tempDir = Directory.systemTemp.createTempSync('awareness_test');
      final tempVideo = File('${tempDir.path}/test_clip.mp4')
        ..writeAsStringSync('fake video bytes');
      final tempPhoto = File('${tempDir.path}/test_img.jpg')
        ..writeAsStringSync('fake img bytes');

      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      bool videoFieldFound = false;
      bool photoFieldFound = false;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        final bodyBytes = await bodyStream.toBytes();
        final bodyStr = String.fromCharCodes(bodyBytes);

        if (bodyStr.contains('name="videos"')) {
          videoFieldFound = true;
        }
        if (bodyStr.contains('name="photos"')) {
          photoFieldFound = true;
        }

        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'message': 'Created successfully',
                'awareness_id': 99,
                'awareness_code': 'AWR-26-0099',
                'verification_status': 'SUBMITTED',
              }),
            ),
          ),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AwarenessApiService(client: mockClient);
      final req = AwarenessActivityCreateRequest(
        awarenessActivityId: 2,
        activityDate: DateTime(2026, 10, 26),
        villageLgdCode: 580001,
        photos: [tempPhoto.path],
        videos: [tempVideo.path],
      );

      final res = await service.submitAwarenessActivity(req);
      expect(res.awarenessId, 99);
      expect(videoFieldFound, isTrue);
      expect(photoFieldFound, isTrue);
    });
  });

  group('Sample Support Upload Fix & Attachments Tests', () {
    test('SampleSupportCreateRequest retains media and serializes JSON fallback', () {
      const req = SampleSupportCreateRequest(
        volunteerId: 4,
        clientRef: 'SMP-REF-01',
        deviceId: 'DEV-01',
        sampleTypeId: 1,
        sampleDate: '2026-10-26',
        sampleCount: 3,
        villageLgdCode: 580001,
        latitude: 25.28,
        longitude: 82.95,
        gpsAccuracyM: 20,
        capturedAt: '2026-10-26T04:00:00Z',
        photos: ['photo.jpg'],
        videos: ['video.mp4'],
        documents: ['doc.pdf'],
      );

      expect(req.photos, ['photo.jpg']);
      expect(req.videos, ['video.mp4']);
      expect(req.documents, ['doc.pdf']);

      final json = req.toJson();
      expect(json['photos'], ['photo.jpg']);
      expect(json['videos'], ['video.mp4']);
      expect(json['documents'], ['doc.pdf']);
    });

    test('SampleSupportApiService submits multipart request when media is present', () async {
      final tempDir = Directory.systemTemp.createTempSync('smp_test');
      final tempPhoto = File('${tempDir.path}/sample.jpg')..writeAsStringSync('dummy photo');
      final tempVideo = File('${tempDir.path}/sample.mp4')..writeAsStringSync('dummy video');
      final tempDoc = File('${tempDir.path}/sample.pdf')..writeAsStringSync('dummy doc');

      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      bool photosAttached = false;
      bool videosAttached = false;
      bool docsAttached = false;
      bool volunteerIdAttached = false;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        final bodyBytes = await bodyStream.toBytes();
        final bodyStr = String.fromCharCodes(bodyBytes);

        if (bodyStr.contains('name="photos"')) photosAttached = true;
        if (bodyStr.contains('name="videos"')) videosAttached = true;
        if (bodyStr.contains('name="documents"')) docsAttached = true;
        if (bodyStr.contains('name="volunteer_id"')) volunteerIdAttached = true;

        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'message': 'Sample support created successfully',
                'data': {
                  'sample_id': 55,
                  'sample_code': 'SMP-26-0055',
                  'sample_type_name': 'Human samples',
                  'sample_count': 3,
                },
              }),
            ),
          ),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SampleSupportApiService(client: mockClient);
      final req = SampleSupportCreateRequest(
        volunteerId: 4,
        clientRef: 'SMP-REF-02',
        deviceId: 'DEV-01',
        sampleTypeId: 1,
        sampleDate: '2026-10-26',
        sampleCount: 3,
        villageLgdCode: 580001,
        latitude: 25.28,
        longitude: 82.95,
        gpsAccuracyM: 20,
        capturedAt: '2026-10-26T04:00:00Z',
        photos: [tempPhoto.path],
        videos: [tempVideo.path],
        documents: [tempDoc.path],
      );

      final res = await service.submitSampleSupport(req);
      expect(res.success, isTrue);
      expect(res.sampleId, 55);
      expect(photosAttached, isTrue);
      expect(videosAttached, isTrue);
      expect(docsAttached, isTrue);
      expect(volunteerIdAttached, isTrue);
    });

    test('SampleSupportRecordModel parses attachments list and creates AppAttachmentItem', () {
      final json = {
        'sample_id': 10,
        'sample_code': 'SMP-26-0010',
        'sample_type_id': 1,
        'sample_type_name': 'Human samples',
        'sample_date': '2026-10-26',
        'sample_count': 2,
        'latitude': 25.281198,
        'longitude': 82.953928,
        'gps_accuracy_m': 22,
        'attachments': [
          {
            'attachment_id': 301,
            'file_kind': 'IMAGE',
            'file_name': 'vial_photo.jpg',
            'storage_path': 'uploads/vial_photo.jpg',
            'latitude': 25.281198,
            'longitude': 82.953928,
            'gps_accuracy_m': 22,
            'captured_at': '2026-10-26T08:30:00Z',
          },
          {
            'attachment_id': 302,
            'file_kind': 'VIDEO',
            'file_name': 'collection_procedure.mp4',
            'storage_path': 'uploads/collection_procedure.mp4',
          },
          {
            'attachment_id': 303,
            'file_kind': 'DOCUMENT',
            'file_name': 'lab_manifest.pdf',
            'storage_path': 'uploads/lab_manifest.pdf',
          },
        ],
      };

      final record = SampleSupportRecordModel.fromJson(json);
      expect(record.appAttachments.length, 3);
      expect(record.appAttachments[0].isImage, isTrue);
      expect(record.appAttachments[0].fileName, 'vial_photo.jpg');
      expect(record.appAttachments[1].isVideo, isTrue);
      expect(record.appAttachments[2].isDocument, isTrue);

      final geoTag = record.appAttachments[0].formatGeoTag();
      expect(geoTag, contains('25.281198, 82.953928'));
      expect(geoTag, contains('±22 m'));
    });

    testWidgets('SampleReportDetailScreen renders AttachmentsSectionWidget and opens preview', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testRecord = SampleSupportRecordModel(
        sampleId: 10,
        sampleCode: 'SMP-26-0010',
        sampleTypeId: 1,
        sampleTypeName: 'Human samples',
        sampleDate: '2026-10-26',
        sampleCount: 2,
        latitude: 25.281198,
        longitude: 82.953928,
        gpsAccuracyM: 22,
        attachments: [
          const AppAttachmentItem(
            attachmentId: 301,
            fileKind: 'IMAGE',
            fileName: 'vial_photo.jpg',
            latitude: 25.281198,
            longitude: 82.953928,
            gpsAccuracyM: 22,
          ),
          const AppAttachmentItem(
            attachmentId: 302,
            fileKind: 'VIDEO',
            fileName: 'collection.mp4',
          ),
          const AppAttachmentItem(
            attachmentId: 303,
            fileKind: 'DOCUMENT',
            fileName: 'manifest.pdf',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SampleReportDetailScreen(
            sampleId: 10,
            initialRecord: testRecord,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.text('DOC'), findsOneWidget);

      // Tap on Video thumbnail to open AttachmentPreviewDialog
      await tester.tap(find.text('VIDEO'));
      await tester.pumpAndSettle();

      // Check dialog opened
      expect(find.text('collection.mp4'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsNothing);
    });
  });

  group('Success Story Upload Fix & Attachments Tests', () {
    test('SuccessStoryCreateRequest includes photos, videos, and documents', () {
      const req = SuccessStoryCreateRequest(
        volunteerId: 4,
        clientRef: 'STY-01',
        deviceId: 'DEV-01',
        title: 'Rabies Awareness Drive',
        storyDate: '2026-10-26',
        locationText: 'Amrabad GP',
        oneHealthIssue: 'Rabies prevention',
        situation: 'Lack of pet vaccination',
        actionTaken: 'Door-to-door drive',
        departmentId: 1,
        outcome: '95% vaccination achieved',
        latitude: 25.28,
        longitude: 82.95,
        gpsAccuracyM: 20,
        photos: ['photo1.jpg'],
        videos: ['video1.mp4'],
        documents: ['doc1.pdf'],
      );

      final json = req.toJson();
      expect(json['photos'], ['photo1.jpg']);
      expect(json['videos'], ['video1.mp4']);
      expect(json['documents'], ['doc1.pdf']);
    });

    test('SuccessStoryApiService sends multipart with media attachments', () async {
      final tempDir = Directory.systemTemp.createTempSync('sty_test');
      final tempPhoto = File('${tempDir.path}/story.jpg')..writeAsStringSync('dummy photo');
      final tempVideo = File('${tempDir.path}/story.mp4')..writeAsStringSync('dummy video');
      final tempDoc = File('${tempDir.path}/story.pdf')..writeAsStringSync('dummy doc');

      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      bool photosSent = false;
      bool videosSent = false;
      bool docsSent = false;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        final bodyBytes = await bodyStream.toBytes();
        final bodyStr = String.fromCharCodes(bodyBytes);

        if (bodyStr.contains('name="photos"')) photosSent = true;
        if (bodyStr.contains('name="videos"')) videosSent = true;
        if (bodyStr.contains('name="documents"')) docsSent = true;

        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'message': 'Success story submitted successfully',
                'story_id': 88,
                'story_code': 'STY-26-0088',
              }),
            ),
          ),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SuccessStoryApiService(client: mockClient);
      const req = SuccessStoryCreateRequest(
        volunteerId: 4,
        clientRef: 'STY-02',
        deviceId: 'DEV-01',
        title: 'Zoonotic Disease Workshop',
        storyDate: '2026-10-26',
        locationText: 'Amrabad GP',
        oneHealthIssue: 'Zoonosis',
        situation: 'Community education',
        actionTaken: 'Conducted session',
        departmentId: 1,
        outcome: 'Positive feedback',
        latitude: 25.28,
        longitude: 82.95,
        gpsAccuracyM: 20,
      );

      final reqWithMedia = SuccessStoryCreateRequest(
        volunteerId: req.volunteerId,
        clientRef: req.clientRef,
        deviceId: req.deviceId,
        title: req.title,
        storyDate: req.storyDate,
        locationText: req.locationText,
        oneHealthIssue: req.oneHealthIssue,
        situation: req.situation,
        actionTaken: req.actionTaken,
        departmentId: req.departmentId,
        outcome: req.outcome,
        latitude: req.latitude,
        longitude: req.longitude,
        gpsAccuracyM: req.gpsAccuracyM,
        photos: [tempPhoto.path],
        videos: [tempVideo.path],
        documents: [tempDoc.path],
      );

      final res = await service.submitSuccessStory(reqWithMedia);
      expect(res.success, isTrue);
      expect(res.storyId, 88);
      expect(photosSent, isTrue);
      expect(videosSent, isTrue);
      expect(docsSent, isTrue);
    });

    testWidgets('SuccessStoryDetailScreen renders AttachmentsSectionWidget with preview and geo-tag', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const story = SuccessStoryRecordModel(
        storyId: 88,
        storyCode: 'STY-26-0088',
        title: 'Rabies Elimination Milestone',
        storyDate: '2026-10-26',
        locationText: 'Nagarkurnool',
        oneHealthIssue: 'Rabies',
        situation: 'Challenge',
        actionTaken: 'Intervention',
        outcome: 'Zero rabies cases',
        latitude: 25.281198,
        longitude: 82.953928,
        gpsAccuracyM: 15,
        attachments: [
          AppAttachmentItem(
            attachmentId: 501,
            fileKind: 'IMAGE',
            fileName: 'success_banner.jpg',
            latitude: 25.281198,
            longitude: 82.953928,
            gpsAccuracyM: 15,
          ),
          AppAttachmentItem(
            attachmentId: 502,
            fileKind: 'VIDEO',
            fileName: 'community_celebration.mp4',
            latitude: 25.281198,
            longitude: 82.953928,
            gpsAccuracyM: 15,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SuccessStoryDetailScreen(
            storyId: 88,
            initialStory: story,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);

      // Tap video thumbnail to view AttachmentPreviewDialog with geo-tag
      await tester.tap(find.text('VIDEO'));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentPreviewDialog), findsOneWidget);
      expect(find.text('community_celebration.mp4'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AttachmentPreviewDialog),
          matching: find.textContaining('25.281198, 82.953928'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AttachmentPreviewDialog),
          matching: find.textContaining('±15 m'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsNothing);
    });
  });

  group('Training Imparted & Attended Attachments Tests', () {
    test('TrainingImpartedRecordModel exposes appAttachments from rich and fallback lists', () {
      final json = {
        'training_imparted_id': 12,
        'training_imparted_code': 'TRI-26-0012',
        'training_id': 1,
        'training_name': 'One Health Surveillance Training',
        'training_date': '2026-10-26',
        'photos': ['photo_a.jpg'],
        'videos': ['video_b.mp4'],
        'documents': ['guide_c.pdf'],
        'attachments': [
          {
            'attachment_id': 701,
            'file_kind': 'IMAGE',
            'file_name': 'attendees.jpg',
            'storage_path': 'uploads/attendees.jpg',
          },
        ],
      };

      final record = TrainingImpartedRecordModel.fromJson(json);
      expect(record.appAttachments.length, 1);
      expect(record.appAttachments.first.fileName, 'attendees.jpg');

      // Test fallback when rich attachments is empty
      final jsonFallback = {
        'training_imparted_id': 13,
        'training_imparted_code': 'TRI-26-0013',
        'training_id': 1,
        'training_name': 'Field Sampling Basics',
        'training_date': '2026-10-26',
        'photos': ['photo_a.jpg'],
        'videos': ['video_b.mp4'],
        'documents': ['guide_c.pdf'],
      };
      final fallbackRecord = TrainingImpartedRecordModel.fromJson(jsonFallback);
      expect(fallbackRecord.appAttachments.length, 3);
      expect(fallbackRecord.appAttachments[0].isImage, isTrue);
      expect(fallbackRecord.appAttachments[1].isVideo, isTrue);
      expect(fallbackRecord.appAttachments[2].isDocument, isTrue);
    });

    testWidgets('TrainingImpartedDetailScreen renders AttachmentsSectionWidget', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const record = TrainingImpartedRecordModel(
        trainingImpartedId: 12,
        trainingImpartedCode: 'TRI-26-0012',
        trainingId: 1,
        trainingName: 'Community Surveillance',
        trainingDate: '2026-10-26',
        photos: ['photo1.jpg'],
        documents: ['agenda.pdf'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingImpartedDetailScreen(
            record: record,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('DOC'), findsOneWidget);

      // Tap document thumbnail
      await tester.tap(find.text('DOC'));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentPreviewDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AttachmentPreviewDialog),
          matching: find.text('agenda.pdf'),
        ),
        findsNWidgets(2),
      );
      expect(find.text('Open file'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('TrainingAttendedDetailScreen renders AttachmentsSectionWidget', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const record = TrainingAttendedRecordModel(
        trainingAttendedId: 15,
        trainingAttendedCode: 'TRN-26-0015',
        trainingId: 2,
        trainingName: 'Vector Control Methods',
        trainingDate: '2026-10-26',
        photos: ['attendance.jpg'],
        videos: ['demonstration.mp4'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TrainingAttendedDetailScreen(
            record: record,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);

      // Tap video thumbnail
      await tester.tap(find.text('VIDEO'));
      await tester.pumpAndSettle();

      expect(find.text('demonstration.mp4'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });

  group('Shared Attachment APIs & Empty States', () {
    test('Shared endpoint URLs match OpenAPI specifications', () {
      expect(ApiConstants.endpointAttachmentStream(42), '${ApiConstants.baseUrl}/attachments/42');
      expect(ApiConstants.endpointAttachmentDownload(42), '${ApiConstants.baseUrl}/attachments/42/download');
      expect(ApiConstants.endpointAttachmentMeta(42), '${ApiConstants.baseUrl}/attachments/42/meta');
    });

    testWidgets('AttachmentsSectionWidget renders graceful empty state when empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttachmentsSectionWidget(
              attachments: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('No attachments uploaded.'), findsOneWidget);
    });
  });
}
