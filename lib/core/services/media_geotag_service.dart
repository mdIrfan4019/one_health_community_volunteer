import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';

/// Represents parsed or determined GPS and time metadata for media.
class MediaGeoMetadata {
  final double? latitude;
  final double? longitude;
  final int? accuracyM;
  final DateTime? capturedAt;
  final bool hasLocation;
  final String statusText;
  final bool isFromGallery;

  const MediaGeoMetadata({
    this.latitude,
    this.longitude,
    this.accuracyM,
    this.capturedAt,
    required this.hasLocation,
    required this.statusText,
    this.isFromGallery = false,
  });

  /// Human-readable geo-tag string formatted for burning onto media.
  String get geoTagLine {
    if (hasLocation && latitude != null && longitude != null) {
      final latStr = latitude!.toStringAsFixed(6);
      final lngStr = longitude!.toStringAsFixed(6);
      final accStr = accuracyM != null && accuracyM! > 0 ? ' · ±$accuracyM m' : '';
      return '📍 $latStr, $lngStr$accStr';
    }
    return '📍 $statusText';
  }

  String get timeLine {
    final dt = capturedAt ?? DateTime.now();
    final dtStr = _formatDateTime(dt);
    final tag = isFromGallery ? ' · Gallery Media' : ' · COHV Fieldspace';
    return '📅 $dtStr$tag';
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final mon = months[dt.month - 1];
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    return '$day $mon $year $hour:$min:$sec';
  }
}

/// Centralized service handling photo and video geo-tagging across all reporting forms.
class MediaGeoTagService {
  static MediaGeoTagService _instance = MediaGeoTagService._internal();
  factory MediaGeoTagService() => _instance;
  MediaGeoTagService._internal();
  MediaGeoTagService.base();

  /// Inject mock service for unit and widget testing.
  static void setMockInstance(MediaGeoTagService? mock) {
    _instance = mock ?? MediaGeoTagService._internal();
  }

  /// Process and stamp a photograph with visible geo-tag overlay.
  /// Returns the path to the newly created stamped photograph file.
  Future<String> processPhoto({
    required String filePath,
    required bool isFromCamera,
    GeoLocationData? fallbackLocation,
    DateTime? captureTime,
  }) async {
    try {
      final originalFile = File(filePath);
      if (!await originalFile.exists()) {
        debugPrint('[GEOTAG] File does not exist: $filePath');
        return filePath;
      }

      final bytes = await originalFile.readAsBytes();
      if (bytes.isEmpty) {
        return filePath;
      }

      // 1. Resolve GeoMetadata
      final metadata = await resolveMetadata(
        bytes: bytes,
        isFromCamera: isFromCamera,
        fallbackLocation: fallbackLocation,
        captureTime: captureTime,
        file: originalFile,
      );

      // 2. Burn stamp overlay onto image pixels
      final stampedBytes = await _burnOverlayOnImage(bytes, metadata);
      if (stampedBytes == null || stampedBytes.isEmpty) {
        debugPrint('[GEOTAG] Could not burn stamp (using original): $filePath');
        return filePath;
      }

      // 3. Save stamped image to dedicated file
      final dir = originalFile.parent.path;
      final originalName = originalFile.uri.pathSegments.last;
      final dotIndex = originalName.lastIndexOf('.');
      final nameWithoutExt = dotIndex != -1 ? originalName.substring(0, dotIndex) : originalName;
      final ext = dotIndex != -1 ? originalName.substring(dotIndex) : '.jpg';

      final stampedPath = '$dir/${nameWithoutExt}_geotagged$ext';
      final stampedFile = File(stampedPath);
      await stampedFile.writeAsBytes(stampedBytes);

      debugPrint('[GEOTAG] Created stamped photo: $stampedPath (${metadata.geoTagLine})');
      return stampedFile.path;
    } catch (e, stack) {
      debugPrint('[GEOTAG] Error processing photo: $e\n$stack');
      return filePath;
    }
  }

