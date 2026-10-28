// Domain Models for Success Stories Feature
// File: lib/features/success_stories/domain/success_story_models.dart

import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/models/geo_location_data.dart';

class SuccessStoryDepartmentModel {
  final int departmentId;
  final String departmentName;
  final bool isOther;

  const SuccessStoryDepartmentModel({
    required this.departmentId,
    required this.departmentName,
    this.isOther = false,
  });

  factory SuccessStoryDepartmentModel.fromJson(Map<String, dynamic> json) {
    final id = json['department_id'] is int
        ? json['department_id'] as int
        : int.tryParse(json['department_id']?.toString() ?? '0') ?? 0;
    final name = json['department_name']?.toString() ?? '';
    final isOther = json['is_other'] == true ||
        name.toLowerCase() == 'other' ||
        name.toLowerCase().contains('other') ||
        name.toLowerCase().contains('community / ngo');

    return SuccessStoryDepartmentModel(
      departmentId: id,
      departmentName: name,
      isOther: isOther,
    );
  }

  Map<String, dynamic> toJson() => {
    'department_id': departmentId,
    'department_name': departmentName,
    'is_other': isOther,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuccessStoryDepartmentModel &&
          runtimeType == other.runtimeType &&
          departmentId == other.departmentId;

  @override
  int get hashCode => departmentId.hashCode;

  @override
  String toString() => departmentName;

  /// Default fallback departments matching GET /api/success-stories/departments
  static List<SuccessStoryDepartmentModel> fallbackDepartments() => const [
    SuccessStoryDepartmentModel(
      departmentId: 1,
      departmentName: 'Public Health Department',
    ),
    SuccessStoryDepartmentModel(
      departmentId: 2,
      departmentName: 'Animal Husbandry Department',
    ),
    SuccessStoryDepartmentModel(
      departmentId: 3,
      departmentName: 'Wildlife Department',
    ),
    SuccessStoryDepartmentModel(
      departmentId: 4,
      departmentName: 'Environment Department',
    ),
    SuccessStoryDepartmentModel(
      departmentId: 5,
      departmentName: 'Rural Department',
    ),
    SuccessStoryDepartmentModel(
      departmentId: 6,
      departmentName: 'Urban Department',
    ),
    SuccessStoryDepartmentModel(
      departmentId: 7,
      departmentName: 'Community / NGO',
      isOther: true,
    ),
    SuccessStoryDepartmentModel(
      departmentId: 99,
      departmentName: 'Other',
      isOther: true,
    ),
  ];
}

/// Request payload matching POST /api/success-stories OpenAPI specification
class SuccessStoryCreateRequest {
  final int volunteerId;
  final String clientRef;
  final String deviceId;
  final String title;
  final String storyDate; // YYYY-MM-DD
  final String locationText;
  final String oneHealthIssue;
  final String situation;
  final String actionTaken;
  final int departmentId;
  final List<int> departmentIds;
  final String? departmentOther;
  final String? caption;
  final String outcome;
  final String? communityBenefit;
  final String? lessonsLearned;
  final bool isInnovation;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;

  const SuccessStoryCreateRequest({
    required this.volunteerId,
    required this.clientRef,
    required this.deviceId,
    required this.title,
    required this.storyDate,
    required this.locationText,
    required this.oneHealthIssue,
    required this.situation,
    required this.actionTaken,
    required this.departmentId,
    this.departmentIds = const [],
    this.departmentOther,
    this.caption,
    required this.outcome,
    this.communityBenefit,
    this.lessonsLearned,
    this.isInnovation = false,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
  });

  Map<String, dynamic> toJson() => {
    'volunteer_id': volunteerId,
    'client_ref': clientRef,
    'device_id': deviceId,
    'title': title,
    'story_date': storyDate,
    'location_text': locationText,
    'one_health_issue': oneHealthIssue,
    'situation': situation,
    'action_taken': actionTaken,
    'department_id': departmentId,
    'department_ids': departmentIds.isNotEmpty ? departmentIds : [departmentId],
    if (departmentOther != null && departmentOther!.trim().isNotEmpty)
      'department_other': departmentOther!.trim()
    else
      'department_other': null,
    if (caption != null && caption!.trim().isNotEmpty) ...{
      'caption': caption!.trim(),
      'media_caption': caption!.trim(),
      'description': caption!.trim(),
    },
    'outcome': outcome,
    'community_benefit': communityBenefit ?? '',
    'lessons_learned': lessonsLearned ?? '',
    'is_innovation': isInnovation,
    if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (gpsUnavailableReason != null && gpsUnavailableReason!.trim().isNotEmpty)
      'gps_unavailable_reason': gpsUnavailableReason!.trim()
    else
      'gps_unavailable_reason': null,
    if (photos.isNotEmpty) 'photos': photos,
    if (videos.isNotEmpty) 'videos': videos,
    if (documents.isNotEmpty) 'documents': documents,
  };
}

/// Response payload for POST /api/success-stories
class SuccessStoryCreateResponse {
  final bool success;
  final String message;
  final int? storyId;
  final String? storyCode;
  final Map<String, dynamic>? rawData;

