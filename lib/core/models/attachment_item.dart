import 'dart:io';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/models/geo_location_data.dart';

/// Unified model representing an attachment across Event Reports, Referrals, and Awareness Activities.
class AppAttachmentItem {
  final int attachmentId;
  final String fileKind; // 'IMAGE', 'VIDEO', 'DOCUMENT'
  final String fileName;
  final String storagePath;
  final String? mimeType;
  final int sizeBytes;
  final String? fileUrl;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final DateTime? capturedAt;
  final String? caption;

  const AppAttachmentItem({
    this.attachmentId = 0,
    required this.fileKind,
    required this.fileName,
    this.storagePath = '',
    this.mimeType,
    this.sizeBytes = 0,
    this.fileUrl,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.capturedAt,
    this.caption,
  });

  AppAttachmentItem copyWith({
    int? attachmentId,
    String? fileKind,
    String? fileName,
    String? storagePath,
    String? mimeType,
    int? sizeBytes,
    String? fileUrl,
    double? latitude,
    double? longitude,
    int? gpsAccuracyM,
    DateTime? capturedAt,
    String? caption,
  }) {
    return AppAttachmentItem(
      attachmentId: attachmentId ?? this.attachmentId,
      fileKind: fileKind ?? this.fileKind,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      fileUrl: fileUrl ?? this.fileUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracyM: gpsAccuracyM ?? this.gpsAccuracyM,
      capturedAt: capturedAt ?? this.capturedAt,
      caption: caption ?? this.caption,
    );
  }

  /// Check if this is an image file
  bool get isImage {
    final kind = fileKind.toUpperCase();
    if (kind == 'IMAGE' || kind == 'PHOTO' || kind == 'PHOTOGRAPH') return true;
    final lower = (fileName.isNotEmpty ? fileName : storagePath).toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  /// Check if this is a video file
  bool get isVideo {
    final kind = fileKind.toUpperCase();
    if (kind == 'VIDEO') return true;
    final lower = (fileName.isNotEmpty ? fileName : storagePath).toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }

  /// Check if this is a document file
  bool get isDocument => !isImage && !isVideo;

  /// Ordered candidate URLs to resolve this attachment with graceful fallback
  List<String> getCandidateUrls() {
    final candidates = <String>[];

    // 1. Direct fileUrl if provided
    if (fileUrl != null && fileUrl!.trim().isNotEmpty) {
      final direct = fileUrl!.trim();
      if (direct.startsWith('http://') || direct.startsWith('https://')) {
        candidates.add(direct);
      } else {
        final clean = direct.startsWith('/') ? direct.substring(1) : direct;
        candidates.add('${ApiConstants.serverRoot}/$clean');
        candidates.add('${ApiConstants.baseUrl}/$clean');
      }
    }

    // 2. Stream & Download API endpoints if attachmentId is valid
    if (attachmentId > 0) {
      candidates.add(ApiConstants.endpointAttachmentStream(attachmentId));
      candidates.add(ApiConstants.endpointAttachmentDownload(attachmentId));
    }

    // 3. Storage path candidate URLs
    if (storagePath.trim().isNotEmpty) {
      final sp = storagePath.trim();
      if (sp.startsWith('http://') || sp.startsWith('https://')) {
        candidates.add(sp);
      } else if (!sp.startsWith('file://') &&
          !sp.startsWith('/data/') &&
          !sp.startsWith('/storage/') &&
          !RegExp(r'^[a-zA-Z]:').hasMatch(sp)) {
        candidates.addAll(ApiConstants.resolveImageCandidateUrls(sp));
      }
    }

    return candidates.toSet().toList();
  }

  /// Resolves the primary streaming / viewing URL
  String get primaryUrl {
    final list = getCandidateUrls();
    if (list.isNotEmpty) return list.first;
    if (attachmentId > 0) {
      return ApiConstants.endpointAttachmentStream(attachmentId);
    }
    return '';
  }

  /// Formatted Geo-tag stamp: "28.609453, 77.367519 · ±11 m · 26 Oct 2026 04:03"
  String formatGeoTag({
    double? fallbackLat,
    double? fallbackLng,
    int? fallbackAccuracy,
    DateTime? fallbackDate,
  }) {
    final effectiveLat = (latitude != null && latitude != 0.0)
        ? latitude
        : ((fallbackLat != null && fallbackLat != 0.0) ? fallbackLat : null);
    final effectiveLng = (longitude != null && longitude != 0.0)
        ? longitude
        : ((fallbackLng != null && fallbackLng != 0.0) ? fallbackLng : null);
    final effectiveAcc = gpsAccuracyM ?? fallbackAccuracy;
    final effectiveDt = capturedAt ?? fallbackDate;

    final dateStr = effectiveDt != null ? _formatDateTime(effectiveDt) : null;

    if (effectiveLat != null && effectiveLng != null) {
      final latStr = effectiveLat.toStringAsFixed(6);
      final lngStr = effectiveLng.toStringAsFixed(6);
      final accStr =
          (effectiveAcc != null && effectiveAcc > 0) ? ' · ±$effectiveAcc m' : '';
      final dtStr = dateStr != null ? ' · $dateStr' : '';
      return '$latStr, $lngStr$accStr$dtStr';
    }

    if (dateStr != null) {
      return dateStr;
    }

    return '';
  }

  /// Formatted capture date: e.g. "26 Oct 2026 04:03"
  String formatCaptureDate({DateTime? fallbackDate}) {
    final dt = capturedAt ?? fallbackDate ?? DateTime.now();
    return _formatDateTime(dt);
  }

  static String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dayStr = dt.day.toString().padLeft(2, '0');
    final monthStr = months[dt.month - 1];
    final yearStr = dt.year.toString();
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '$dayStr $monthStr $yearStr $hourStr:$minStr';
  }