  /// Process a video attachment, embedding geo-tag metadata and generating stamped companion.
  /// Returns the path to the final video file.
  Future<String> processVideo({
    required String filePath,
    required bool isFromCamera,
    GeoLocationData? fallbackLocation,
    DateTime? captureTime,
  }) async {
    try {
      final originalFile = File(filePath);
      if (!await originalFile.exists()) {
        return filePath;
      }

      final metadata = await resolveMetadata(
        bytes: Uint8List(0),
        isFromCamera: isFromCamera,
        fallbackLocation: fallbackLocation,
        captureTime: captureTime,
        file: originalFile,
      );

      // Embed ISO-6709 location atom / user-data box if camera location is valid
      final stampedPath = await _embedVideoMetadata(originalFile, metadata);
      debugPrint('[GEOTAG] Processed video: $stampedPath (${metadata.geoTagLine})');
      return stampedPath;
    } catch (e, stack) {
      debugPrint('[GEOTAG] Error processing video: $e\n$stack');
      return filePath;
    }
  }

  /// Resolve metadata for media from camera or gallery.
  Future<MediaGeoMetadata> resolveMetadata({
    required Uint8List bytes,
    required bool isFromCamera,
    GeoLocationData? fallbackLocation,
    DateTime? captureTime,
    File? file,
  }) async {
    if (isFromCamera) {
      // For camera media, capture real current GPS
      GeoLocationData loc = fallbackLocation ??
          LocationService().lastKnownLocation ??
          await LocationService().getCurrentLocation(requestIfNeeded: false);

      final dt = captureTime ?? loc.timestamp ?? DateTime.now();

      if (loc.isAvailable && loc.latitude != null && loc.longitude != null) {
        return MediaGeoMetadata(
          latitude: GeoLocationData.formatCoordinate(loc.latitude),
          longitude: GeoLocationData.formatCoordinate(loc.longitude),
          accuracyM: loc.accuracyM,
          capturedAt: dt,
          hasLocation: true,
          statusText: 'Location Available',
          isFromGallery: false,
        );
      }

      return MediaGeoMetadata(
        capturedAt: dt,
        hasLocation: false,
        statusText: loc.displayText,
        isFromGallery: false,
      );
    } else {
      // For gallery media, extract embedded EXIF metadata when available
      // Do NOT falsely label with current device location!
      ExifMetadata? exif;
      if (bytes.isNotEmpty) {
        exif = ExifMetadataReader.parse(bytes);
      }

      DateTime? dt = exif?.captureTime;
      if (dt == null && file != null) {
        try {
          dt = await file.lastModified();
        } catch (_) {}
      }

      if (exif != null && exif.hasLocation) {
        return MediaGeoMetadata(
          latitude: GeoLocationData.formatCoordinate(exif.latitude),
          longitude: GeoLocationData.formatCoordinate(exif.longitude),
          accuracyM: null,
          capturedAt: dt,
          hasLocation: true,
          statusText: 'Location Available (EXIF)',
          isFromGallery: true,
        );
      }

      return MediaGeoMetadata(
        capturedAt: dt,
        hasLocation: false,
        statusText: 'Location: Not Available in Image Metadata',
        isFromGallery: true,
      );
    }
  }

