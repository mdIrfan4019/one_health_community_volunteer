// Create file: lib/features/awareness/domain/awareness_models.dart

class AwarenessItem {
  final String id; // e.g. AWR-26-0006
  final String activityType; // e.g. Village meetings
  final DateTime date;
  final String village;
  final int peopleReached;
  final String topicCovered;
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
    required this.activityType,
    required this.date,
    required this.village,
    required this.peopleReached,
    required this.topicCovered,
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
    'activity_type': activityType,
    'date': date.toIso8601String(),
    'village': village,
    'people_reached': peopleReached,
    'topic_covered': topicCovered,
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
    id: json['id'] ?? 'AWR-26-0001',
    activityType: json['activity_type'] ?? 'Village meetings',
    date: DateTime.parse(json['date']),
    village: json['village'] ?? 'Amrabad',
    peopleReached: (json['people_reached'] as num?)?.toInt() ?? 0,
    topicCovered: json['topic_covered'] ?? 'General Health',
    departmentInvolved: json['department_involved'] ?? 'Health Department',
    status: json['status'] ?? 'synced',
    mediaFiles: List<String>.from(json['media_files'] ?? []),
    mediaCaption: json['media_caption'],
    latitude: (json['latitude'] as num?)?.toDouble() ?? 28.60928,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 77.367449,
    accuracy: (json['accuracy'] as num?)?.toInt() ?? 133,
    volunteerId: json['volunteer_id'] ?? 'COHV-26-0001',
    deviceId: json['device_id'] ?? 'DEV-C0YBZ9WK',
  );
}
