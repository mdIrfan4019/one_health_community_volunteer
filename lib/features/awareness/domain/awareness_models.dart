// Domain models for Awareness Activities feature
// File: lib/features/awareness/domain/awareness_models.dart

import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/models/geo_location_data.dart';

class AwarenessActivityTypeModel {
  final int awarenessActivityId;
  final String awarenessActivityName;
  final List<String> applicableSectors;
  final bool isOther;

  const AwarenessActivityTypeModel({
    required this.awarenessActivityId,
    required this.awarenessActivityName,
    this.applicableSectors = const [],
    this.isOther = false,
  });

  factory AwarenessActivityTypeModel.fromJson(Map<String, dynamic> json) {
    return AwarenessActivityTypeModel(
      awarenessActivityId: json['awareness_activity_id'] is int
          ? json['awareness_activity_id'] as int
          : int.tryParse(json['awareness_activity_id']?.toString() ?? '0') ?? 0,
      awarenessActivityName: json['awareness_activity_name']?.toString() ?? '',
      applicableSectors: (json['applicable_sectors'] is List)
          ? (json['applicable_sectors'] as List)
                .map((e) => e.toString().toLowerCase().trim())
                .toList()
          : const [],
      isOther: json['is_other'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'awareness_activity_id': awarenessActivityId,
    'awareness_activity_name': awarenessActivityName,
    'applicable_sectors': applicableSectors,
    'is_other': isOther,
  };

  @override
  String toString() => awarenessActivityName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AwarenessActivityTypeModel &&
          runtimeType == other.runtimeType &&
          awarenessActivityId == other.awarenessActivityId;

  @override
  int get hashCode => awarenessActivityId.hashCode;
}

class AwarenessTopicModel {
  final int awarenessTopicId;
  final String awarenessTopicName;
  final bool isOther;

  const AwarenessTopicModel({
    required this.awarenessTopicId,
    required this.awarenessTopicName,
    this.isOther = false,
  });

  factory AwarenessTopicModel.fromJson(Map<String, dynamic> json) {
    return AwarenessTopicModel(
      awarenessTopicId: json['awareness_topic_id'] is int
          ? json['awareness_topic_id'] as int
          : int.tryParse(json['awareness_topic_id']?.toString() ?? '0') ?? 0,
      awarenessTopicName: json['awareness_topic_name']?.toString() ?? '',
      isOther: json['is_other'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'awareness_topic_id': awarenessTopicId,
    'awareness_topic_name': awarenessTopicName,
    'is_other': isOther,
  };

  @override
  String toString() => awarenessTopicName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AwarenessTopicModel &&
          runtimeType == other.runtimeType &&
          awarenessTopicId == other.awarenessTopicId;

  @override
  int get hashCode => awarenessTopicId.hashCode;
}

class AwarenessAttachmentItem {
  final int attachmentId;
  final String fileKind; // 'IMAGE', 'VIDEO', 'DOCUMENT'
  final String fileName;
  final String storagePath;
  final String? mimeType;
  final int sizeBytes;
  final String? caption;
  final String? fileUrl;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final DateTime? capturedAt;

  const AwarenessAttachmentItem({
    required this.attachmentId,
    required this.fileKind,
    required this.fileName,
    required this.storagePath,
    this.mimeType,
    this.sizeBytes = 0,
    this.caption,
    this.fileUrl,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.capturedAt,
  });

  AppAttachmentItem toAppAttachment({
    double? fallbackLat,
    double? fallbackLng,
    int? fallbackAcc,
    DateTime? fallbackDt,
  }) {
    return AppAttachmentItem(
      attachmentId: attachmentId,
      fileKind: fileKind,
      fileName: fileName,
      storagePath: storagePath,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      fileUrl: fileUrl,
      latitude: latitude ?? fallbackLat,
      longitude: longitude ?? fallbackLng,
      gpsAccuracyM: gpsAccuracyM ?? fallbackAcc,
      capturedAt: capturedAt ?? fallbackDt,
      caption: caption,
    );
  }

  factory AwarenessAttachmentItem.fromJson(Map<String, dynamic> json) {
    final rawFileName =
        (json['file_name'] ?? json['filename'] ?? json['name'] ?? '')
            .toString();
    final rawStorage =
        (json['storage_path'] ?? json['file_path'] ?? json['path'] ?? '')
            .toString();
    final rawUrl = (json['file_url'] ?? json['url'])?.toString();

    String name = rawFileName;
    if (name.isEmpty) {
      if (rawStorage.isNotEmpty) {
        name = rawStorage.split('/').last;
      } else if (rawUrl != null && rawUrl.isNotEmpty) {
        name = rawUrl.split('/').last.split('?').first;
      }
    }

    final lat = json['latitude'] != null
        ? double.tryParse(json['latitude'].toString())
        : (json['lat'] != null
              ? double.tryParse(json['lat'].toString())
              : null);
    final lng = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString())
        : (json['lng'] != null
              ? double.tryParse(json['lng'].toString())
              : null);
    final acc = json['gps_accuracy_m'] != null
        ? int.tryParse(json['gps_accuracy_m'].toString())
        : (json['accuracy'] != null
              ? int.tryParse(json['accuracy'].toString())
              : null);
    final rawDt =
        json['captured_at'] ??
        json['created_at'] ??
        json['timestamp'] ??
        json['date'];

    return AwarenessAttachmentItem(
      attachmentId: json['attachment_id'] is int
          ? json['attachment_id'] as int
          : (json['id'] is int
                ? json['id'] as int
                : int.tryParse(
                        json['attachment_id']?.toString() ??
                            json['id']?.toString() ??
                            '0',
                      ) ??
                      0),
      fileKind: json['file_kind']?.toString() ?? 'IMAGE',
      fileName: name,
      storagePath: rawStorage,
      mimeType:
          json['mime_type']?.toString() ?? json['content_type']?.toString(),
      sizeBytes: json['size_bytes'] is int
          ? json['size_bytes'] as int
          : int.tryParse(
                  json['size_bytes']?.toString() ??
                      json['size']?.toString() ??
                      '0',
                ) ??
                0,
      caption: json['caption']?.toString() ?? json['description']?.toString(),
      fileUrl: rawUrl,
      latitude: lat,
      longitude: lng,
      gpsAccuracyM: acc,
      capturedAt: rawDt != null
          ? DateTime.tryParse(rawDt.toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'attachment_id': attachmentId,
    'file_kind': fileKind,
    'file_name': fileName,
    'storage_path': storagePath,
    'mime_type': mimeType,
    'size_bytes': sizeBytes,
    'caption': caption,
    if (fileUrl != null) 'file_url': fileUrl,
    if (latitude != null)
      'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null)
      'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (capturedAt != null)
      'captured_at': capturedAt!.toUtc().toIso8601String(),
  };
}

class AwarenessItem {
  final int? awarenessId;
  final String id; // e.g. AWR-26-0006
  final int? awarenessActivityId;
  final String activityType; // e.g. Village meetings
  final String? otherActivityName;
  final DateTime date;
  final int? villageLgdCode;
  final String village;
  final int peopleReached;
  final int? topicId;
  final String topicCovered;
  final String? otherTopicName;
  final int? departmentId;
  final String departmentInvolved;
  final String status; // 'synced' or 'pending'
  final String? verificationStatus;
  final List<AwarenessAttachmentItem> attachments;
  final List<String> mediaFiles;
  final String? mediaCaption;
  final double? latitude;
  final double? longitude;
  final int? accuracy;
  final String volunteerId;
  final int? numericVolunteerId;
  final String? volunteerName;
  final String? volunteerCode;
  final String deviceId;

  List<AppAttachmentItem> get appAttachments {
    if (attachments.isNotEmpty) {
      return attachments
          .map(
            (a) => a.toAppAttachment(
              fallbackLat: latitude,
              fallbackLng: longitude,
              fallbackAcc: accuracy,
              fallbackDt: date,
            ),
          )
          .toList();
    }
    return mediaFiles
        .map(
          (p) => AppAttachmentItem.fromPath(
            p,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            capturedAt: date,
          ),
        )
        .toList();
  }

  AwarenessItem({
    this.awarenessId,
    required this.id,
    this.awarenessActivityId,
    required this.activityType,
    this.otherActivityName,
    required this.date,
    this.villageLgdCode,
    required this.village,
    required this.peopleReached,
    this.topicId,
    required this.topicCovered,
    this.otherTopicName,
    this.departmentId,
    required this.departmentInvolved,
    this.status = 'synced',
    this.verificationStatus,
    this.attachments = const [],
    this.mediaFiles = const [],
    this.mediaCaption,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.volunteerId,
    this.numericVolunteerId,
    this.volunteerName,
    this.volunteerCode,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    if (awarenessId != null) 'awareness_id': awarenessId,
    'id': id,
    'awareness_activity_id': awarenessActivityId,
    'activity_type': activityType,
    if (otherActivityName != null) 'other_activity_name': otherActivityName,
    'date': date.toIso8601String(),
    if (villageLgdCode != null) 'village_lgd_code': villageLgdCode,
    'village': village,
    'people_reached': peopleReached,
    if (topicId != null) 'topic_id': topicId,
    'topic_covered': topicCovered,
    if (otherTopicName != null) 'other_topic_name': otherTopicName,
    if (departmentId != null) 'department_id': departmentId,
    'department_involved': departmentInvolved,
    'status': status,
    if (verificationStatus != null) 'verification_status': verificationStatus,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'media_files': mediaFiles,
    'media_caption': mediaCaption,
    if (latitude != null)
      'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null)
      'longitude': GeoLocationData.formatCoordinate(longitude),
    'accuracy': accuracy,
    'volunteer_id': volunteerId,
    if (numericVolunteerId != null) 'numeric_volunteer_id': numericVolunteerId,
    if (volunteerName != null) 'volunteer_name': volunteerName,
    if (volunteerCode != null) 'volunteer_code': volunteerCode,
    'device_id': deviceId,
  };

  factory AwarenessItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['activity_date'] ?? json['date'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    final rawAwarenessId = json['awareness_id'];
    final int? parsedAwarenessId = rawAwarenessId is int
        ? rawAwarenessId
        : int.tryParse(rawAwarenessId?.toString() ?? '');

    final parsedLat = json['latitude'] != null
        ? double.tryParse(json['latitude'].toString())
        : (json['lat'] != null
              ? double.tryParse(json['lat'].toString())
              : null);
    final parsedLng = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString())
        : (json['lng'] != null
              ? double.tryParse(json['lng'].toString())
              : null);
    final parsedAcc = json['gps_accuracy_m'] != null
        ? int.tryParse(json['gps_accuracy_m'].toString())
        : (json['accuracy'] != null
              ? int.tryParse(json['accuracy'].toString())
              : null);

    List<String> parseStringList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      return const [];
    }

    final rawAttach = json['attachments'];
    final List<AwarenessAttachmentItem> richAttachments = [];
    final List<String> files = [];
    if (rawAttach is List) {
      for (final a in rawAttach) {
        if (a is Map) {
          final att = AwarenessAttachmentItem.fromJson(
            Map<String, dynamic>.from(a),
          );
          richAttachments.add(att);
          if (att.storagePath.isNotEmpty) {
            files.add(att.storagePath);
          }
        } else if (a is String && a.trim().isNotEmpty) {
          final att = AwarenessAttachmentItem(
            attachmentId: 0,
            fileKind: 'IMAGE',
            fileName: a.split('/').last,
            storagePath: a,
            fileUrl: a.startsWith('http') ? a : null,
            latitude: parsedLat,
            longitude: parsedLng,
            gpsAccuracyM: parsedAcc,
            capturedAt: parsedDate,
          );
          richAttachments.add(att);
          files.add(a);
        }
      }
    }

    final rawPhotos = parseStringList(json['photos'] ?? json['photo_paths']);
    final rawVideos = parseStringList(json['videos'] ?? json['video_paths']);
    final rawDocs =
        parseStringList(json['documents'] ?? json['document_paths']);
    if (richAttachments.isEmpty) {
      for (final p in rawPhotos) {
        richAttachments.add(
          AwarenessAttachmentItem(
            attachmentId: 0,
            fileKind: 'IMAGE',
            fileName: p.split('/').last,
            storagePath: p,
            fileUrl: p.startsWith('http') ? p : null,
            latitude: parsedLat,
            longitude: parsedLng,
            gpsAccuracyM: parsedAcc,
            capturedAt: parsedDate,
          ),
        );
        files.add(p);
      }
      for (final v in rawVideos) {
        richAttachments.add(
          AwarenessAttachmentItem(
            attachmentId: 0,
            fileKind: 'VIDEO',
            fileName: v.split('/').last,
            storagePath: v,
            fileUrl: v.startsWith('http') ? v : null,
            latitude: parsedLat,
            longitude: parsedLng,
            gpsAccuracyM: parsedAcc,
            capturedAt: parsedDate,
          ),
        );
        files.add(v);
      }
      for (final d in rawDocs) {
        richAttachments.add(
          AwarenessAttachmentItem(
            attachmentId: 0,
            fileKind: 'DOCUMENT',
            fileName: d.split('/').last,
            storagePath: d,
            fileUrl: d.startsWith('http') ? d : null,
            latitude: parsedLat,
            longitude: parsedLng,
            gpsAccuracyM: parsedAcc,
            capturedAt: parsedDate,
          ),
        );
        files.add(d);
      }
      if (files.isEmpty && json['media_files'] is List) {
        files.addAll(List<String>.from(json['media_files']));
      }
    }

    // Combine topic name and topic_other if multiple topics or specify topic is stored
    final String topicName =
        json['awareness_topic_name']?.toString() ??
        json['topic_covered']?.toString() ??
        '';
    final String? topicOther =
        json['topic_other']?.toString() ?? json['other_topic_name']?.toString();

    String combinedTopic = topicName;
    if (topicOther != null && topicOther.trim().isNotEmpty) {
      final cleanOther = topicOther
          .replaceFirst(RegExp(r'^Also:\s*', caseSensitive: false), '')
          .trim();
      if (cleanOther.isNotEmpty) {
        if (combinedTopic.isNotEmpty && !combinedTopic.contains(cleanOther)) {
          combinedTopic = '$combinedTopic; $cleanOther';
        } else if (combinedTopic.isEmpty) {
          combinedTopic = cleanOther;
        }
      }
    }
    if (combinedTopic.isEmpty) {
      combinedTopic = 'General Health';
    }

    final rawVerStatus = json['verification_status']?.toString();
    final rawStatus = json['status']?.toString();

    return AwarenessItem(
      awarenessId: parsedAwarenessId,
      id:
          json['awareness_code']?.toString() ??
          json['id']?.toString() ??
          'AWR-26-0001',
      awarenessActivityId: json['awareness_activity_id'] is int
          ? json['awareness_activity_id'] as int
          : int.tryParse(json['awareness_activity_id']?.toString() ?? ''),
      activityType:
          json['awareness_activity_name']?.toString() ??
          json['activity_type']?.toString() ??
          'Village meetings',
      otherActivityName: json['other_activity_name']?.toString(),
      date: parsedDate,
      villageLgdCode: json['village_lgd_code'] is int
          ? json['village_lgd_code'] as int
          : int.tryParse(json['village_lgd_code']?.toString() ?? ''),
      village:
          json['village_name']?.toString() ??
          json['village']?.toString() ??
          'Amrabad',
      peopleReached: (json['people_reached'] as num?)?.toInt() ?? 0,
      topicId: json['awareness_topic_id'] is int
          ? json['awareness_topic_id'] as int
          : (json['topic_id'] is int
                ? json['topic_id'] as int
                : int.tryParse(
                    json['awareness_topic_id']?.toString() ??
                        json['topic_id']?.toString() ??
                        '',
                  )),
      topicCovered: combinedTopic,
      otherTopicName: topicOther,
      departmentId: json['department_id'] is int
          ? json['department_id'] as int
          : int.tryParse(json['department_id']?.toString() ?? ''),
      departmentInvolved:
          json['department_name']?.toString() ??
          json['department_involved']?.toString() ??
          'Health Department',
      status:
          rawStatus ??
          (rawVerStatus != null ? rawVerStatus.toLowerCase() : 'synced'),
      verificationStatus: rawVerStatus ?? 'SUBMITTED',
      attachments: richAttachments,
      mediaFiles: files,
      latitude: parsedLat,
      longitude: parsedLng,
      accuracy: parsedAcc,
      volunteerId:
          json['volunteer_code']?.toString() ??
          json['volunteer_id']?.toString() ??
          '',
      numericVolunteerId: json['volunteer_id'] is int
          ? json['volunteer_id'] as int
          : (json['numeric_volunteer_id'] is int
                ? json['numeric_volunteer_id'] as int
                : int.tryParse(json['volunteer_id']?.toString() ?? '')),
      volunteerName: json['volunteer_name']?.toString(),
      volunteerCode: json['volunteer_code']?.toString(),
      deviceId: json['device_id']?.toString() ?? 'DEV-C0YBZ9WK',
    );
  }
}

class VolunteerSessionInfo {
  final String volunteerCode;
  final String cohvType;
  final String sectorKey; // 'human', 'animal', 'wildlife', 'environment'
  final int? gramPanchayatLgdCode;
  final String? gramPanchayatName;
  final int? villageLgdCode;
  final String? villageName;
  final String? blockName;
  final String? districtName;
  final String? stateName;

  const VolunteerSessionInfo({
    required this.volunteerCode,
    required this.cohvType,
    required this.sectorKey,
    this.gramPanchayatLgdCode,
    this.gramPanchayatName,
    this.villageLgdCode,
    this.villageName,
    this.blockName,
    this.districtName,
    this.stateName,
  });
}

/// Request payload for POST /api/awareness-activities (multipart/form-data)
class AwarenessActivityCreateRequest {
  final String? clientRef;
  final String? deviceId;
  final int awarenessActivityId;
  final DateTime activityDate;
  final int villageLgdCode;
  final int? peopleReached;
  final int? awarenessTopicId;
  final String? topicOther;
  final int? departmentId;
  final String? departmentOther;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;

  AwarenessActivityCreateRequest({
    this.clientRef,
    this.deviceId,
    required this.awarenessActivityId,
    required this.activityDate,
    required this.villageLgdCode,
    this.peopleReached,
    this.awarenessTopicId,
    this.topicOther,
    this.departmentId,
    this.departmentOther,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
  });
}

/// Response model from POST /api/awareness-activities
class AwarenessActivitySubmitResponse {
  final String message;
  final int awarenessId;
  final String awarenessCode;
  final String verificationStatus;
  final bool duplicate;

  AwarenessActivitySubmitResponse({
    required this.message,
    required this.awarenessId,
    required this.awarenessCode,
    required this.verificationStatus,
    this.duplicate = false,
  });

  factory AwarenessActivitySubmitResponse.fromJson(Map<String, dynamic> json) {
    return AwarenessActivitySubmitResponse(
      message:
          json['message']?.toString() ??
          'Awareness activity submitted successfully.',
      awarenessId: json['awareness_id'] is int
          ? json['awareness_id'] as int
          : int.tryParse(json['awareness_id']?.toString() ?? '0') ?? 0,
      awarenessCode: json['awareness_code']?.toString() ?? '',
      verificationStatus:
          json['verification_status']?.toString() ?? 'SUBMITTED',
      duplicate: json['duplicate'] == true,
    );
  }
}