  /// Burns a clearly visible, high-contrast location and timestamp banner onto an image.
  Future<Uint8List?> _burnOverlayOnImage(Uint8List imageBytes, MediaGeoMetadata meta) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final imgWidth = image.width.toDouble();
      final imgHeight = image.height.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgWidth, imgHeight));

      // 1. Draw base photo
      canvas.drawImage(image, Offset.zero, Paint());

      // 2. Calculate banner dimensions proportional to image size
      final bannerHeight = (imgHeight * 0.09).clamp(64.0, 180.0);
      final bannerTop = imgHeight - bannerHeight;

      // Dark translucent background with subtle blur feel
      final bgPaint = Paint()..color = const Color(0xDD0F172A); // 87% dark slate
      canvas.drawRect(Rect.fromLTWH(0, bannerTop, imgWidth, bannerHeight), bgPaint);

      // Accent strip at top of banner
      final accentPaint = Paint()
        ..color = meta.hasLocation ? const Color(0xFF10B981) : const Color(0xFFF59E0B)
        ..strokeWidth = (bannerHeight * 0.04).clamp(2.5, 6.0)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(0, bannerTop, imgWidth, (bannerHeight * 0.04).clamp(2.5, 6.0)),
        accentPaint,
      );

      // 3. Text styling
      final titleFontSize = (bannerHeight * 0.28).clamp(13.0, 32.0);
      final subFontSize = (bannerHeight * 0.22).clamp(11.0, 24.0);
      final paddingH = (imgWidth * 0.035).clamp(16.0, 48.0);
      final paddingV = (bannerHeight * 0.16);

      // Line 1: Coordinates or Status
      final paragraphBuilder1 = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
          maxLines: 1,
          ellipsis: '...',
        ),
      )
        ..pushStyle(ui.TextStyle(
          color: Colors.white,
          letterSpacing: 0.2,
          shadows: [
            const Shadow(
              color: Colors.black,
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ],
        ))
        ..addText(meta.geoTagLine);

      final p1 = paragraphBuilder1.build()
        ..layout(ui.ParagraphConstraints(width: imgWidth - (paddingH * 2)));

      canvas.drawParagraph(p1, Offset(paddingH, bannerTop + paddingV));

      // Line 2: Timestamp and Application Tag
      final paragraphBuilder2 = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: subFontSize,
          fontWeight: FontWeight.w500,
          maxLines: 1,
          ellipsis: '...',
        ),
      )
        ..pushStyle(ui.TextStyle(
          color: const Color(0xFFE2E8F0),
          letterSpacing: 0.1,
          shadows: [
            const Shadow(
              color: Colors.black,
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ))
        ..addText(meta.timeLine);

      final p2 = paragraphBuilder2.build()
        ..layout(ui.ParagraphConstraints(width: imgWidth - (paddingH * 2)));

      canvas.drawParagraph(p2, Offset(paddingH, bannerTop + paddingV + titleFontSize + 4));

      // 4. Finalize picture and encode to PNG bytes
      final picture = recorder.endRecording();
      final stampedImage = await picture.toImage(image.width, image.height);
      final byteData = await stampedImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[GEOTAG] _burnOverlayOnImage error (fallback to raw): $e');
      return null;
    }
  }

  /// Embeds ISO-6709 location atom and creates stamped video attachment.
  Future<String> _embedVideoMetadata(File videoFile, MediaGeoMetadata meta) async {
    final dir = videoFile.parent.path;
    final originalName = videoFile.uri.pathSegments.last;
    final dotIndex = originalName.lastIndexOf('.');
    final nameWithoutExt = dotIndex != -1 ? originalName.substring(0, dotIndex) : originalName;
    final ext = dotIndex != -1 ? originalName.substring(dotIndex) : '.mp4';

    final targetPath = '$dir/${nameWithoutExt}_geotagged$ext';
    final targetFile = File(targetPath);

    // If destination already exists, return it
    if (await targetFile.exists() && targetPath != videoFile.path) {
      return targetPath;
    }

    // Read original video bytes
    final bytes = await videoFile.readAsBytes();
    if (bytes.isEmpty) return videoFile.path;

    // Inject MP4 user data box (udta / ©xyz) with ISO-6709 coordinates if location is valid
    if (meta.hasLocation && meta.latitude != null && meta.longitude != null) {
      final isoCoords = _formatIso6709(meta.latitude!, meta.longitude!);
      final updatedBytes = _injectMp4LocationBox(bytes, isoCoords);
      await targetFile.writeAsBytes(updatedBytes);
      return targetFile.path;
    }

    // Copy to standardized geotagged video path
    await targetFile.writeAsBytes(bytes);
    return targetFile.path;
  }

  /// Formats coordinate pair into standard ISO-6709 format: e.g. "+28.609471+077.367524/"
  static String _formatIso6709(double lat, double lng) {
    final latSign = lat >= 0 ? '+' : '-';
    final lngSign = lng >= 0 ? '+' : '-';
    final latAbs = lat.abs().toStringAsFixed(6).padLeft(9, '0');
    final lngAbs = lng.abs().toStringAsFixed(6).padLeft(10, '0');
    return '$latSign$latAbs$lngSign$lngAbs/';
  }

  /// Injects or appends standard MP4 user data atom (©xyz) with ISO-6709 location.
  static Uint8List _injectMp4LocationBox(Uint8List bytes, String isoCoords) {
    try {
      if (bytes.length < 8) return bytes;
      final payload = isoCoords.codeUnits;
      // Atom header: length (4 bytes) + type '©xyz' (0xA9, 'x', 'y', 'z') + lang (2 bytes) + payload
      final atomLen = 4 + 4 + 2 + payload.length;
      final atomData = ByteData(atomLen);
      atomData.setUint32(0, atomLen);
      atomData.setUint8(4, 0xA9);
      atomData.setUint8(5, 0x78); // 'x'
      atomData.setUint8(6, 0x79); // 'y'
      atomData.setUint8(7, 0x7A); // 'z'
      atomData.setUint16(8, 0x55C4); // lang: und
      for (int i = 0; i < payload.length; i++) {
        atomData.setUint8(10 + i, payload[i]);
      }

      final builder = BytesBuilder();
      builder.add(bytes);
      builder.add(atomData.buffer.asUint8List());
      return builder.toBytes();
    } catch (_) {
      return bytes;
    }
  }
}