  factory AppAttachmentItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['attachment_id'] ?? json['id'];
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    var rawKind = (json['file_kind'] ??
            json['kind'] ??
            json['type'] ??
            '')
        .toString()
        .toUpperCase();

    final rawFileName = (json['file_name'] ??
            json['filename'] ??
            json['name'] ??
            '')
        .toString();

    final rawPath = (json['storage_path'] ??
            json['file_path'] ??
            json['path'] ??
            '')
        .toString();

    final rawUrl = (json['file_url'] ?? json['url'])?.toString();

    // Infer kind if unspecified
    if (rawKind.isEmpty) {
      final checkStr = rawFileName.isNotEmpty ? rawFileName : rawPath;
      final lower = checkStr.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi')) {
        rawKind = 'VIDEO';
      } else if (lower.endsWith('.pdf') ||
          lower.endsWith('.doc') ||
          lower.endsWith('.docx') ||
          lower.endsWith('.xls') ||
          lower.endsWith('.xlsx')) {
        rawKind = 'DOCUMENT';
      } else {
        rawKind = 'IMAGE';
      }
    }

    // Determine clean file name
    String effectiveFileName = rawFileName;
    if (effectiveFileName.isEmpty) {
      if (rawPath.isNotEmpty) {
        effectiveFileName = rawPath.split(Platform.pathSeparator).last.split('/').last;
      } else if (rawUrl != null && rawUrl.isNotEmpty) {
        effectiveFileName = rawUrl.split('/').last.split('?').first;
      } else {
        effectiveFileName = 'attachment_${parsedId > 0 ? parsedId : "file"}';
      }
    }

    // Parse coordinates and accuracy
    final lat = json['latitude'] != null
        ? double.tryParse(json['latitude'].toString())
        : (json['lat'] != null ? double.tryParse(json['lat'].toString()) : null);
    final lng = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString())
        : (json['lng'] != null
            ? double.tryParse(json['lng'].toString())
            : (json['lon'] != null
                ? double.tryParse(json['lon'].toString())
                : null));
    final acc = json['gps_accuracy_m'] != null
        ? int.tryParse(json['gps_accuracy_m'].toString())
        : (json['accuracy'] != null
            ? int.tryParse(json['accuracy'].toString())
            : null);

    // Parse capture / creation date
    DateTime? capAt;
    final rawDate = json['captured_at'] ??
        json['created_at'] ??
        json['timestamp'] ??
        json['date'];
    if (rawDate != null) {
      capAt = DateTime.tryParse(rawDate.toString())?.toLocal();
    }

    return AppAttachmentItem(
      attachmentId: parsedId,
      fileKind: rawKind,
      fileName: effectiveFileName,
      storagePath: rawPath,
      mimeType: json['mime_type']?.toString() ?? json['content_type']?.toString(),
      sizeBytes: json['size_bytes'] is int
          ? json['size_bytes'] as int
          : (int.tryParse(json['size_bytes']?.toString() ??
                  json['size']?.toString() ??
                  '0') ??
              0),
      fileUrl: rawUrl,
      latitude: lat,
      longitude: lng,
      gpsAccuracyM: acc,
      capturedAt: capAt,
      caption: json['caption']?.toString() ?? json['description']?.toString(),
    );
  }

  /// Create an attachment item from a local file path or remote URL
  factory AppAttachmentItem.fromPath(
    String path, {
    String? fileKind,
    String? fileName,
    double? latitude,
    double? longitude,
    int? accuracy,
    DateTime? capturedAt,
  }) {
    final cleanPath = path.trim();
    final name = fileName ??
        cleanPath.split(Platform.pathSeparator).last.split('/').last.split('?').first;

    String kind = (fileKind ?? '').toUpperCase();
    if (kind.isEmpty) {
      final lower = name.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi')) {
        kind = 'VIDEO';
      } else if (lower.endsWith('.pdf') ||
          lower.endsWith('.doc') ||
          lower.endsWith('.docx') ||
          lower.endsWith('.xls') ||
          lower.endsWith('.xlsx')) {
        kind = 'DOCUMENT';
      } else {
        kind = 'IMAGE';
      }
    }

    final isHttp = cleanPath.startsWith('http://') || cleanPath.startsWith('https://');

    return AppAttachmentItem(
      attachmentId: 0,
      fileKind: kind,
      fileName: name,
      storagePath: isHttp ? '' : cleanPath,
      fileUrl: isHttp ? cleanPath : null,
      latitude: latitude,
      longitude: longitude,
      gpsAccuracyM: accuracy,
      capturedAt: capturedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'attachment_id': attachmentId,
        'file_kind': fileKind,
        'file_name': fileName,
        'storage_path': storagePath,
        if (mimeType != null) 'mime_type': mimeType,
        'size_bytes': sizeBytes,
        if (fileUrl != null) 'file_url': fileUrl,
        if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
        if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
        if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
        if (capturedAt != null) 'captured_at': capturedAt!.toUtc().toIso8601String(),
        if (caption != null) 'caption': caption,
      };
}