  const SuccessStoryCreateResponse({
    required this.success,
    required this.message,
    this.storyId,
    this.storyCode,
    this.rawData,
  });

  factory SuccessStoryCreateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return SuccessStoryCreateResponse(
      success: json['success'] == true || !json.containsKey('success'),
      message: json['message']?.toString() ??
          'Success story submitted successfully.',
      storyId: data['story_id'] is int
          ? data['story_id'] as int
          : int.tryParse(data['story_id']?.toString() ??
              (data['id']?.toString() ?? '')),
      storyCode: data['story_code']?.toString() ??
          (data['code']?.toString() ??
              (data['id'] != null ? 'STY-26-${data['id']}' : null)),
      rawData: data,
    );
  }

  factory SuccessStoryCreateResponse.failure(String message) {
    return SuccessStoryCreateResponse(
      success: false,
      message: message,
    );
  }
}

/// Domain Model for a Success Story Record (GET /api/success-stories/all and GET /api/success-stories/{id})
class SuccessStoryRecordModel {
  final int storyId;
  final String storyCode;
  final int? volunteerId;
  final String? volunteerName;
  final String title;
  final String storyDate;
  final String locationText;
  final String oneHealthIssue;
  final String situation;
  final String actionTaken;
  final int? departmentId;
  final List<int> departmentIds;
  final String? departmentName;
  final String? departmentOther;
  final String? caption;
  final String outcome;
  final String? communityBenefit;
  final String? lessonsLearned;
  final bool isInnovation;
  final dynamic latitude;
  final dynamic longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final String verificationStatus;
  final String? capturedAt;
  final String? createdAt;
  final String? updatedAt;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;
  final List<AppAttachmentItem> attachments;

  List<AppAttachmentItem> get appAttachments {
    if (attachments.isNotEmpty) return attachments;
    final list = <AppAttachmentItem>[];
    final effectiveLat = latitude is num
        ? (latitude as num).toDouble()
        : double.tryParse(latitude?.toString() ?? '');
    final effectiveLng = longitude is num
        ? (longitude as num).toDouble()
        : double.tryParse(longitude?.toString() ?? '');
    final capDate = DateTime.tryParse(capturedAt ?? storyDate);

    for (final p in photos) {
      list.add(AppAttachmentItem.fromPath(
        p,
        fileKind: 'IMAGE',
        latitude: effectiveLat,
        longitude: effectiveLng,
        accuracy: gpsAccuracyM,
        capturedAt: capDate,
      ));
    }
    for (final v in videos) {
      list.add(AppAttachmentItem.fromPath(
        v,
        fileKind: 'VIDEO',
        latitude: effectiveLat,
        longitude: effectiveLng,
        accuracy: gpsAccuracyM,
        capturedAt: capDate,
      ));
    }
    for (final d in documents) {
      list.add(AppAttachmentItem.fromPath(
        d,
        fileKind: 'DOCUMENT',
        latitude: effectiveLat,
        longitude: effectiveLng,
        accuracy: gpsAccuracyM,
        capturedAt: capDate,
      ));
    }
    return list;
  }

  const SuccessStoryRecordModel({
    required this.storyId,
    required this.storyCode,
    this.volunteerId,
    this.volunteerName,
    required this.title,
    required this.storyDate,
    required this.locationText,
    required this.oneHealthIssue,
    required this.situation,
    required this.actionTaken,
    this.departmentId,
    this.departmentIds = const [],
    this.departmentName,
    this.departmentOther,
    this.caption,
    required this.outcome,
    this.communityBenefit,
    this.lessonsLearned,
    this.isInnovation = false,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.verificationStatus = 'SUBMITTED',
    this.capturedAt,
    this.createdAt,
    this.updatedAt,
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
    this.attachments = const [],
  });

