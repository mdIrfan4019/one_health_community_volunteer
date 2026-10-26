import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/success_stories/domain/success_story_models.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';

/// Test mock implementation for LocationService
class MockLocationService extends LocationService {
  GeoLocationData nextResult;
  bool startupRequested = false;

  MockLocationService({required this.nextResult}) : super.base();

  @override
  Future<bool> requestStartupPermission() async {
    startupRequested = true;
    return nextResult.isAvailable;
  }

  @override
  Future<GeoLocationData> getCurrentLocation({
    bool requestIfNeeded = true,
    Duration timeout = const Duration(seconds: 12),
    bool forceFresh = true,
  }) async {
    return nextResult;
  }
}

/// Test mock implementation for MediaPickerService
class MockMediaPickerService extends MediaPickerService {
  XFile? photoToReturn;
  XFile? videoToReturn;
  List<XFile> galleryPhotosToReturn = [];
  XFile? galleryVideoToReturn;
  List<PlatformFile> documentsToReturn = [];
  List<PlatformFile> imageFilesToReturn = [];

  MockMediaPickerService({
    this.photoToReturn,
    this.videoToReturn,
    this.galleryPhotosToReturn = const [],
    this.galleryVideoToReturn,
    this.documentsToReturn = const [],
    this.imageFilesToReturn = const [],
  }) : super.base();

  @override
  Future<XFile?> capturePhoto(BuildContext context) async {
    return photoToReturn;
  }

  @override
  Future<XFile?> recordVideo(BuildContext context) async {
    return videoToReturn;
  }

  @override
  Future<List<XFile>> pickImagesFromGallery(
    BuildContext context, {
    bool allowMultiple = true,
  }) async {
    return galleryPhotosToReturn;
  }

  @override
  Future<XFile?> pickVideoFromGallery(BuildContext context) async {
    return galleryVideoToReturn;
  }

