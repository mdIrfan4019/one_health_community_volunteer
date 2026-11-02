// Domain Models for Success Stories Feature
// File: lib/features/success_stories/domain/success_story_models.dart

import 'dart:convert';
import 'package:cohv/core/constants/api_constants.dart';
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
  final int? departmentId;
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
  final List<int> removedAttachmentIds;

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
    this.departmentId,
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
    this.removedAttachmentIds = const [],
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
    'department_id': departmentIds.isNotEmpty
        ? departmentIds
        : (departmentId != null ? [departmentId!] : <int>[]),
    'department_ids': departmentIds.isNotEmpty
        ? departmentIds
        : (departmentId != null ? [departmentId!] : <int>[]),
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
    if (removedAttachmentIds.isNotEmpty) 'removed_attachment_ids': removedAttachmentIds,
  };

  factory SuccessStoryCreateRequest.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    List<int> parseIntList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      return const [];
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return SuccessStoryCreateRequest(
      volunteerId: parseInt(json['volunteer_id']) ?? 0,
      clientRef: json['client_ref']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Success Story',
      storyDate: json['story_date']?.toString() ?? '',
      locationText: json['location_text']?.toString() ?? 'Local Area',
      oneHealthIssue:
          json['one_health_issue']?.toString() ?? 'Community Health',
      situation: json['situation']?.toString() ?? '',
      actionTaken: json['action_taken']?.toString() ?? '',
      departmentId: parseInt(json['department_id']) ?? 1,
      departmentIds: parseIntList(json['department_ids']),
      departmentOther: json['department_other']?.toString(),
      caption: json['caption']?.toString() ?? json['description']?.toString(),
      outcome: json['outcome']?.toString() ?? '',
      communityBenefit: json['community_benefit']?.toString(),
      lessonsLearned: json['lessons_learned']?.toString(),
      isInnovation: json['is_innovation'] == true ||
          json['is_innovation'] == 'true' ||
          json['is_innovation'] == '1',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      gpsAccuracyM: parseInt(json['gps_accuracy_m']),
      gpsUnavailableReason: json['gps_unavailable_reason']?.toString(),
      photos: parseStringList(json['photos']),
      videos: parseStringList(json['videos']),
      documents: parseStringList(json['documents']),
    );
  }
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

  String get storyText => situation.isNotEmpty ? situation : (actionTaken.isNotEmpty ? actionTaken : outcome);

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
    final rawId = json['story_id'] ?? json['storyId'] ?? json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final rawVid = json['volunteer_id'] ?? json['volunteerId'];
    final vId = rawVid is int ? rawVid : int.tryParse(rawVid?.toString() ?? '');

    final rawDeptId = json['department_id'] ?? json['departmentId'] ?? json['department_ids'] ?? json['departmentIds'];
    final deptId = rawDeptId is int
        ? rawDeptId
        : (rawDeptId is List && rawDeptId.isNotEmpty
            ? (rawDeptId.first is int
                ? rawDeptId.first as int
                : int.tryParse(rawDeptId.first.toString()))
            : int.tryParse(rawDeptId?.toString() ?? ''));

    final rawAcc = json['gps_accuracy_m'] ?? json['gpsAccuracyM'];
    final acc = rawAcc is int ? rawAcc : int.tryParse(rawAcc?.toString() ?? '');

    final isInnov = json['is_innovation'] == true ||
        json['is_innovation'] == 1 ||
        json['is_innovation']?.toString().toLowerCase() == 'true' ||
        json['is_innovation']?.toString().toLowerCase() == 'yes';

    // Parse attachments / media if present
    List<String> parseList(dynamic val) {
      if (val is List) {
        final result = <String>[];
        for (final item in val) {
          if (item is Map) {
            final rawUrl = item['url']?.toString() ??
                item['file_url']?.toString() ??
                item['storage_path']?.toString() ??
                '';
            if (rawUrl.isNotEmpty) {
              final fullUrl = rawUrl.startsWith('http')
                  ? rawUrl
                  : '${ApiConstants.serverRoot}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
              result.add(fullUrl);
            }
          } else if (item is String && item.trim().isNotEmpty) {
            final str = item.trim();
            if (str.startsWith('{') && str.endsWith('}')) {
              final match = RegExp(r'(?:url|file_url|storage_path):\s*([^\s,}]+)').firstMatch(str);
              if (match != null) {
                final extracted = match.group(1)!;
                if (extracted != 'null' && extracted.isNotEmpty) {
                  final fullUrl = extracted.startsWith('http')
                      ? extracted
                      : '${ApiConstants.serverRoot}${extracted.startsWith('/') ? '' : '/'}$extracted';
                  result.add(fullUrl);
                }
              }
            } else {
              final fullUrl = str.startsWith('http')
                  ? str
                  : '${ApiConstants.serverRoot}${str.startsWith('/') ? '' : '/'}$str';
              result.add(fullUrl);
            }
          }
        }
        return result;
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
          final str = a.trim();
          if (!str.startsWith('{')) {
            attList.add(
              AppAttachmentItem.fromPath(
                str,
                latitude: effectiveLat,
                longitude: effectiveLng,
                accuracy: acc,
                capturedAt: capDate,
              ),
            );
          }
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
      volunteerName: json['volunteer_name']?.toString() ?? json['volunteerName']?.toString(),
      title: json['title']?.toString() ?? '',
      storyDate: json['story_date']?.toString() ?? json['date']?.toString() ?? '',
      locationText: json['location_text']?.toString() ?? json['location']?.toString() ?? '',
      oneHealthIssue: json['one_health_issue']?.toString() ?? json['issue']?.toString() ?? '',
      situation: json['situation']?.toString() ?? json['problem']?.toString() ?? '',
      actionTaken: json['action_taken']?.toString() ?? json['action']?.toString() ?? '',
      departmentId: deptId,
      departmentIds: () {
        dynamic raw = json['department_ids'] ?? json['department_id'] ?? json['departments'] ?? json['department_id_list'];
        if (raw is String && raw.trim().startsWith('[') && raw.trim().endsWith(']')) {
          try {
            raw = jsonDecode(raw.trim());
          } catch (_) {}
        }
        if (raw is List) {
          return raw
              .map((e) {
                if (e is Map) {
                  final idVal = e['department_id'] ?? e['id'];
                  return int.tryParse(idVal?.toString() ?? '0') ?? 0;
                }
                return int.tryParse(e.toString()) ?? 0;
              })
              .where((id) => id > 0)
              .toList();
        }
        return deptId != null ? [deptId] : <int>[];
      }(),
      departmentName: () {
        dynamic rawName = json['department_name'] ?? json['department'];
        if (rawName is String && rawName.trim().startsWith('[') && rawName.trim().endsWith(']')) {
          try {
            rawName = jsonDecode(rawName.trim());
          } catch (_) {}
        }
        if (rawName is List) {
          final list = rawName
              .map((e) => e is Map ? (e['department_name'] ?? e['name'])?.toString() : e.toString())
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (list.isNotEmpty) return list.join(', ');
        } else if (rawName is String && rawName.trim().isNotEmpty) {
          final str = rawName.trim();
          if (str.startsWith('[') && str.endsWith(']')) {
            return str
                .substring(1, str.length - 1)
                .split(',')
                .map((s) => s.trim().replaceAll("'", "").replaceAll('"', ''))
                .where((s) => s.isNotEmpty)
                .join(', ');
          }
          return str;
        }
        final rawDepts = json['departments'];
        if (rawDepts is List && rawDepts.isNotEmpty) {
          final names = rawDepts
              .map((d) {
                if (d is Map) {
                  return (d['department_name'] ?? d['name'])?.toString();
                }
                return null;
              })
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toList();
          if (names.isNotEmpty) return names.join(', ');
        }
        return null;
      }(),
      departmentOther: json['department_other']?.toString(),
      caption: () {
        final root = json['caption']?.toString() ??
            json['media_caption']?.toString() ??
            json['description']?.toString() ??
            json['remarks']?.toString();
        if (root != null && root.trim().isNotEmpty) return root.trim();
        for (final listKey in ['attachments', 'photos', 'videos', 'documents']) {
          final list = json[listKey];
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                final c = item['caption']?.toString() ?? item['description']?.toString();
                if (c != null && c.trim().isNotEmpty) return c.trim();
              }
            }
          }
        }
        return null;
      }(),
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
      photos: (attList.any((a) => a.isImage))
          ? attList.where((a) => a.isImage).map((a) => a.storagePath.isNotEmpty ? a.storagePath : (a.fileUrl ?? '')).where((s) => s.isNotEmpty).toList()
          : photos,
      videos: (attList.any((a) => a.isVideo))
          ? attList.where((a) => a.isVideo).map((a) => a.storagePath.isNotEmpty ? a.storagePath : (a.fileUrl ?? '')).where((s) => s.isNotEmpty).toList()
          : videos,
      documents: (attList.any((a) => a.isDocument))
          ? attList.where((a) => a.isDocument).map((a) => a.storagePath.isNotEmpty ? a.storagePath : (a.fileUrl ?? '')).where((s) => s.isNotEmpty).toList()
          : documents,
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final trimmed = storyDate.trim();
    // 1. Try standard ISO parse (YYYY-MM-DD)
    try {
      final parsed = DateTime.parse(trimmed);
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {}

    // 2. Try DD/MM/YYYY or DD-MM-YYYY
    final parts = trimmed.split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      if (parts[2].length == 4) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null && month >= 1 && month <= 12) {
          return '$day ${months[month - 1]} $year';
        }
      }
    }
    return storyDate;
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

  /// Formatted department string for display on details screen
  String get formattedDepartments {
    if (departmentName != null && departmentName!.trim().isNotEmpty) {
      final trimmed = departmentName!.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        return trimmed
            .substring(1, trimmed.length - 1)
            .split(',')
            .map((s) => s.trim().replaceAll("'", "").replaceAll('"', ''))
            .where((s) => s.isNotEmpty)
            .join(', ');
      }
      return trimmed;
    }
    if (departmentOther != null && departmentOther!.trim().isNotEmpty) {
      return departmentOther!.trim();
    }
    if (departmentIds.isNotEmpty) {
      final names = departmentIds.map((id) {
        final match = SuccessStoryDepartmentModel.fallbackDepartments()
            .where((d) => d.departmentId == id);
        return match.isNotEmpty ? match.first.departmentName : 'Department $id';
      }).toList();
      return names.join(', ');
    }
    if (departmentId != null && departmentId! > 0) {
      final match = SuccessStoryDepartmentModel.fallbackDepartments()
          .where((d) => d.departmentId == departmentId);
      return match.isNotEmpty ? match.first.departmentName : 'Department $departmentId';
    }
    return '—';
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
    'department': formattedDepartments,
    'departmentId': departmentId,
    'departmentIds': departmentIds,
    'departmentOther': departmentOther,
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