  factory SuccessStoryRecordModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['story_id'] ?? json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final rawVid = json['volunteer_id'];
    final vId = rawVid is int ? rawVid : int.tryParse(rawVid?.toString() ?? '');

    final rawDeptId = json['department_id'];
    final deptId = rawDeptId is int ? rawDeptId : int.tryParse(rawDeptId?.toString() ?? '');

    final rawAcc = json['gps_accuracy_m'];
    final acc = rawAcc is int ? rawAcc : int.tryParse(rawAcc?.toString() ?? '');

    final isInnov = json['is_innovation'] == true ||
        json['is_innovation'] == 1 ||
        json['is_innovation']?.toString().toLowerCase() == 'true' ||
        json['is_innovation']?.toString().toLowerCase() == 'yes';

    // Parse attachments / media if present
    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return const [];
    }

    final photos = parseList(json['photos'] ?? json['photo_urls']);
    final videos = parseList(json['videos'] ?? json['video_urls']);
    final documents = parseList(json['documents'] ?? json['document_urls']);

    final effectiveLat = json['latitude'] is num
        ? (json['latitude'] as num).toDouble()
        : double.tryParse(json['latitude']?.toString() ?? '');
    final effectiveLng = json['longitude'] is num
        ? (json['longitude'] as num).toDouble()
        : double.tryParse(json['longitude']?.toString() ?? '');
    final capDate = DateTime.tryParse(json['captured_at']?.toString() ?? json['story_date']?.toString() ?? '');

    final List<AppAttachmentItem> attList = [];
    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        if (a is Map) {
          attList.add(AppAttachmentItem.fromJson(Map<String, dynamic>.from(a)));
        } else if (a is String && a.trim().isNotEmpty) {
          attList.add(
            AppAttachmentItem.fromPath(
              a,
              latitude: effectiveLat,
              longitude: effectiveLng,
              accuracy: acc,
              capturedAt: capDate,
            ),
          );
        }
      }
    }

    if (attList.isEmpty) {
      for (final p in photos) {
        attList.add(
          AppAttachmentItem.fromPath(
            p,
            fileKind: 'IMAGE',
            latitude: effectiveLat,
            longitude: effectiveLng,
            accuracy: acc,
            capturedAt: capDate,
          ),
        );
      }
      for (final v in videos) {
        attList.add(
          AppAttachmentItem.fromPath(
            v,
            fileKind: 'VIDEO',
            latitude: effectiveLat,
            longitude: effectiveLng,
            accuracy: acc,
            capturedAt: capDate,
          ),
        );
      }
      for (final d in documents) {
        attList.add(
          AppAttachmentItem.fromPath(
            d,
            fileKind: 'DOCUMENT',
            latitude: effectiveLat,
            longitude: effectiveLng,
            accuracy: acc,
            capturedAt: capDate,
          ),
        );
      }
    }

    return SuccessStoryRecordModel(
      storyId: id,
      storyCode: json['story_code']?.toString() ??
          json['code']?.toString() ??
          'STY-26-${id.toString().padLeft(4, '0')}',
      volunteerId: vId,
      volunteerName: json['volunteer_name']?.toString(),
      title: json['title']?.toString() ?? '',
      storyDate: json['story_date']?.toString() ?? json['date']?.toString() ?? '',
      locationText: json['location_text']?.toString() ?? json['location']?.toString() ?? '',
      oneHealthIssue: json['one_health_issue']?.toString() ?? json['issue']?.toString() ?? '',
      situation: json['situation']?.toString() ?? json['problem']?.toString() ?? '',
      actionTaken: json['action_taken']?.toString() ?? json['action']?.toString() ?? '',
      departmentId: deptId,
      departmentIds: () {
        final raw = json['department_ids'];
        if (raw is List) {
          return raw
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
        }
        return deptId != null ? [deptId] : <int>[];
      }(),
      departmentName: json['department_name']?.toString() ?? json['department']?.toString(),
      departmentOther: json['department_other']?.toString(),
      caption: json['caption']?.toString() ??
          json['media_caption']?.toString() ??
          json['description']?.toString(),
      outcome: json['outcome']?.toString() ?? '',
      communityBenefit: json['community_benefit']?.toString() ?? json['benefit']?.toString(),
      lessonsLearned: json['lessons_learned']?.toString() ?? json['lessons']?.toString(),
      isInnovation: isInnov,
      latitude: json['latitude'],
      longitude: json['longitude'],
      gpsAccuracyM: acc,
      gpsUnavailableReason: json['gps_unavailable_reason']?.toString(),
      verificationStatus: json['verification_status']?.toString() ??
          json['verification']?.toString() ??
          'SUBMITTED',
      capturedAt: json['captured_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      photos: photos,
      videos: videos,
      documents: documents,
      attachments: attList,
    );
  }

  Map<String, dynamic> toJson() => {
    'story_id': storyId,
    'story_code': storyCode,
    'volunteer_id': volunteerId,
    'volunteer_name': volunteerName,
    'title': title,
    'story_date': storyDate,
    'location_text': locationText,
    'one_health_issue': oneHealthIssue,
    'situation': situation,
    'action_taken': actionTaken,
    'department_id': departmentId,
    if (departmentIds.isNotEmpty) 'department_ids': departmentIds,
    'department_name': departmentName,
    'department_other': departmentOther,
    if (caption != null && caption!.trim().isNotEmpty) ...{
      'caption': caption!.trim(),
      'media_caption': caption!.trim(),
      'description': caption!.trim(),
    },
    'outcome': outcome,
    'community_benefit': communityBenefit,
    'lessons_learned': lessonsLearned,
    'is_innovation': isInnovation,
    if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
    'gps_accuracy_m': gpsAccuracyM,
    'gps_unavailable_reason': gpsUnavailableReason,
    'verification_status': verificationStatus,
    'captured_at': capturedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'photos': photos,
    'videos': videos,
    'documents': documents,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  /// Formatted date in "25 Oct 2026" style matching screenshot
  String get formattedDate {
    if (storyDate.trim().isEmpty) return '';
    try {
      final parsed = DateTime.parse(storyDate.trim());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return storyDate;
    }
  }

  /// Formatted category: "innovation / best practice" or "Success Story"
  String get formattedCategory =>
      isInnovation ? 'innovation / best practice' : 'Success Story';

  /// "Yes" or "No" for innovation row
  String get formattedInnovation => isInnovation ? 'Yes' : 'No';

  /// Formatted verification status: "Submitted"
  String get formattedVerificationStatus {
    final status = verificationStatus.trim();
    if (status.toUpperCase() == 'SUBMITTED') return 'Submitted';
    if (status.toUpperCase() == 'APPROVED') return 'Approved';
    if (status.toUpperCase() == 'REJECTED') return 'Rejected';
    return status.isNotEmpty ? status : 'Submitted';
  }

  /// Formatted sync status: "Synced"
  String get formattedSyncStatus => 'Synced';

  /// Badge label for card ("pending", "synced", etc.)
  String get statusBadge {
    final s = verificationStatus.toLowerCase().trim();
    if (s == 'submitted') return 'pending';
    return s.isNotEmpty ? s : 'pending';
  }

  /// Formatted GPS location string e.g. "25.281198, 82.953928 · ±22 m"
  String get formattedGpsLocation {
    final lat = latitude?.toString().trim();
    final lng = longitude?.toString().trim();
    if (lat != null && lat.isNotEmpty && lng != null && lng.isNotEmpty) {
      final acc = gpsAccuracyM != null ? ' · ±$gpsAccuracyM m' : '';
      return '$lat, $lng$acc';
    }
    return 'Location not captured';
  }

  /// Map representation for backward compatibility with map-based widgets
  Map<String, dynamic> toMap() => {
    'id': storyCode,
    'storyId': storyId,
    'title': title,
    'date': formattedDate,
    'location': locationText,
    'category': formattedCategory,
    'innovation': formattedInnovation,
    'issue': oneHealthIssue,
    'problem': situation,
    'action': actionTaken,
    'department': departmentName ?? departmentOther ?? 'Public Health Department',
    'outcome': outcome,
    'benefit': communityBenefit ?? '—',
    'lessons': lessonsLearned ?? '—',
    'verification': formattedVerificationStatus,
    'sync': formattedSyncStatus,
    'gps': formattedGpsLocation,
    'status': statusBadge,
    'photos': photos,
    'videos': videos,
    'documents': documents,
  };
}
