import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/services/attachment_api_service.dart';
import 'package:cohv/core/widgets/attachments/attachment_preview_dialog.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/events/presentation/screen/event_report_detail_screen.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/referrals/presentation/screen/referral_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/awareness/presentation/screen/awareness_detail_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test_jwt_token',
    });
  });
  group('AppAttachmentItem Unit Tests', () {
    test('Correctly parses image, video, and document from JSON with all fields', () {
      final imgJson = {
        'attachment_id': 101,
        'file_kind': 'IMAGE',
        'file_name': 'test_photo.jpg',
        'storage_path': 'uploads/events/test_photo.jpg',
        'mime_type': 'image/jpeg',
        'size_bytes': 102400,
        'file_url': 'http://192.168.10.136:8000/api/attachments/101',
        'latitude': 28.609453,
        'longitude': 77.367519,
        'gps_accuracy_m': 11,
        'captured_at': '2026-10-26T04:03:00Z',
      };

      final imgItem = AppAttachmentItem.fromJson(imgJson);
      expect(imgItem.attachmentId, 101);
      expect(imgItem.isImage, isTrue);
      expect(imgItem.isVideo, isFalse);
      expect(imgItem.isDocument, isFalse);
      expect(imgItem.fileName, 'test_photo.jpg');
      expect(imgItem.mimeType, 'image/jpeg');
      expect(imgItem.sizeBytes, 102400);
      expect(imgItem.latitude, 28.609453);
      expect(imgItem.longitude, 77.367519);
      expect(imgItem.gpsAccuracyM, 11);
      expect(imgItem.capturedAt, isNotNull);

      // Geo-tag text contains lat, lng, accuracy, and capture timestamp
      final geoTag = imgItem.formatGeoTag();
      expect(geoTag, contains('28.609453, 77.367519'));
      expect(geoTag, contains('±11 m'));
      expect(geoTag, contains('2026'));

      // Serializes back to JSON correctly
      final serialized = imgItem.toJson();
      expect(serialized['attachment_id'], 101);
      expect(serialized['file_kind'], 'IMAGE');
    });

    test('Identifies video and document kinds correctly', () {
      final vidItem = AppAttachmentItem.fromJson({
        'attachment_id': 102,
        'file_kind': 'VIDEO',
        'file_name': 'sample_video.mp4',
        'storage_path': 'uploads/sample_video.mp4',
      });
      expect(vidItem.isVideo, isTrue);
      expect(vidItem.isImage, isFalse);
      expect(vidItem.isDocument, isFalse);

      final docItem = AppAttachmentItem.fromJson({
        'attachment_id': 103,
        'file_kind': 'DOCUMENT',
        'file_name': 'report_guide.pdf',
        'storage_path': 'uploads/report_guide.pdf',
      });
      expect(docItem.isDocument, isTrue);
      expect(docItem.isImage, isFalse);
      expect(docItem.isVideo, isFalse);
    });

    test('Resolves relative URLs against baseUrl and serverRoot', () {
      final relItem = AppAttachmentItem.fromJson({
        'attachment_id': 104,
        'file_kind': 'IMAGE',
        'file_name': 'relative.jpg',
        'file_url': '/attachments/104',
      });
      final urls = relItem.getCandidateUrls();
      expect(urls, isNotEmpty);
      expect(urls.any((u) => u.contains('${ApiConstants.serverRoot}/attachments/104')), isTrue);
    });

    test('Handles unavailable GPS gracefully with date fallback', () {
      final noGpsItem = AppAttachmentItem.fromJson({
        'attachment_id': 105,
        'file_kind': 'IMAGE',
        'file_name': 'no_gps.jpg',
        'captured_at': '2026-10-26T04:03:00Z',
      });
      final geoTag = noGpsItem.formatGeoTag();
      // Should show the formatted date/time instead of broken coordinates
      expect(geoTag, contains('2026'));
      expect(geoTag.contains('0.000000'), isFalse);
    });

    test('ApiConstants provides attachment streaming, download, and meta endpoints', () {
      expect(
        ApiConstants.endpointAttachmentStream(42),
        '${ApiConstants.baseUrl}/attachments/42',
      );
      expect(
        ApiConstants.endpointAttachmentDownload(42),
        '${ApiConstants.baseUrl}/attachments/42/download',
      );
      expect(
        ApiConstants.endpointAttachmentMeta(42),
        '${ApiConstants.baseUrl}/attachments/42/meta',
      );
    });
  });

  group('AttachmentApiService Tests', () {
    test('fetchAttachmentMeta returns parsed AppAttachmentItem on 200', () async {
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/meta')) {
          return http.Response(
            jsonEncode({
              'data': {
                'attachment_id': 77,
                'file_kind': 'IMAGE',
                'file_name': 'field_photo.jpg',
                'mime_type': 'image/jpeg',
                'size_bytes': 204800,
              }
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = AttachmentApiService(client: client);
      final meta = await service.fetchAttachmentMeta(77);
      expect(meta, isNotNull);
      expect(meta!.attachmentId, 77);
      expect(meta.fileName, 'field_photo.jpg');
    });

    test('downloadAttachment returns byte array on 200', () async {
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/download')) {
          return http.Response.bytes([1, 2, 3, 4, 5], 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = AttachmentApiService(client: client);
      final bytes = await service.downloadAttachment(88);
      expect(bytes, isNotNull);
      expect(bytes!.length, 5);
    });
  });

  group('AttachmentsSectionWidget & Preview Dialog Widget Tests', () {
    testWidgets('Renders ATTACHMENTS header and thumbnails with green badges', (tester) async {
      final attachments = [
        const AppAttachmentItem(
          attachmentId: 1,
          fileKind: 'VIDEO',
          fileName: 'video_clip.mp4',
        ),
        const AppAttachmentItem(
          attachmentId: 2,
          fileKind: 'IMAGE',
          fileName: 'photo_stamped.jpg',
        ),
        const AppAttachmentItem(
          attachmentId: 3,
          fileKind: 'DOCUMENT',
          fileName: 'guidelines.pdf',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentsSectionWidget(
              attachments: attachments,
              fallbackLatitude: 28.609453,
              fallbackLongitude: 77.367519,
              fallbackAccuracy: 11,
              fallbackDate: DateTime(2026, 10, 26, 4, 3),
            ),
          ),
        ),
      );

      // Verify ATTACHMENTS header
      expect(find.text('ATTACHMENTS'), findsOneWidget);

      // Verify Video placeholder with VIDEO text
      expect(find.text('VIDEO'), findsOneWidget);

      // Verify Document placeholder with DOC badge
      expect(find.text('DOC'), findsOneWidget);

      // Verify green circular badges (3 thumbnails = 3 camera icon badges)
      expect(find.byIcon(Icons.camera_alt), findsNWidgets(3));
    });

    testWidgets('Displays fallback text when attachments array is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttachmentsSectionWidget(attachments: []),
          ),
        ),
      );

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('No attachments uploaded.'), findsOneWidget);
    });

    testWidgets('Tapping image thumbnail opens preview dialog with geo-tag and Close button', (tester) async {
      final attachments = [
        const AppAttachmentItem(
          attachmentId: 2,
          fileKind: 'IMAGE',
          fileName: 'cohv_1792987427386.jpg',
          latitude: 28.609453,
          longitude: 77.367519,
          gpsAccuracyM: 11,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentsSectionWidget(
              attachments: attachments,
              fallbackDate: DateTime(2026, 10, 26, 4, 3),
            ),
          ),
        ),
      );

      // Tap on thumbnail
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Verify Dialog opens
      expect(find.byType(AttachmentPreviewDialog), findsOneWidget);
      expect(find.text('cohv_1792987427386.jpg'), findsOneWidget);

      // Verify geo-tag stamp overlay text
      expect(find.textContaining('28.609453, 77.367519 · ±11 m'), findsOneWidget);

      // Verify Close button
      expect(find.text('Close'), findsOneWidget);

      // Tap Close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog closed
      expect(find.byType(AttachmentPreviewDialog), findsNothing);
    });

    testWidgets('Tapping video thumbnail opens video preview player with controls and Close button', (tester) async {
      final attachments = [
        const AppAttachmentItem(
          attachmentId: 1,
          fileKind: 'VIDEO',
          fileName: '1000140298.mp4',
          latitude: 28.609453,
          longitude: 77.367519,
          gpsAccuracyM: 11,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentsSectionWidget(
              attachments: attachments,
              fallbackDate: DateTime(2026, 10, 26, 4, 3),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Verify Video Preview dialog
      expect(find.byType(AttachmentPreviewDialog), findsOneWidget);
      expect(find.text('1000140298.mp4'), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
      expect(find.textContaining('28.609453, 77.367519 · ±11 m'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentPreviewDialog), findsNothing);
    });

    testWidgets('Tapping document thumbnail opens document preview with Open file button', (tester) async {
      final attachments = [
        const AppAttachmentItem(
          attachmentId: 3,
          fileKind: 'DOCUMENT',
          fileName: 'guidelines_v1.pdf',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentsSectionWidget(
              attachments: attachments,
              fallbackDate: DateTime(2026, 10, 26, 4, 4),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Verify Document Preview dialog with "Open file" button
      expect(find.byType(AttachmentPreviewDialog), findsOneWidget);
      expect(find.text('Open file'), findsOneWidget);
      expect(find.text('guidelines_v1.pdf'), findsWidgets);

      // Tap Open file
      await tester.tap(find.text('Open file'));
      await tester.pump();

      // Tap Close
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentPreviewDialog), findsNothing);
    });
  });

  group('Feature Integration Tests (Event Report, Referral, Awareness Activity)', () {
    testWidgets('EventReportDetailScreen displays AttachmentsSectionWidget with event attachments', (tester) async {
      final event = EventReportItem(
        id: 'VISIT-26-0003',
        numericId: 15,
        eventType: 'Suspected anthrax in animals',
        primarySector: 'Animal Health',
        eventDate: DateTime(2026, 10, 26, 11, 0),
        village: 'Amrabad',
        latitude: 28.609453,
        longitude: 77.367519,
        gpsAccuracyM: 11,
        attachments: const [
          AppAttachmentItem(
            attachmentId: 201,
            fileKind: 'IMAGE',
            fileName: 'event_animal.jpg',
          ),
          AppAttachmentItem(
            attachmentId: 202,
            fileKind: 'VIDEO',
            fileName: 'event_symptoms.mp4',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EventReportDetailScreen(
            event: event,
            volunteerId: 'COHV-26-0004',
          ),
        ),
      );

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsNWidgets(2));
    });

    testWidgets('ReferralDetailScreen displays AttachmentsSectionWidget inside main card below GPS location', (tester) async {
      final referral = ReferralItem(
        id: 'REF-26-0011',
        referralId: 11,
        facilityName: 'CHC',
        stream: 'HUMAN',
        referralType: 'CHC',
        village: 'Vatvarlapally',
        eventDate: DateTime(2026, 10, 26),
        referralDate: DateTime(2026, 10, 26),
        isFollowedUp: false,
        latitude: 28.609453,
        longitude: 77.367519,
        accuracy: 11,
        volunteerId: 'COHV-26-0004',
        deviceId: 'DEV-TEST',
        attachments: const [
          ReferralAttachmentItem(
            attachmentId: 301,
            fileKind: 'VIDEO',
            fileName: 'referral_video.mp4',
            storagePath: 'referral_video.mp4',
          ),
          ReferralAttachmentItem(
            attachmentId: 302,
            fileKind: 'IMAGE',
            fileName: 'referral_photo.jpg',
            storagePath: 'referral_photo.jpg',
          ),
          ReferralAttachmentItem(
            attachmentId: 303,
            fileKind: 'DOCUMENT',
            fileName: 'referral_slip.pdf',
            storagePath: 'referral_slip.pdf',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReferralDetailScreen(referral: referral),
        ),
      );

      // Verify GPS location is shown
      expect(find.text('GPS location'), findsOneWidget);
      expect(find.textContaining('28.609453, 77.367519'), findsWidgets);

      // Verify ATTACHMENTS row is present
      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);
      expect(find.text('DOC'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsNWidgets(3));

      // Verify Back button
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('AwarenessDetailScreen displays AttachmentsSectionWidget with awareness attachments', (tester) async {
      final activity = AwarenessItem(
        id: 'AWR-26-0006',
        awarenessId: 6,
        activityType: 'Village meetings',
        date: DateTime(2026, 10, 26),
        village: 'Amrabad',
        peopleReached: 25,
        topicCovered: 'Zoonotic Diseases',
        departmentInvolved: 'Public Health Department',
        latitude: 28.609453,
        longitude: 77.367519,
        accuracy: 11,
        volunteerId: 'COHV-26-0004',
        deviceId: 'DEV-TEST',
        attachments: const [
          AwarenessAttachmentItem(
            attachmentId: 401,
            fileKind: 'IMAGE',
            fileName: 'meeting_pic.jpg',
            storagePath: 'meeting_pic.jpg',
          ),
          AwarenessAttachmentItem(
            attachmentId: 402,
            fileKind: 'DOCUMENT',
            fileName: 'pamphlet.pdf',
            storagePath: 'pamphlet.pdf',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AwarenessDetailScreen(activity: activity),
        ),
      );

      expect(find.text('ATTACHMENTS'), findsOneWidget);
      expect(find.text('DOC'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsNWidgets(2));

      await tester.scrollUntilVisible(find.text('Back'), 200);
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
