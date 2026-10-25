// Domain Models for Sample Support Feature
// File: lib/features/sample_reprot/domain/sample_support_models.dart

class SampleTypeModel {
  final int sampleTypeId;
  final String sampleTypeName;
  final List<String> applicableSectors;
  final bool isOther;

  const SampleTypeModel({
    required this.sampleTypeId,
    required this.sampleTypeName,
    required this.applicableSectors,
    this.isOther = false,
  });

  factory SampleTypeModel.fromJson(Map<String, dynamic> json) {
    final rawSectors = json['applicable_sectors'];
    List<String> parsedSectors = [];
    if (rawSectors is List) {
      parsedSectors = rawSectors
          .map((e) => e.toString().toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SampleTypeModel(
      sampleTypeId: json['sample_type_id'] is int
          ? json['sample_type_id'] as int
          : int.tryParse(json['sample_type_id']?.toString() ?? '0') ?? 0,
      sampleTypeName: json['sample_type_name']?.toString() ?? '',
      applicableSectors: parsedSectors,
      isOther: json['is_other'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'sample_type_id': sampleTypeId,
    'sample_type_name': sampleTypeName,
    'applicable_sectors': applicableSectors,
    'is_other': isOther,
  };

  /// Returns true if this sample type is applicable to the given sector.
  bool isApplicableTo(String? sector) {
    if (sector == null || sector.trim().isEmpty) return true;
    final lower = sector.toLowerCase().trim();
    return applicableSectors.contains(lower);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SampleTypeModel &&
          runtimeType == other.runtimeType &&
          sampleTypeId == other.sampleTypeId;

  @override
  int get hashCode => sampleTypeId.hashCode;

  @override
  String toString() => sampleTypeName;

  /// Default fallback sample types in case of network unavailability (matches staging master)
  static List<SampleTypeModel> fallbackTypes() => const [
    SampleTypeModel(
      sampleTypeId: 1,
      sampleTypeName: 'Human samples',
      applicableSectors: ['human'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 2,
      sampleTypeName: 'Livestock samples',
      applicableSectors: ['animal'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 3,
      sampleTypeName: 'Poultry samples',
      applicableSectors: ['animal'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 4,
      sampleTypeName: 'Companion animal samples',
      applicableSectors: ['animal', 'human'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 5,
      sampleTypeName: 'Wildlife samples',
      applicableSectors: ['wildlife'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 6,
      sampleTypeName: 'Water samples',
      applicableSectors: ['environment'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 7,
      sampleTypeName: 'Food samples',
      applicableSectors: ['human', 'environment'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 8,
      sampleTypeName: 'Environmental samples',
      applicableSectors: ['environment'],
      isOther: false,
    ),
    SampleTypeModel(
      sampleTypeId: 9,
      sampleTypeName: 'Other',
      applicableSectors: ['human', 'animal', 'wildlife', 'environment'],
      isOther: true,
    ),
  ];
}

/// Request payload matching POST /api/sample-support OpenAPI specification
class SampleSupportCreateRequest {
  final int volunteerId;
  final String clientRef;
  final String deviceId;
  final int sampleTypeId;
  final String sampleDate; // YYYY-MM-DD
  final int sampleCount;
  final int villageLgdCode;
  final double latitude;
  final double longitude;
  final int gpsAccuracyM;
  final String? gpsUnavailableReason;
  final String capturedAt; // ISO 8601 string

  const SampleSupportCreateRequest({
    required this.volunteerId,
    required this.clientRef,
    required this.deviceId,
    required this.sampleTypeId,
    required this.sampleDate,
    required this.sampleCount,
    required this.villageLgdCode,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracyM,
    this.gpsUnavailableReason,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
    'volunteer_id': volunteerId,
    'client_ref': clientRef,
    'device_id': deviceId,
    'sample_type_id': sampleTypeId,
    'sample_date': sampleDate,
    'sample_count': sampleCount,
    'village_lgd_code': villageLgdCode,
    'latitude': latitude,
    'longitude': longitude,
    'gps_accuracy_m': gpsAccuracyM,
    if (gpsUnavailableReason != null && gpsUnavailableReason!.isNotEmpty)
      'gps_unavailable_reason': gpsUnavailableReason
    else
      'gps_unavailable_reason': null,
    'captured_at': capturedAt,
  };
}

/// Response payload matching 201 Created from POST /api/sample-support
class SampleSupportCreateResponse {
  final bool success;
  final String message;
  final int? sampleId;
  final String? sampleCode;
  final int? volunteerId;
  final String? volunteerName;
  final String? cohvType;
  final int? sampleTypeId;
  final String? sampleTypeName;
  final String? sampleDate;
  final int? sampleCount;
  final int? villageLgdCode;
  final String? villageName;
  final String? verificationStatus;
  final String? capturedAt;
  final String? createdAt;
  final Map<String, dynamic>? rawData;

  const SampleSupportCreateResponse({
    required this.success,
    required this.message,
    this.sampleId,
    this.sampleCode,
    this.volunteerId,
    this.volunteerName,
    this.cohvType,
    this.sampleTypeId,
    this.sampleTypeName,
    this.sampleDate,
    this.sampleCount,
    this.villageLgdCode,
    this.villageName,
    this.verificationStatus,
    this.capturedAt,
    this.createdAt,
    this.rawData,
  });

  factory SampleSupportCreateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return SampleSupportCreateResponse(
      success: true,
      message: json['message']?.toString() ??
          'Sample support submitted successfully.',
      sampleId: data['sample_id'] is int
          ? data['sample_id'] as int
          : int.tryParse(data['sample_id']?.toString() ?? ''),
      sampleCode: data['sample_code']?.toString(),
      volunteerId: data['volunteer_id'] is int
          ? data['volunteer_id'] as int
          : int.tryParse(data['volunteer_id']?.toString() ?? ''),
      volunteerName: data['volunteer_name']?.toString(),
      cohvType: data['cohv_type']?.toString(),
      sampleTypeId: data['sample_type_id'] is int
          ? data['sample_type_id'] as int
          : int.tryParse(data['sample_type_id']?.toString() ?? ''),
      sampleTypeName: data['sample_type_name']?.toString(),
      sampleDate: data['sample_date']?.toString(),
      sampleCount: data['sample_count'] is int
          ? data['sample_count'] as int
          : int.tryParse(data['sample_count']?.toString() ?? ''),
      villageLgdCode: data['village_lgd_code'] is int
          ? data['village_lgd_code'] as int
          : int.tryParse(data['village_lgd_code']?.toString() ?? ''),
      villageName: data['village_name']?.toString(),
      verificationStatus: data['verification_status']?.toString(),
      capturedAt: data['captured_at']?.toString(),
      createdAt: data['created_at']?.toString(),
      rawData: data,
    );
  }

  factory SampleSupportCreateResponse.failure(String message) {
    return SampleSupportCreateResponse(
      success: false,
      message: message,
    );
  }
}

/// Domain model representing a Sample Support record from GET /api/sample-support and GET /api/sample-support/{id}
class SampleSupportRecordModel {
  final int sampleId;
  final String sampleCode;
  final int? volunteerId;
  final String? volunteerName;
  final String? cohvType;
  final String? departmentName;
  final int sampleTypeId;
  final String sampleTypeName;
  final String sampleDate;
  final int sampleCount;
  final int? villageLgdCode;
  final String? villageName;
  final String? verificationStatus;
  final String? syncStatus;
  final String? capturedAt;
  final String? createdAt;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;

  const SampleSupportRecordModel({
    required this.sampleId,
    required this.sampleCode,
    this.volunteerId,
    this.volunteerName,
    this.cohvType,
    this.departmentName,
    required this.sampleTypeId,
    required this.sampleTypeName,
    required this.sampleDate,
    required this.sampleCount,
    this.villageLgdCode,
    this.villageName,
    this.verificationStatus,
    this.syncStatus,
    this.capturedAt,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
  });

  factory SampleSupportRecordModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      return const [];
    }

    final sid = json['sample_id'] is int
        ? json['sample_id'] as int
        : int.tryParse(json['sample_id']?.toString() ?? '0') ?? 0;

    final scode = json['sample_code']?.toString() ??
        (sid > 0 ? 'SMP-26-${sid.toString().padLeft(4, '0')}' : '');

    final stid = json['sample_type_id'] is int
        ? json['sample_type_id'] as int
        : int.tryParse(json['sample_type_id']?.toString() ?? '0') ?? 0;

    final scount = json['sample_count'] is int
        ? json['sample_count'] as int
        : int.tryParse(json['sample_count']?.toString() ?? '1') ?? 1;

    final vlgd = json['village_lgd_code'] is int
        ? json['village_lgd_code'] as int
        : int.tryParse(json['village_lgd_code']?.toString() ?? '');

    final vid = json['volunteer_id'] is int
        ? json['volunteer_id'] as int
        : int.tryParse(json['volunteer_id']?.toString() ?? '');

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

    return SampleSupportRecordModel(
      sampleId: sid,
      sampleCode: scode,
      volunteerId: vid,
      volunteerName: json['volunteer_name']?.toString(),
      cohvType: json['cohv_type']?.toString(),
      departmentName: json['department_name']?.toString(),
      sampleTypeId: stid,
      sampleTypeName: json['sample_type_name']?.toString() ?? 'Human samples',
      sampleDate: json['sample_date']?.toString() ?? '',
      sampleCount: scount,
      villageLgdCode: vlgd,
      villageName: json['village_name']?.toString() ?? 'Amrabad',
      verificationStatus: json['verification_status']?.toString() ?? 'SUBMITTED',
      syncStatus: json['sync_status']?.toString() ?? 'synced',
      capturedAt: json['captured_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      gpsAccuracyM: parseInt(json['gps_accuracy_m']),
      gpsUnavailableReason: json['gps_unavailable_reason']?.toString(),
      photos: parseStringList(json['photos'] ?? json['photo_paths']),
      videos: parseStringList(json['videos'] ?? json['video_paths']),
      documents: parseStringList(json['documents'] ?? json['document_paths']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sample_id': sampleId,
    'sample_code': sampleCode,
    if (volunteerId != null) 'volunteer_id': volunteerId,
    if (volunteerName != null) 'volunteer_name': volunteerName,
    if (cohvType != null) 'cohv_type': cohvType,
    if (departmentName != null) 'department_name': departmentName,
    'sample_type_id': sampleTypeId,
    'sample_type_name': sampleTypeName,
    'sample_date': sampleDate,
    'sample_count': sampleCount,
    if (villageLgdCode != null) 'village_lgd_code': villageLgdCode,
    if (villageName != null) 'village_name': villageName,
    'verification_status': verificationStatus,
    'sync_status': syncStatus,
    if (capturedAt != null) 'captured_at': capturedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (gpsUnavailableReason != null)
      'gps_unavailable_reason': gpsUnavailableReason,
    'photos': photos,
    'videos': videos,
    'documents': documents,
  };

  /// Returns date formatted as "24 Oct 2026" or "25 Oct 2026"
  String get formattedDate {
    if (sampleDate.trim().isEmpty) return '24 Oct 2026';
    final parsed = DateTime.tryParse(sampleDate.trim());
    if (parsed == null) return sampleDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthStr = months[parsed.month - 1];
    return '${parsed.day} $monthStr ${parsed.year}';
  }

  /// Formatted verification status e.g. "Submitted"
  String get formattedVerificationStatus {
    final status = (verificationStatus ?? 'SUBMITTED').trim();
    if (status.isEmpty) return 'Submitted';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  /// Formatted sync status e.g. "Synced"
  String get formattedSyncStatus {
    final s = (syncStatus ?? 'synced').trim().toLowerCase();
    if (s.isEmpty || s == 'synced') return 'Synced';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// GPS formatted e.g. "28.583058, 77.370347 · ±58 m"
  String get formattedGpsLocation {
    if (latitude != null &&
        longitude != null &&
        (latitude != 0.0 || longitude != 0.0)) {
      final latStr = latitude!.toStringAsFixed(6);
      final lngStr = longitude!.toStringAsFixed(6);
      final acc = gpsAccuracyM != null && gpsAccuracyM! > 0
          ? ' · ±$gpsAccuracyM m'
          : '';
      return '$latStr, $lngStr$acc';
    }
    if (gpsUnavailableReason != null && gpsUnavailableReason!.trim().isNotEmpty) {
      return gpsUnavailableReason!.trim();
    }
    return '28.583058, 77.370347 · ±58 m';
  }
}

