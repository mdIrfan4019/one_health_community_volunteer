// Domain models for Awareness Activities feature
// File: lib/features/awareness/domain/awareness_models.dart

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
      awarenessActivityName:
          json['awareness_activity_name']?.toString() ?? '',
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

class AwarenessItem {
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
  final List<String> mediaFiles;
  final String? mediaCaption;
  final double latitude;
  final double longitude;
  final int accuracy;
  final String volunteerId;
  final String deviceId;

  AwarenessItem({
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
    this.mediaFiles = const [],
    this.mediaCaption,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.volunteerId,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
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
    'media_files': mediaFiles,
    'media_caption': mediaCaption,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'volunteer_id': volunteerId,
    'device_id': deviceId,
  };

  factory AwarenessItem.fromJson(Map<String, dynamic> json) => AwarenessItem(
    id: json['id'] ?? json['awareness_code'] ?? 'AWR-26-0001',
    awarenessActivityId: json['awareness_activity_id'] is int
        ? json['awareness_activity_id'] as int
        : int.tryParse(json['awareness_activity_id']?.toString() ?? ''),
    activityType: json['activity_type'] ??
        json['awareness_activity_name'] ??
        'Village meetings',
    otherActivityName: json['other_activity_name']?.toString(),
    date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    villageLgdCode: json['village_lgd_code'] is int
        ? json['village_lgd_code'] as int
        : int.tryParse(json['village_lgd_code']?.toString() ?? ''),
    village: json['village_name'] ?? json['village'] ?? 'Amrabad',
    peopleReached: (json['people_reached'] as num?)?.toInt() ?? 0,
    topicId: json['topic_id'] is int
        ? json['topic_id'] as int
        : int.tryParse(json['topic_id']?.toString() ?? ''),
    topicCovered: json['topic_covered'] ??
        json['awareness_topic_name'] ??
        'General Health',
    otherTopicName: json['other_topic_name']?.toString(),
    departmentId: json['department_id'] is int
        ? json['department_id'] as int
        : int.tryParse(json['department_id']?.toString() ?? ''),
    departmentInvolved: json['department_involved'] ??
        json['department_name'] ??
        'Health Department',
    status: json['status'] ?? json['verification_status'] ?? 'synced',
    mediaFiles: List<String>.from(json['media_files'] ?? []),
    mediaCaption: json['media_caption'],
    latitude: (json['latitude'] as num?)?.toDouble() ?? 28.60928,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 77.367449,
    accuracy: (json['accuracy'] as num?)?.toInt() ?? 133,
    volunteerId: json['volunteer_id']?.toString() ?? 'COHV-26-0001',
    deviceId: json['device_id']?.toString() ?? 'DEV-C0YBZ9WK',
  );
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