  @override
  Future<List<PlatformFile>> pickDocuments(
    BuildContext context, {
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    return documentsToReturn;
  }

  @override
  Future<List<PlatformFile>> pickImageFiles(
    BuildContext context, {
    bool allowMultiple = true,
  }) async {
    return imageFilesToReturn;
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() {
    LocationService.setMockInstance(null);
    MediaPickerService.setMockInstance(null);
  });

  group('GeoLocationData Unit Tests', () {
    test('Success state holds exact coordinates, accuracy, and timestamp', () {
      final now = DateTime.now();
      final data = GeoLocationData.success(
        latitude: 17.385044,
        longitude: 78.486671,
        accuracyM: 8,
        timestamp: now,
      );

      expect(data.isAvailable, isTrue);
      expect(data.status, LocationFetchStatus.success);
      expect(data.latitude, 17.385044);
      expect(data.longitude, 78.486671);
      expect(data.accuracyM, 8);
      expect(data.timestamp, now);
      expect(data.displayText, contains('17.385044, 78.486671'));
      expect(data.displayText, contains('±8 m'));
    });

    test('Service disabled state has null coordinates and explains GPS is off', () {
      final data = GeoLocationData.serviceDisabled();

      expect(data.isAvailable, isFalse);
      expect(data.status, LocationFetchStatus.serviceDisabled);
      expect(data.latitude, isNull);
      expect(data.longitude, isNull);
      expect(data.accuracyM, isNull);
      expect(data.displayText, 'GPS / Location Service Disabled');
      expect(data.errorMessage, contains('Location services are disabled'));
    });

    test('Permission denied state has null coordinates and explains permission needed', () {
      final data = GeoLocationData.permissionDenied();

      expect(data.isAvailable, isFalse);
      expect(data.status, LocationFetchStatus.permissionDenied);
      expect(data.latitude, isNull);
      expect(data.longitude, isNull);
      expect(data.displayText, 'Location Permission Denied');
      expect(data.errorMessage, contains('Location permission was denied'));
    });

    test('Permanently denied state directs user to device settings', () {
      final data = GeoLocationData.permissionPermanentlyDenied();

      expect(data.isAvailable, isFalse);
      expect(data.status, LocationFetchStatus.permissionPermanentlyDenied);
      expect(data.latitude, isNull);
      expect(data.longitude, isNull);
      expect(data.displayText, contains('Open Settings'));
      expect(data.errorMessage, contains('permanently denied'));
    });

    test('Timeout state indicates signal acquisition failure', () {
      final data = GeoLocationData.timeout();

      expect(data.isAvailable, isFalse);
      expect(data.status, LocationFetchStatus.timeout);
      expect(data.displayText, 'GPS Signal Timeout');
    });

    test('Generic error state includes custom error message', () {
      final data = GeoLocationData.error('Hardware sensor unreadable');

      expect(data.isAvailable, isFalse);
      expect(data.status, LocationFetchStatus.error);
      expect(data.displayText, 'Hardware sensor unreadable');
    });
  });

  group('LocationService Mock Integration Tests', () {
    test('Returns genuine GPS fix when permission and service are active', () async {
      final mock = MockLocationService(
        nextResult: GeoLocationData.success(
          latitude: 16.506174,
          longitude: 80.648015,
          accuracyM: 5,
          timestamp: DateTime.now(),
        ),
      );
      LocationService.setMockInstance(mock);

      final loc = await LocationService().getCurrentLocation();

      expect(loc.isAvailable, isTrue);
      expect(loc.latitude, 16.506174);
      expect(loc.longitude, 80.648015);
      expect(loc.accuracyM, 5);
      expect(loc.status, LocationFetchStatus.success);
    });

    test('Startup permission request marks startupRequested', () async {
      final mock = MockLocationService(
        nextResult: GeoLocationData.permissionDenied(),
      );
      LocationService.setMockInstance(mock);

      final granted = await LocationService().requestStartupPermission();

      expect(granted, isFalse);
      expect(mock.startupRequested, isTrue);
    });

    test('Handles disabled GPS gracefully without throwing', () async {
      final mock = MockLocationService(
        nextResult: GeoLocationData.serviceDisabled(),
      );
      LocationService.setMockInstance(mock);

      final loc = await LocationService().getCurrentLocation();

      expect(loc.isAvailable, isFalse);
      expect(loc.status, LocationFetchStatus.serviceDisabled);
      expect(loc.latitude, isNull);
      expect(loc.longitude, isNull);
    });
  });

  group('MediaPickerService Integration Tests', () {
    testWidgets('Photo capture returns XFile', (tester) async {
      final mock = MockMediaPickerService(
        photoToReturn: XFile('path/to/captured_photo.jpg'),
      );
      MediaPickerService.setMockInstance(mock);

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final photo = await MediaPickerService().capturePhoto(context);
              expect(photo, isNotNull);
              expect(photo!.path, 'path/to/captured_photo.jpg');
            },
            child: const Text('Capture'),
          );
        }),
      ));

      await tester.tap(find.text('Capture'));
      await tester.pump();
    });

    testWidgets('Video recording returns XFile', (tester) async {
      final mock = MockMediaPickerService(
        videoToReturn: XFile('path/to/recorded_video.mp4'),
      );
      MediaPickerService.setMockInstance(mock);

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final video = await MediaPickerService().recordVideo(context);
              expect(video, isNotNull);
              expect(video!.path, 'path/to/recorded_video.mp4');
            },
            child: const Text('Record'),
          );
        }),
      ));

      await tester.tap(find.text('Record'));
      await tester.pump();
    });

    testWidgets('Gallery photo picker returns list of XFiles', (tester) async {
      final mock = MockMediaPickerService(
        galleryPhotosToReturn: [
          XFile('path/to/gallery1.jpg'),
          XFile('path/to/gallery2.jpg'),
        ],
      );
      MediaPickerService.setMockInstance(mock);

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final photos = await MediaPickerService().pickImagesFromGallery(context);
              expect(photos.length, 2);
              expect(photos.first.path, 'path/to/gallery1.jpg');
            },
            child: const Text('Gallery'),
          );
        }),
      ));

      await tester.tap(find.text('Gallery'));
      await tester.pump();
    });

    testWidgets('Document picker returns list of PlatformFiles', (tester) async {
      final mock = MockMediaPickerService(
        documentsToReturn: [],
      );
      MediaPickerService.setMockInstance(mock);

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final docs = await MediaPickerService().pickDocuments(context);
              expect(docs, isA<List<PlatformFile>>());
              expect(docs, isEmpty);
            },
            child: const Text('Docs'),
          );
        }),
      ));

      await tester.tap(find.text('Docs'));
      await tester.pump();
    });
  });

  group('No Fake Coordinates Verification Across Domain Requests', () {
    test('EventReportRequest handles null coordinates when GPS unavailable', () {
      final request = EventReportRequest(
        eventTypeId: 1,
        eventType: 'Suspected Anthrax',
        primarySector: 'human',
        date: DateTime(2026, 10, 26),
        time: '10:00',
        villageLgdCode: 200,
        village: 'Achampet',
        isOutOfAreaVisit: false,
        purposeOfVisit: 'Surveillance',
        locationType: 'Field',
        totalVisits: 1,
        populationTypeId: 1,
        targetPopulation: 'Farmers',
        observations: 'Two cattle dead',
        actionTaken: 'Isolated herd',
        isReferralGenerated: false,
        isAlertGenerated: false,
        isFollowUpRequired: false,
        volunteerId: 'COHV-26-0001',
        deviceId: 'DEV-TEST',
        latitude: null,
        longitude: null,
        accuracy: null,
        gpsUnavailableReason: 'GPS service disabled by user',
      );

      final json = request.toJson();
      expect(json['latitude'], isNull);
      expect(json['longitude'], isNull);
      expect(json['accuracy'], isNull);
      expect(json['gps_unavailable_reason'], 'GPS service disabled by user');
    });

    test('ReferralCreateRequest supports null coordinates with reason', () {
      final request = ReferralCreateRequest(
        volunteerId: 1,
        referralStream: 'human',
        referralFacilityId: 1,
        villageLgdCode: 200,
        eventDate: DateTime(2026, 10, 26),
        referralDate: DateTime(2026, 10, 26),
        reason: 'High fever',
        latitude: null,
        longitude: null,
        gpsAccuracyM: null,
        gpsUnavailableReason: 'Permission denied',
      );

      final json = request.toJson();
      expect(json.containsKey('latitude'), isFalse);
      expect(json.containsKey('longitude'), isFalse);
      expect(json['gps_unavailable_reason'], 'Permission denied');
    });

    test('AwarenessActivityCreateRequest supports null coordinates with reason', () {
      final request = AwarenessActivityCreateRequest(
        awarenessActivityId: 1,
        activityDate: DateTime(2026, 10, 26),
        villageLgdCode: 200,
        latitude: null,
        longitude: null,
        gpsAccuracyM: null,
        gpsUnavailableReason: 'GPS timed out',
      );

      expect(request.latitude, isNull);
      expect(request.longitude, isNull);
      expect(request.gpsAccuracyM, isNull);
      expect(request.gpsUnavailableReason, 'GPS timed out');
    });

    test('SampleSupportCreateRequest supports null coordinates with reason', () {
      final request = SampleSupportCreateRequest(
        volunteerId: 1,
        clientRef: 'SMP-1001',
        deviceId: 'DEV-TEST',
        sampleTypeId: 1,
        sampleDate: '2026-10-26',
        sampleCount: 1,
        villageLgdCode: 200,
        capturedAt: '2026-10-26T10:00:00Z',
        latitude: null,
        longitude: null,
        gpsAccuracyM: null,
        gpsUnavailableReason: 'Location sensor unavailable',
      );

      expect(request.latitude, isNull);
      expect(request.longitude, isNull);
      expect(request.gpsAccuracyM, isNull);
      expect(request.gpsUnavailableReason, 'Location sensor unavailable');
    });

    test('SuccessStoryCreateRequest supports null coordinates with reason', () {
      final request = SuccessStoryCreateRequest(
        volunteerId: 1,
        clientRef: 'STY-1001',
        deviceId: 'DEV-TEST',
        title: 'Community Water Filtration',
        storyDate: '2026-10-26',
        locationText: 'Achampet',
        oneHealthIssue: 'Water contamination',
        situation: 'Turbid well water',
        actionTaken: 'Installed sand filtration',
        departmentId: 1,
        outcome: 'Clean water for 500 households',
        latitude: null,
        longitude: null,
        gpsAccuracyM: null,
        gpsUnavailableReason: 'Location disabled',
      );

      expect(request.latitude, isNull);
      expect(request.longitude, isNull);
      expect(request.gpsAccuracyM, isNull);
      expect(request.gpsUnavailableReason, 'Location disabled');
    });

    test('VolunteerRegistrationRequest supports null coordinates with reason', () {
      final request = VolunteerRegistrationRequest(
        volunteerName: 'Ravi Kumar',
        gender: 'Male',
        dateOfBirth: DateTime(1995, 5, 20),
        mobileNo: '9876543210',
        email: 'ravi@example.com',
        cohvType: 'Community Health',
        stateLgdCode: 36,
        districtLgdCode: 505,
        blockLgdCode: 450,
        gramPanchayatLgdCode: 100,
        villageLgdCode: 200,
        dateOfJoining: DateTime(2026, 1, 1),
        educationId: 1,
        professionId: 1,
        pin: '509375',
        latitude: null,
        longitude: null,
        gpsAccuracyM: null,
        gpsUnavailableReason: 'Location permission denied by user',
      );

      expect(request.latitude, isNull);
      expect(request.longitude, isNull);
      expect(request.gpsAccuracyM, isNull);
      expect(request.gpsUnavailableReason, 'Location permission denied by user');
    });

    test('Coordinates format to at most 6 decimal places matching user requirement', () {
      const rawLat = 28.609471238;
      const rawLng = 77.367523891;

      expect(GeoLocationData.formatCoordinate(rawLat), 28.609471);
      expect(GeoLocationData.formatCoordinate(rawLng), 77.367524);
      expect(GeoLocationData.formatCoordinateString(rawLat), '28.609471');
      expect(GeoLocationData.formatCoordinateString(rawLng), '77.367524');

      final loc = GeoLocationData.success(
        latitude: rawLat,
        longitude: rawLng,
        accuracyM: 11,
        timestamp: DateTime(2026, 10, 26, 13, 16),
      );

      expect(loc.latitude, 28.609471);
      expect(loc.longitude, 77.367524);
      expect(loc.accuracyM, 11); // Preserves accuracy in meters without rounding
      expect(loc.displayText, contains('28.609471, 77.367524'));

      // Event Report Request
      final evt = EventReportRequest(
        eventTypeId: 1,
        eventType: 'Disease Outbreak',
        primarySector: 'Health',
        date: DateTime.now(),
        time: '12:00:00',
        villageLgdCode: 101,
        village: 'Achampet',
        isOutOfAreaVisit: false,
        purposeOfVisit: 'Surveillance',
        locationType: 'Field',
        totalVisits: 1,
        populationTypeId: 1,
        targetPopulation: 'Humans',
        observations: 'None',
        actionTaken: 'None',
        isReferralGenerated: false,
        isAlertGenerated: false,
        isFollowUpRequired: false,
        volunteerId: 'COHV-01',
        deviceId: 'DEV-01',
        latitude: rawLat,
        longitude: rawLng,
        accuracy: 11,
      );
      expect(evt.toJson()['latitude'], 28.609471);
      expect(evt.toJson()['longitude'], 77.367524);
      expect(evt.toJson()['gps_accuracy_m'], 11);

      // Referral Request
      final ref = ReferralCreateRequest(
        volunteerId: 1,
        referralStream: 'HUMAN',
        referralFacilityId: 1,
        villageLgdCode: 101,
        eventDate: DateTime.now(),
        referralDate: DateTime.now(),
        latitude: rawLat,
        longitude: rawLng,
        gpsAccuracyM: 11,
      );
      expect(ref.toJson()['latitude'], 28.609471);
      expect(ref.toJson()['longitude'], 77.367524);
      expect(ref.toJson()['gps_accuracy_m'], 11);

      // Sample Support Request
      final smp = SampleSupportCreateRequest(
        volunteerId: 1,
        clientRef: 'SMP-1',
        deviceId: 'DEV-1',
        sampleTypeId: 1,
        sampleDate: '2026-10-26',
        sampleCount: 1,
        villageLgdCode: 101,
        capturedAt: '2026-10-26T12:00:00Z',
        latitude: rawLat,
        longitude: rawLng,
        gpsAccuracyM: 11,
      );
      expect(smp.toJson()['latitude'], 28.609471);
      expect(smp.toJson()['longitude'], 77.367524);
      expect(smp.toJson()['gps_accuracy_m'], 11);

      // Success Story Request
      final sty = SuccessStoryCreateRequest(
        volunteerId: 1,
        clientRef: 'STY-1',
        deviceId: 'DEV-1',
        title: 'Story',
        storyDate: '2026-10-26',
        locationText: 'Loc',
        oneHealthIssue: 'Issue',
        situation: 'Sit',
        actionTaken: 'Act',
        departmentId: 1,
        outcome: 'Out',
        latitude: rawLat,
        longitude: rawLng,
        gpsAccuracyM: 11,
      );
      expect(sty.toJson()['latitude'], 28.609471);
      expect(sty.toJson()['longitude'], 77.367524);
      expect(sty.toJson()['gps_accuracy_m'], 11);

      // Volunteer Registration Request
      final reg = VolunteerRegistrationRequest(
        volunteerName: 'Name',
        gender: 'Male',
        dateOfBirth: DateTime(1990, 1, 1),
        mobileNo: '9999999999',
        email: 'a@b.com',
        cohvType: 'Type',
        stateLgdCode: 1,
        districtLgdCode: 1,
        blockLgdCode: 1,
        gramPanchayatLgdCode: 1,
        villageLgdCode: 1,
        dateOfJoining: DateTime.now(),
        educationId: 1,
        professionId: 1,
        pin: '123456',
        latitude: rawLat,
        longitude: rawLng,
        gpsAccuracyM: 11,
      );
      expect(reg.toJson()['latitude'], 28.609471);
      expect(reg.toJson()['longitude'], 77.367524);
      expect(reg.toJson()['gps_accuracy_m'], 11);
    });
  });

  group('Location Resolution Dialog Widget Test', () {
    testWidgets('Renders explanation dialog for disabled GPS with action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  LocationService().showLocationResolutionDialog(
                    context,
                    status: LocationFetchStatus.serviceDisabled,
                    onRetry: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('GPS Is Turned Off'), findsOneWidget);
      expect(find.textContaining('Location services are disabled'), findsOneWidget);
      expect(find.text('Open Location Settings'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Renders explanation dialog for permanently denied permission', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  LocationService().showLocationResolutionDialog(
                    context,
                    status: LocationFetchStatus.permissionPermanentlyDenied,
                    onRetry: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Permission Permanently Denied'), findsOneWidget);
      expect(find.textContaining('Location permission is permanently denied'), findsOneWidget);
      expect(find.text('Open App Settings'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