// =========================================================================
// PURE DART EXIF METADATA READER (FOR GALLERY PHOTOS)
// =========================================================================

class ExifMetadata {
  final double? latitude;
  final double? longitude;
  final DateTime? captureTime;

  const ExifMetadata({this.latitude, this.longitude, this.captureTime});
  bool get hasLocation => latitude != null && longitude != null;
}

class ExifMetadataReader {
  static ExifMetadata? parse(Uint8List bytes) {
    if (bytes.length < 14) return null;
    // Check JPEG SOI marker 0xFFD8
    if (bytes[0] != 0xFF || bytes[1] != 0xD8) return null;

    int offset = 2;
    while (offset + 4 < bytes.length) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      if (marker == 0xDA || marker == 0xD9) break; // Start of Scan or EOI
      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (marker == 0xE1) {
        // APP1 Exif Marker
        final end = (offset + 2 + length).clamp(0, bytes.length);
        final app1Data = bytes.sublist(offset + 4, end);
        return _parseApp1(app1Data);
      }
      offset += 2 + length;
    }
    return null;
  }

  static ExifMetadata? _parseApp1(Uint8List data) {
    if (data.length < 14) return null;
    // Check "Exif\0\0"
    if (data[0] != 0x45 ||
        data[1] != 0x78 ||
        data[2] != 0x69 ||
        data[3] != 0x76 && data[3] != 0x66 ||
        data[4] != 0x00 ||
        data[5] != 0x00) {
      return null;
    }

    final tiff = data.sublist(6);
    if (tiff.length < 8) return null;
    final isLittleEndian = (tiff[0] == 0x49 && tiff[1] == 0x49); // 'II' vs 'MM'
    final byteData = ByteData.sublistView(tiff);
    final endian = isLittleEndian ? Endian.little : Endian.big;

    final magic = byteData.getUint16(2, endian);
    if (magic != 42) return null;

    final ifd0Offset = byteData.getUint32(4, endian);
    if (ifd0Offset >= tiff.length) return null;

    int? gpsOffset;
    int? exifOffset;
    DateTime? captureTime;

    void parseIfd(int startOffset) {
      if (startOffset + 2 > tiff.length) return;
      final entriesCount = byteData.getUint16(startOffset, endian);
      int cur = startOffset + 2;
      for (int i = 0; i < entriesCount; i++) {
        if (cur + 12 > tiff.length) break;
        final tag = byteData.getUint16(cur, endian);
        final valOffset = byteData.getUint32(cur + 8, endian);
        if (tag == 0x8825) {
          gpsOffset = valOffset;
        } else if (tag == 0x8769) {
          exifOffset = valOffset;
        } else if (tag == 0x0132 && captureTime == null) {
          captureTime = _parseDateTimeString(tiff, valOffset);
        }
        cur += 12;
      }
    }

    parseIfd(ifd0Offset);

    if (exifOffset != null && exifOffset! < tiff.length) {
      if (exifOffset! + 2 <= tiff.length) {
        final entries = byteData.getUint16(exifOffset!, endian);
        int cur = exifOffset! + 2;
        for (int i = 0; i < entries; i++) {
          if (cur + 12 > tiff.length) break;
          final tag = byteData.getUint16(cur, endian);
          final valOffset = byteData.getUint32(cur + 8, endian);
          if (tag == 0x9003 || tag == 0x9004) {
            final dt = _parseDateTimeString(tiff, valOffset);
            if (dt != null) captureTime = dt;
          }
          cur += 12;
        }
      }
    }

    double? lat;
    double? lng;
    if (gpsOffset != null && gpsOffset! < tiff.length) {
      String? latRef;
      String? lngRef;
      List<double>? latParts;
      List<double>? lngParts;

      if (gpsOffset! + 2 <= tiff.length) {
        final entries = byteData.getUint16(gpsOffset!, endian);
        int cur = gpsOffset! + 2;
        for (int i = 0; i < entries; i++) {
          if (cur + 12 > tiff.length) break;
          final tag = byteData.getUint16(cur, endian);
          final val = cur + 8;
          if (tag == 0x0001) {
            latRef = String.fromCharCode(tiff[val]);
          } else if (tag == 0x0002) {
            final ptr = byteData.getUint32(val, endian);
            latParts = _parseRationals(byteData, ptr, 3, endian);
          } else if (tag == 0x0003) {
            lngRef = String.fromCharCode(tiff[val]);
          } else if (tag == 0x0004) {
            final ptr = byteData.getUint32(val, endian);
            lngParts = _parseRationals(byteData, ptr, 3, endian);
          }
          cur += 12;
        }
      }

      if (latParts != null && latParts.length == 3) {
        lat = latParts[0] + (latParts[1] / 60.0) + (latParts[2] / 3600.0);
        if (latRef == 'S') lat = -lat;
      }
      if (lngParts != null && lngParts.length == 3) {
        lng = lngParts[0] + (lngParts[1] / 60.0) + (lngParts[2] / 3600.0);
        if (lngRef == 'W') lng = -lng;
      }
    }

    return ExifMetadata(latitude: lat, longitude: lng, captureTime: captureTime);
  }

  static List<double>? _parseRationals(ByteData data, int offset, int count, Endian endian) {
    if (offset + count * 8 > data.lengthInBytes) return null;
    final res = <double>[];
    for (int i = 0; i < count; i++) {
      final num = data.getUint32(offset + (i * 8), endian);
      final den = data.getUint32(offset + (i * 8) + 4, endian);
      if (den == 0) return null;
      res.add(num / den);
    }
    return res;
  }

  static DateTime? _parseDateTimeString(Uint8List tiff, int offset) {
    if (offset >= tiff.length) return null;
    final chars = <int>[];
    for (int i = offset; i < tiff.length && i < offset + 20; i++) {
      if (tiff[i] == 0) break;
      chars.add(tiff[i]);
    }
    final str = String.fromCharCodes(chars).trim();
    if (str.length >= 19 && str[4] == ':' && str[7] == ':') {
      try {
        final formatted =
            '${str.substring(0, 4)}-${str.substring(5, 7)}-${str.substring(8, 10)}T${str.substring(11, 19)}';
        return DateTime.tryParse(formatted);
      } catch (_) {}
    }
    return null;
  }
}

