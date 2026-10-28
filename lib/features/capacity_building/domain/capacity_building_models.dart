// Domain Models for Capacity Building Module
// File: lib/features/capacity_building/domain/capacity_building_models.dart

import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/models/geo_location_data.dart';

class TrainingMasterModel {
  final int trainingId;
  final String trainingName;
  final bool isOther;
  final int sortOrder;

  const TrainingMasterModel({
    required this.trainingId,
    required this.trainingName,
    this.isOther = false,
    this.sortOrder = 0,
  });

  factory TrainingMasterModel.fromJson(Map<String, dynamic> json) {
    return TrainingMasterModel(
      trainingId: json['training_id'] is int
          ? json['training_id'] as int
          : int.tryParse(json['training_id']?.toString() ?? '0') ?? 0,
      trainingName: json['training_name']?.toString() ?? '',
      isOther: json['is_other'] == true,
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'training_id': trainingId,
    'training_name': trainingName,
    'is_other': isOther,
    'sort_order': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingMasterModel &&
          runtimeType == other.runtimeType &&
          trainingId == other.trainingId;

  @override
  int get hashCode => trainingId.hashCode;

  @override
  String toString() => trainingName;

  /// Fallback active training master types matching backend master data
  static List<TrainingMasterModel> fallbackTypes() => const [
    TrainingMasterModel(
      trainingId: 1,
      trainingName: 'Initial COHV Training',
      isOther: false,
      sortOrder: 1,
    ),
    TrainingMasterModel(
      trainingId: 2,
      trainingName: 'Refresher Training',
      isOther: false,
      sortOrder: 2,
    ),
    TrainingMasterModel(
      trainingId: 3,
      trainingName: 'Disease-specific Training',
      isOther: false,
      sortOrder: 3,
    ),
    TrainingMasterModel(
      trainingId: 4,
      trainingName: 'Emergency Response',
      isOther: false,
      sortOrder: 4,
    ),
    TrainingMasterModel(
      trainingId: 5,
      trainingName: 'Digital Reporting',
      isOther: false,
      sortOrder: 5,
    ),
    TrainingMasterModel(
      trainingId: 6,
      trainingName: 'Rabies / Animal Bite Management',
      isOther: false,
      sortOrder: 6,
    ),
    TrainingMasterModel(
      trainingId: 7,
      trainingName: 'One Health Surveillance',
      isOther: false,
      sortOrder: 7,
    ),
    TrainingMasterModel(
      trainingId: 8,
      trainingName: 'Other',
      isOther: true,
      sortOrder: 99,
    ),
  ];
}

/// Request payload for creating a new Training Imparted record
class TrainingImpartedCreateRequest {
  final int trainingId;
  final String trainingDate; // YYYY-MM-DD
  final String? organisedBy;
  final String? duration;
  final String? remarks;
  final String? clientRef;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? capturedAt;
  final List<String> photos;
  final List<String> documents;
  final List<String> videos;

  const TrainingImpartedCreateRequest({
    required this.trainingId,
    required this.trainingDate,
    this.organisedBy,
    this.duration,
    this.remarks,
    this.clientRef,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.capturedAt,
    this.photos = const [],
    this.documents = const [],
    this.videos = const [],
  });

  Map<String, dynamic> toJson() => {
    'training_id': trainingId,
    'training_date': trainingDate,
    if (organisedBy != null && organisedBy!.trim().isNotEmpty)
      'organised_by': organisedBy!.trim(),
    if (duration != null && duration!.trim().isNotEmpty)
      'duration': duration!.trim(),
    if (remarks != null && remarks!.trim().isNotEmpty)
      'remarks': remarks!.trim(),
    if (clientRef != null && clientRef!.trim().isNotEmpty)
      'client_ref': clientRef!.trim(),
    if (deviceId != null && deviceId!.trim().isNotEmpty)
      'device_id': deviceId!.trim(),
    if (latitude != null)
      'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null)
      'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (capturedAt != null && capturedAt!.trim().isNotEmpty)
      'captured_at': capturedAt!.trim(),
  };
}

/// Training Imparted Record Model matching backend schema
class TrainingImpartedRecordModel {
  final int trainingImpartedId;
  final String trainingImpartedCode;
  final int? volunteerId;
  final String? volunteerName;
  final String? clientRef;
  final String? deviceId;
  final int trainingId;
  final String trainingName;
  final String trainingDate;
  final String? organisedBy;
  final String? duration;
  final String? remarks;
  final String? capturedAt;
  final String verificationStatus;
  final String? createdAt;
  final String? updatedAt;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;
  final List<String> attachments;
  final List<AppAttachmentItem> richAttachments;

  List<AppAttachmentItem> get appAttachments {
    final capDate = DateTime.tryParse(capturedAt ?? trainingDate);
    if (richAttachments.isNotEmpty) {
      return richAttachments.map((a) {
        if (a.latitude == null && latitude != null) {
          return a.copyWith(
            latitude: latitude,
            longitude: longitude,
            gpsAccuracyM: gpsAccuracyM,
            capturedAt: a.capturedAt ?? capDate,
          );
        }
        return a;
      }).toList();
    }
    final list = <AppAttachmentItem>[];
    for (final p in photos) {
      list.add(
        AppAttachmentItem.fromPath(
          p,
          fileKind: 'IMAGE',
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    for (final v in videos) {
      list.add(
        AppAttachmentItem.fromPath(
          v,
          fileKind: 'VIDEO',
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    for (final d in documents) {
      list.add(
        AppAttachmentItem.fromPath(
          d,
          fileKind: 'DOCUMENT',
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    for (final a in attachments) {
      list.add(
        AppAttachmentItem.fromPath(
          a,
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    return list;
  }

  const TrainingImpartedRecordModel({
    required this.trainingImpartedId,
    required this.trainingImpartedCode,
    this.volunteerId,
    this.volunteerName,
    this.clientRef,
    this.deviceId,
    required this.trainingId,
    required this.trainingName,
    required this.trainingDate,
    this.organisedBy,
    this.duration,
    this.remarks,
    this.capturedAt,
    this.verificationStatus = 'SUBMITTED',
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
    this.attachments = const [],
    this.richAttachments = const [],
  });

  factory TrainingImpartedRecordModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
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

    final parsedLat = parseDouble(json['latitude'] ?? json['lat']);
    final parsedLng = parseDouble(json['longitude'] ?? json['lng']);
    final parsedAcc = parseInt(json['gps_accuracy_m'] ?? json['accuracy']);

    final List<AppAttachmentItem> richList = [];
    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        if (a is Map) {
          richList.add(
            AppAttachmentItem.fromJson(Map<String, dynamic>.from(a)),
          );
        }
      }
    }

    return TrainingImpartedRecordModel(
      latitude: parsedLat,
      longitude: parsedLng,
      gpsAccuracyM: parsedAcc,
      gpsUnavailableReason: json['gps_unavailable_reason']?.toString(),
      trainingImpartedId: json['training_imparted_id'] is int
          ? json['training_imparted_id'] as int
          : int.tryParse(json['training_imparted_id']?.toString() ?? '0') ?? 0,
      trainingImpartedCode:
          json['training_imparted_code']?.toString() ?? 'TRI-RECORD',
      volunteerId: json['volunteer_id'] is int
          ? json['volunteer_id'] as int
          : int.tryParse(json['volunteer_id']?.toString() ?? ''),
      volunteerName: json['volunteer_name']?.toString(),
      clientRef: json['client_ref']?.toString(),
      deviceId: json['device_id']?.toString(),
      trainingId: json['training_id'] is int
          ? json['training_id'] as int
          : int.tryParse(json['training_id']?.toString() ?? '0') ?? 0,
      trainingName: json['training_name']?.toString() ?? 'Training',
      trainingDate: json['training_date']?.toString() ?? '',
      organisedBy: json['organised_by']?.toString(),
      duration: json['duration']?.toString(),
      remarks: json['remarks']?.toString(),
      capturedAt: json['captured_at']?.toString(),
      verificationStatus:
          json['verification_status']?.toString() ?? 'SUBMITTED',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      photos: parseStringList(json['photos']),
      videos: parseStringList(json['videos']),
      documents: parseStringList(json['documents']),
      attachments: parseStringList(json['attachments']),
      richAttachments: richList,
    );
  }

  Map<String, dynamic> toJson() => {
    'training_imparted_id': trainingImpartedId,
    'training_imparted_code': trainingImpartedCode,
    'volunteer_id': volunteerId,
    'volunteer_name': volunteerName,
    'client_ref': clientRef,
    'device_id': deviceId,
    'training_id': trainingId,
    'training_name': trainingName,
    'training_date': trainingDate,
    if (organisedBy != null) 'organised_by': organisedBy,
    if (duration != null) 'duration': duration,
    if (remarks != null) 'remarks': remarks,
    if (capturedAt != null) 'captured_at': capturedAt,
    'verification_status': verificationStatus,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    if (latitude != null)
      'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null)
      'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (gpsUnavailableReason != null)
      'gps_unavailable_reason': gpsUnavailableReason,
    'photos': photos,
    'videos': videos,
    'documents': documents,
    'attachments': attachments,
  };

  /// Formatted date string for display (e.g. "25 Oct 2026")
  String get displayDate {
    if (trainingDate.isEmpty) return 'Date not specified';
    try {
      final dt = DateTime.parse(trainingDate);
      final months = [
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
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      return '$day $month ${dt.year}';
    } catch (_) {
      return trainingDate;
    }
  }
}

/// Response returned from POST /api/capacity-building/training-imparted
class TrainingImpartedCreateResponse {
  final bool success;
  final String message;
  final TrainingImpartedRecordModel? record;

  const TrainingImpartedCreateResponse({
    required this.success,
    required this.message,
    this.record,
  });

  factory TrainingImpartedCreateResponse.fromJson(Map<String, dynamic> json) {
    TrainingImpartedRecordModel? record;
    if (json['data'] is Map<String, dynamic>) {
      record = TrainingImpartedRecordModel.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    } else if (json['data'] is Map) {
      record = TrainingImpartedRecordModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      );
    }

    return TrainingImpartedCreateResponse(
      success: json['success'] == true,
      message:
          json['message']?.toString() ??
          'Training imparted record saved successfully.',
      record: record,
    );
  }

  factory TrainingImpartedCreateResponse.failure(String message) {
    return TrainingImpartedCreateResponse(success: false, message: message);
  }
}

/// Request payload for creating a new Training Attended record
class TrainingAttendedCreateRequest {
  final int trainingId;
  final String trainingDate; // YYYY-MM-DD
  final String? venue;
  final String? chairedBy;
  final String? keyPoints;
  final bool certificateIssued;
  final String? clientRef;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? capturedAt;
  final List<String> photos;
  final List<String> documents;
  final List<String> videos;

  const TrainingAttendedCreateRequest({
    required this.trainingId,
    required this.trainingDate,
    this.venue,
    this.chairedBy,
    this.keyPoints,
    this.certificateIssued = false,
    this.clientRef,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.capturedAt,
    this.photos = const [],
    this.documents = const [],
    this.videos = const [],
  });

  Map<String, dynamic> toJson() => {
    'training_id': trainingId,
    'training_date': trainingDate,
    if (venue != null && venue!.trim().isNotEmpty) 'venue': venue!.trim(),
    if (chairedBy != null && chairedBy!.trim().isNotEmpty)
      'chaired_by': chairedBy!.trim(),
    if (keyPoints != null && keyPoints!.trim().isNotEmpty)
      'key_points': keyPoints!.trim(),
    'certificate_issued': certificateIssued,
    if (clientRef != null && clientRef!.trim().isNotEmpty)
      'client_ref': clientRef!.trim(),
    if (deviceId != null && deviceId!.trim().isNotEmpty)
      'device_id': deviceId!.trim(),
    if (latitude != null)
      'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null)
      'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (capturedAt != null && capturedAt!.trim().isNotEmpty)
      'captured_at': capturedAt!.trim(),
  };
}

/// Training Attended Record Model matching backend schema
class TrainingAttendedRecordModel {
  final int trainingAttendedId;
  final String trainingAttendedCode;
  final int? volunteerId;
  final String? volunteerName;
  final String? clientRef;
  final String? deviceId;
  final int trainingId;
  final String trainingName;
  final String trainingDate;
  final String? venue;
  final String? chairedBy;
  final String? keyPoints;
  final bool certificateIssued;
  final String? capturedAt;
  final String verificationStatus;
  final String? createdAt;
  final String? updatedAt;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;
  final List<String> attachments;
  final List<AppAttachmentItem> richAttachments;

  List<AppAttachmentItem> get appAttachments {
    final capDate = DateTime.tryParse(capturedAt ?? trainingDate);
    if (richAttachments.isNotEmpty) {
      return richAttachments.map((a) {
        if (a.latitude == null && latitude != null) {
          return a.copyWith(
            latitude: latitude,
            longitude: longitude,
            gpsAccuracyM: gpsAccuracyM,
            capturedAt: a.capturedAt ?? capDate,
          );
        }
        return a;
      }).toList();
    }
    final list = <AppAttachmentItem>[];
    for (final p in photos) {
      list.add(
        AppAttachmentItem.fromPath(
          p,
          fileKind: 'IMAGE',
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    for (final v in videos) {
      list.add(
        AppAttachmentItem.fromPath(
          v,
          fileKind: 'VIDEO',
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    for (final d in documents) {
      list.add(
        AppAttachmentItem.fromPath(
          d,
          fileKind: 'DOCUMENT',
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    for (final a in attachments) {
      list.add(
        AppAttachmentItem.fromPath(
          a,
          latitude: latitude,
          longitude: longitude,
          accuracy: gpsAccuracyM,
          capturedAt: capDate,
        ),
      );
    }
    return list;
  }

  const TrainingAttendedRecordModel({
    required this.trainingAttendedId,
    required this.trainingAttendedCode,
    this.volunteerId,
    this.volunteerName,
    this.clientRef,
    this.deviceId,
    required this.trainingId,
    required this.trainingName,
    required this.trainingDate,
    this.venue,
    this.chairedBy,
    this.keyPoints,
    this.certificateIssued = false,
    this.capturedAt,
    this.verificationStatus = 'SUBMITTED',
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
    this.attachments = const [],
    this.richAttachments = const [],
  });

  factory TrainingAttendedRecordModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
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

    final parsedLat = parseDouble(json['latitude'] ?? json['lat']);
    final parsedLng = parseDouble(json['longitude'] ?? json['lng']);
    final parsedAcc = parseInt(json['gps_accuracy_m'] ?? json['accuracy']);

    final List<AppAttachmentItem> richList = [];
    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        if (a is Map) {
          richList.add(
            AppAttachmentItem.fromJson(Map<String, dynamic>.from(a)),
          );
        }
      }
    }

    return TrainingAttendedRecordModel(
      latitude: parsedLat,
      longitude: parsedLng,
      gpsAccuracyM: parsedAcc,
      gpsUnavailableReason: json['gps_unavailable_reason']?.toString(),
      trainingAttendedId: json['training_attended_id'] is int
          ? json['training_attended_id'] as int
          : int.tryParse(json['training_attended_id']?.toString() ?? '0') ?? 0,
      trainingAttendedCode:
          json['training_attended_code']?.toString() ?? 'TRN-RECORD',
      volunteerId: json['volunteer_id'] is int
          ? json['volunteer_id'] as int
          : int.tryParse(json['volunteer_id']?.toString() ?? ''),
      volunteerName: json['volunteer_name']?.toString(),
      clientRef: json['client_ref']?.toString(),
      deviceId: json['device_id']?.toString(),
      trainingId: json['training_id'] is int
          ? json['training_id'] as int
          : int.tryParse(json['training_id']?.toString() ?? '0') ?? 0,
      trainingName: json['training_name']?.toString() ?? 'Training',
      trainingDate: json['training_date']?.toString() ?? '',
      venue: json['venue']?.toString(),
      chairedBy: json['chaired_by']?.toString(),
      keyPoints: json['key_points']?.toString(),
      certificateIssued: json['certificate_issued'] == true,
      capturedAt: json['captured_at']?.toString(),
      verificationStatus:
          json['verification_status']?.toString() ?? 'SUBMITTED',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      photos: parseStringList(json['photos']),
      videos: parseStringList(json['videos']),
      documents: parseStringList(json['documents']),
      attachments: parseStringList(json['attachments']),
      richAttachments: richList,
    );
  }

  Map<String, dynamic> toJson() => {
    'training_attended_id': trainingAttendedId,
    'training_attended_code': trainingAttendedCode,
    'volunteer_id': volunteerId,
    'volunteer_name': volunteerName,
    'client_ref': clientRef,
    'device_id': deviceId,
    'training_id': trainingId,
    'training_name': trainingName,
    'training_date': trainingDate,
    if (venue != null) 'venue': venue,
    if (chairedBy != null) 'chaired_by': chairedBy,
    if (keyPoints != null) 'key_points': keyPoints,
    'certificate_issued': certificateIssued,
    if (capturedAt != null) 'captured_at': capturedAt,
    'verification_status': verificationStatus,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    if (latitude != null)
      'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null)
      'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (gpsUnavailableReason != null)
      'gps_unavailable_reason': gpsUnavailableReason,
    'photos': photos,
    'videos': videos,
    'documents': documents,
    'attachments': attachments,
  };

  /// Formatted date string for display (e.g. "25 Oct 2026")
  String get displayDate {
    if (trainingDate.isEmpty) return 'Date not specified';
    try {
      final dt = DateTime.parse(trainingDate);
      final months = [
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
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      return '$day $month ${dt.year}';
    } catch (_) {
      return trainingDate;
    }
  }
}

/// Response returned from POST /api/capacity-building/training-attended
class TrainingAttendedCreateResponse {
  final bool success;
  final String message;
  final TrainingAttendedRecordModel? record;

  const TrainingAttendedCreateResponse({
    required this.success,
    required this.message,
    this.record,
  });

  factory TrainingAttendedCreateResponse.fromJson(Map<String, dynamic> json) {
    TrainingAttendedRecordModel? record;
    if (json['data'] is Map<String, dynamic>) {
      record = TrainingAttendedRecordModel.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    } else if (json['data'] is Map) {
      record = TrainingAttendedRecordModel.fromJson(
        Map<String, dynamic>.from(json['data'] as Map),
      );
    }

    return TrainingAttendedCreateResponse(
      success: json['success'] == true,
      message:
          json['message']?.toString() ??
          'Training attended record saved successfully.',
      record: record,
    );
  }

  factory TrainingAttendedCreateResponse.failure(String message) {
    return TrainingAttendedCreateResponse(success: false, message: message);
  }
}

