import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/media_geotag_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaGeoMetadata', () {
    test('formats coordinates to maximum 6 decimal places with accuracy', () {
      final metadata = MediaGeoMetadata(
        latitude: GeoLocationData.formatCoordinate(28.609471238),
        longitude: GeoLocationData.formatCoordinate(77.367523891),
        accuracyM: 14,
        capturedAt: DateTime(2026, 10, 28, 12, 14, 0),
        hasLocation: true,
        statusText: 'GPS Fixed',
        isFromGallery: false,
      );

      expect(metadata.latitude, 28.609471);
      expect(metadata.longitude, 77.367524);
      expect(metadata.geoTagLine, '📍 28.609471, 77.367524 · ±14 m');
      expect(metadata.timeLine, contains('28 Oct 2026 12:14:00'));
      expect(metadata.timeLine, contains('COHV Fieldspace'));
    });

    test('handles missing GPS without assigning fake coordinates', () {
      final metadata = const MediaGeoMetadata(
        latitude: null,
        longitude: null,
        accuracyM: null,
        capturedAt: null,
        hasLocation: false,
        statusText: 'Location: Not Available in Image Metadata',
        isFromGallery: true,
      );

      expect(metadata.hasLocation, isFalse);
      expect(metadata.latitude, isNull);
      expect(metadata.longitude, isNull);
      expect(metadata.geoTagLine, '📍 Location: Not Available in Image Metadata');
      expect(metadata.timeLine, contains('Gallery Media'));
    });
  });

  group('MediaGeoTagService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('geotag_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('resolveMetadata for camera with valid location formats coordinates', () async {
      final service = MediaGeoTagService();
      final loc = GeoLocationData(
        status: LocationFetchStatus.success,
        latitude: 28.584065999,
        longitude: 77.371091111,
        accuracyM: 11,
        timestamp: DateTime(2026, 10, 28, 10, 0, 0),
      );

      final meta = await service.resolveMetadata(
        bytes: Uint8List(0),
        isFromCamera: true,
        fallbackLocation: loc,
      );

      expect(meta.hasLocation, isTrue);
      expect(meta.latitude, 28.584066);
      expect(meta.longitude, 77.371091);
      expect(meta.accuracyM, 11);
      expect(meta.geoTagLine, '📍 28.584066, 77.371091 · ±11 m');
    });

    test('resolveMetadata for gallery with no EXIF does NOT use device GPS', () async {
      final service = MediaGeoTagService();
      // Dummy image bytes with no EXIF
      final dummyBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

      final loc = GeoLocationData(
        status: LocationFetchStatus.success,
        latitude: 28.584065,
        longitude: 77.371091,
      );

      final meta = await service.resolveMetadata(
        bytes: dummyBytes,
        isFromCamera: false,
        fallbackLocation: loc, // Fallback should NOT be used for gallery without EXIF
      );

      expect(meta.hasLocation, isFalse);
      expect(meta.latitude, isNull);
      expect(meta.longitude, isNull);
      expect(meta.statusText, contains('Not Available in Image Metadata'));
    });

    test('processPhoto non-existent file returns original path gracefully', () async {
      final service = MediaGeoTagService();
      final nonExistentPath = '${tempDir.path}/does_not_exist.jpg';

      final result = await service.processPhoto(
        filePath: nonExistentPath,
        isFromCamera: true,
      );

      expect(result, nonExistentPath);
    });

    test('processVideo returns processed video path', () async {
      final service = MediaGeoTagService();
      final sampleVideo = File('${tempDir.path}/test_video.mp4');
      await sampleVideo.writeAsBytes([0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70]);

      final loc = GeoLocationData(
        status: LocationFetchStatus.success,
        latitude: 28.584065,
        longitude: 77.371091,
        accuracyM: 8,
      );

      final result = await service.processVideo(
        filePath: sampleVideo.path,
        isFromCamera: true,
        fallbackLocation: loc,
      );

      expect(result, isNotEmpty);
      expect(File(result).existsSync(), isTrue);
    });
  });
}
