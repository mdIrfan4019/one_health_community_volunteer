// Domain models for Event Reporting & Dynamic Form Metadata
// File: lib/features/events/domain/event_models.dart

class EventReportRequest {
  final int eventTypeId;
  final String? eventTypeOther;
  final String eventType; // Human-readable name
  final String primarySector;
  final String? primarySectorCode;
  final DateTime date;
  final String time; // HH:mm:ss format
  final int villageLgdCode;
  final String village; // Human-readable village name
  final String? gramPanchayat;
  final String? blockName;
  final bool isOutOfAreaVisit;
  final String purposeOfVisit;
  final String locationType;
  final int totalVisits;
  final int populationTypeId;
  final String? populationOther;
  final String targetPopulation; // Human-readable population name
  final String observations;
  final String actionTaken;
  final String? description; // Media caption / description
  final bool isReferralGenerated;
  final bool isAlertGenerated;
  final bool isFollowUpRequired;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;
  final double latitude;
  final double longitude;
  final int accuracy;
  final String? gpsUnavailableReason;
  final String volunteerId;
  final String deviceId;
  final String? clientRef;

  // Backward compatibility getters
  List<String> get mediaFiles => [...photos, ...videos, ...documents];
  String? get mediaCaption => description;

  EventReportRequest({
    required this.eventTypeId,
    this.eventTypeOther,
    required this.eventType,
    required this.primarySector,
    this.primarySectorCode,
    required this.date,
    required this.time,
    required this.villageLgdCode,
    required this.village,
    this.gramPanchayat,
    this.blockName,
    required this.isOutOfAreaVisit,
    required this.purposeOfVisit,
    required this.locationType,
    required this.totalVisits,
    required this.populationTypeId,
    this.populationOther,
    required this.targetPopulation,
    required this.observations,
    required this.actionTaken,
    String? description,
    String? mediaCaption,
    required this.isReferralGenerated,
    required this.isAlertGenerated,
    required this.isFollowUpRequired,
    List<String>? photos,
    List<String>? videos,
    List<String>? documents,
    List<String>? mediaFiles,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.gpsUnavailableReason,
    required this.volunteerId,
    required this.deviceId,
    this.clientRef,
  })  : description = description ?? mediaCaption,
        photos = photos ?? mediaFiles ?? [],
        videos = videos ?? [],
        documents = documents ?? [];

  Map<String, dynamic> toJson() => {
        'event_type_id': eventTypeId,
        if (eventTypeOther != null && eventTypeOther!.isNotEmpty)
          'event_type_other': eventTypeOther,
        'event_type': eventType,
        'primary_sector': primarySector,
        if (primarySectorCode != null) 'primary_sector_code': primarySectorCode,
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'time': time,
        'village_lgd_code': villageLgdCode,
        'village': village,
        if (gramPanchayat != null) 'gram_panchayat': gramPanchayat,
        if (blockName != null) 'block_name': blockName,
        'is_out_of_area': isOutOfAreaVisit,
        'is_out_of_area_visit': isOutOfAreaVisit,
        'purpose_of_visit': purposeOfVisit,
        'location_type': locationType,
        'total_visits': totalVisits,
        'population_type_id': populationTypeId,
        if (populationOther != null && populationOther!.isNotEmpty)
          'population_other': populationOther,
        'target_population': targetPopulation,
        'observations': observations,
        'action_taken': actionTaken,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'media_caption': description,
        'referral_generated': isReferralGenerated,
        'is_referral_generated': isReferralGenerated,
        'alert_generated': isAlertGenerated,
        'is_alert_generated': isAlertGenerated,
        'follow_up_required': isFollowUpRequired,
        'is_follow_up_required': isFollowUpRequired,
        'photos': photos,
        'videos': videos,
        'documents': documents,
        'media_files': mediaFiles,
        'latitude': latitude,
        'longitude': longitude,
        'gps_accuracy_m': accuracy,
        'accuracy': accuracy,
        if (gpsUnavailableReason != null)
          'gps_unavailable_reason': gpsUnavailableReason,
        'volunteer_id': volunteerId,
        'device_id': deviceId,
        if (clientRef != null) 'client_ref': clientRef,
      };
}

class EventReportResult {
  final String reportId; // e.g. EVT-26-0005
  final int? eventReportId;
  final String status; // 'synced' or 'queued_offline'
  final String? alertId; // e.g. ALT-26-0001
  final String? verificationStatus; // e.g. PENDING
  final int attachments;
  final bool duplicate;
  final String message;

  EventReportResult({
    required this.reportId,
    this.eventReportId,
    required this.status,
    this.alertId,
    this.verificationStatus,
    this.attachments = 0,
    this.duplicate = false,
    required this.message,
  });

  factory EventReportResult.fromJson(Map<String, dynamic> json) =>
      EventReportResult(
        reportId: json['event_report_code'] ??
            json['report_id'] ??
            'EVT-26-0001',
        eventReportId: json['event_report_id'] is int
            ? json['event_report_id'] as int
            : int.tryParse(json['event_report_id']?.toString() ?? ''),
        status: json['status'] ?? 'synced',
        alertId: json['alert_code'] ?? json['alert_id'],
        verificationStatus:
            json['verification_status']?.toString() ?? 'PENDING',
        attachments:
            json['attachments'] is int ? json['attachments'] as int : 0,
        duplicate: json['duplicate'] == true,
        message: json['message'] ?? 'Event reported successfully.',
      );
}

// =============================================================================
// 📦 DYNAMIC EVENT FORM METADATA MODELS (GET /api/events/form-metadata)
// =============================================================================

class PrimarySector {
  final String sectorCode;
  final String sectorName;

  const PrimarySector({
    required this.sectorCode,
    required this.sectorName,
  });

  factory PrimarySector.fromJson(Map<String, dynamic> json) {
    return PrimarySector(
      sectorCode: json['sector_code']?.toString() ?? 'human',
      sectorName: json['sector_name']?.toString() ?? 'Human Health',
    );
  }

  Map<String, dynamic> toJson() => {
        'sector_code': sectorCode,
        'sector_name': sectorName,
      };
}

class EventTypeOption {
  final int id;
  final String name;
  final bool isOther;

  const EventTypeOption({
    required this.id,
    required this.name,
    this.isOther = false,
  });

  factory EventTypeOption.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final rawIsOther = json['is_other'] == true ||
        rawName.trim().toLowerCase() == 'other';
    return EventTypeOption(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: rawName,
      isOther: rawIsOther,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_other': isOther,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTypeOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class PopulationOption {
  final int id;
  final String name;
  final bool isOther;

  const PopulationOption({
    required this.id,
    required this.name,
    this.isOther = false,
  });

  factory PopulationOption.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final rawIsOther = json['is_other'] == true ||
        rawName.trim().toLowerCase() == 'other';
    return PopulationOption(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: rawName,
      isOther: rawIsOther,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_other': isOther,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PopulationOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class PopulationMetadata {
  final String label;
  final List<PopulationOption> options;

  const PopulationMetadata({
    required this.label,
    required this.options,
  });

  factory PopulationMetadata.fromJson(Map<String, dynamic> json) {
    final list = json['options'] as List? ?? [];
    return PopulationMetadata(
      label: json['label']?.toString() ?? 'Human Population',
      options: list
          .whereType<Map<String, dynamic>>()
          .map((e) => PopulationOption.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

class EventVillageOption {
  final int villageLgdCode;
  final String villageName;
  final String gramPanchayatName;
  final String blockName;

  const EventVillageOption({
    required this.villageLgdCode,
    required this.villageName,
    required this.gramPanchayatName,
    required this.blockName,
  });

  factory EventVillageOption.fromJson(Map<String, dynamic> json) {
    return EventVillageOption(
      villageLgdCode: json['village_lgd_code'] is int
          ? json['village_lgd_code'] as int
          : int.tryParse(json['village_lgd_code']?.toString() ?? '0') ?? 0,
      villageName: json['village_name']?.toString() ?? '',
      gramPanchayatName: json['gram_panchayat_name']?.toString() ?? '',
      blockName: json['block_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'village_lgd_code': villageLgdCode,
        'village_name': villageName,
        'gram_panchayat_name': gramPanchayatName,
        'block_name': blockName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventVillageOption &&
          runtimeType == other.runtimeType &&
          villageLgdCode == other.villageLgdCode;

  @override
  int get hashCode => villageLgdCode.hashCode;

  @override
  String toString() => '$villageName ($gramPanchayatName)';
}

class UploadLimitCategory {
  final int max;
  final int mb;
  final String label;

  const UploadLimitCategory({
    required this.max,
    required this.mb,
    required this.label,
  });

  factory UploadLimitCategory.fromJson(
    Map<String, dynamic> json, {
    String defaultLabel = '',
  }) {
    return UploadLimitCategory(
      max: json['max'] is int
          ? json['max'] as int
          : int.tryParse(json['max']?.toString() ?? '5') ?? 5,
      mb: json['mb'] is int
          ? json['mb'] as int
          : int.tryParse(json['mb']?.toString() ?? '5') ?? 5,
      label: json['label']?.toString() ?? defaultLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'max': max,
        'mb': mb,
        'label': label,
      };
}

class UploadLimitsMetadata {
  final UploadLimitCategory photos;
  final UploadLimitCategory videos;
  final UploadLimitCategory documents;

  const UploadLimitsMetadata({
    required this.photos,
    required this.videos,
    required this.documents,
  });

  factory UploadLimitsMetadata.fromJson(Map<String, dynamic> json) {
    return UploadLimitsMetadata(
      photos: UploadLimitCategory.fromJson(
        json['photos'] as Map<String, dynamic>? ?? {},
        defaultLabel: 'Photographs',
      ),
      videos: UploadLimitCategory.fromJson(
        json['videos'] as Map<String, dynamic>? ?? {},
        defaultLabel: 'Videos',
      ),
      documents: UploadLimitCategory.fromJson(
        json['documents'] as Map<String, dynamic>? ?? {},
        defaultLabel: 'Documents',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'photos': photos.toJson(),
        'videos': videos.toJson(),
        'documents': documents.toJson(),
      };

  static const defaultLimits = UploadLimitsMetadata(
    photos: UploadLimitCategory(max: 5, mb: 5, label: 'Photographs'),
    videos: UploadLimitCategory(max: 2, mb: 25, label: 'Videos'),
    documents: UploadLimitCategory(max: 4, mb: 10, label: 'Documents'),
  );
}

class EventFormMetadata {
  final PrimarySector primarySector;
  final List<EventTypeOption> eventTypes;
  final PopulationMetadata population;
  final List<String> locationTypes;
  final List<EventVillageOption> villages;
  final UploadLimitsMetadata uploadLimits;
  final String? minDate;
  final String? maxDate;

  const EventFormMetadata({
    required this.primarySector,
    required this.eventTypes,
    required this.population,
    required this.locationTypes,
    required this.villages,
    required this.uploadLimits,
    this.minDate,
    this.maxDate,
  });

  DateTime? get minDateTime {
    if (minDate == null || minDate!.trim().isEmpty) return null;
    return DateTime.tryParse(minDate!);
  }

  DateTime? get maxDateTime {
    if (maxDate == null || maxDate!.trim().isEmpty) return null;
    return DateTime.tryParse(maxDate!);
  }

  factory EventFormMetadata.fromJson(Map<String, dynamic> json) {
    return EventFormMetadata(
      primarySector: PrimarySector.fromJson(
        json['primary_sector'] as Map<String, dynamic>? ?? {},
      ),
      eventTypes: (json['event_types'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => EventTypeOption.fromJson(e))
          .toList(),
      population: PopulationMetadata.fromJson(
        json['population'] as Map<String, dynamic>? ?? {},
      ),
      locationTypes: (json['location_types'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      villages: (json['villages'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => EventVillageOption.fromJson(e))
          .toList(),
      uploadLimits: json['upload_limits'] != null
          ? UploadLimitsMetadata.fromJson(
              json['upload_limits'] as Map<String, dynamic>,
            )
          : UploadLimitsMetadata.defaultLimits,
      minDate: json['min_date']?.toString(),
      maxDate: json['max_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'primary_sector': primarySector.toJson(),
        'event_types': eventTypes.map((e) => e.toJson()).toList(),
        'population': population.toJson(),
        'location_types': locationTypes,
        'villages': villages.map((e) => e.toJson()).toList(),
        'upload_limits': uploadLimits.toJson(),
        'min_date': minDate,
        'max_date': maxDate,
      };

  /// Fallback metadata configured from official backend schema response
  factory EventFormMetadata.fallback() {
    return const EventFormMetadata(
      primarySector: PrimarySector(
        sectorCode: 'human',
        sectorName: 'Human Health',
      ),
      eventTypes: [
        EventTypeOption(id: 1, name: 'Suspected disease outbreaks'),
        EventTypeOption(id: 2, name: 'Human disease clusters'),
        EventTypeOption(id: 5, name: 'Food poisoning events'),
        EventTypeOption(id: 6, name: 'Chemical exposure'),
        EventTypeOption(id: 7, name: 'Animal-borne disease events'),
        EventTypeOption(id: 15, name: 'Household visits conducted'),
        EventTypeOption(id: 16, name: 'Fever cases identified'),
        EventTypeOption(id: 17, name: 'Diarrhoea cases identified'),
        EventTypeOption(id: 18, name: 'Acute respiratory illness identified'),
        EventTypeOption(id: 19, name: 'Skin disease cases identified'),
        EventTypeOption(id: 20, name: 'Suspected zoonotic disease cases'),
        EventTypeOption(id: 21, name: 'Animal-bite exposure cases'),
        EventTypeOption(id: 22, name: 'Suspected rabies exposure'),
        EventTypeOption(id: 23, name: 'Unusual disease clusters'),
        EventTypeOption(id: 24, name: 'Maternal health referrals'),
        EventTypeOption(id: 25, name: 'Child health referrals'),
        EventTypeOption(id: 26, name: 'Deaths reported'),
        EventTypeOption(id: 27, name: 'Unusual deaths'),
        EventTypeOption(id: 28, name: 'Public health alerts generated'),
        EventTypeOption(id: 29, name: 'Other significant health events'),
        EventTypeOption(id: 68, name: 'Other', isOther: true),
      ],
      population: PopulationMetadata(
        label: 'Human Population',
        options: [
          PopulationOption(id: 1, name: 'General population'),
          PopulationOption(id: 2, name: 'Children (under 5)'),
          PopulationOption(id: 3, name: 'School children'),
          PopulationOption(id: 4, name: 'Pregnant women'),
          PopulationOption(id: 5, name: 'Elderly'),
          PopulationOption(id: 6, name: 'Migrant / labour population'),
          PopulationOption(id: 7, name: 'Other', isOther: true),
        ],
      ),
      locationTypes: [
        'Urban',
        'Rural',
      ],
      villages: [
        EventVillageOption(
          villageLgdCode: 90000007,
          villageName: 'Achampet',
          gramPanchayatName: 'Achampet',
          blockName: 'Achampeta',
        ),
        EventVillageOption(
          villageLgdCode: 90000009,
          villageName: 'Balmoor',
          gramPanchayatName: 'Achampet',
          blockName: 'Achampeta',
        ),
        EventVillageOption(
          villageLgdCode: 90000008,
          villageName: 'Uppununthala',
          gramPanchayatName: 'Achampet',
          blockName: 'Achampeta',
        ),
        EventVillageOption(
          villageLgdCode: 90000004,
          villageName: 'Amrabad',
          gramPanchayatName: 'Amrabad',
          blockName: 'Amrabad',
        ),
        EventVillageOption(
          villageLgdCode: 90000005,
          villageName: 'Macharam',
          gramPanchayatName: 'Amrabad',
          blockName: 'Amrabad',
        ),
        EventVillageOption(
          villageLgdCode: 90000006,
          villageName: 'Sarlapally',
          gramPanchayatName: 'Amrabad',
          blockName: 'Amrabad',
        ),
        EventVillageOption(
          villageLgdCode: 90000001,
          villageName: 'Mannanur',
          gramPanchayatName: 'Mannanur',
          blockName: 'Amrabad',
        ),
        EventVillageOption(
          villageLgdCode: 90000003,
          villageName: 'Rampur',
          gramPanchayatName: 'Mannanur',
          blockName: 'Amrabad',
        ),
        EventVillageOption(
          villageLgdCode: 90000002,
          villageName: 'Vatvarlapally',
          gramPanchayatName: 'Mannanur',
          blockName: 'Amrabad',
        ),
      ],
      uploadLimits: UploadLimitsMetadata.defaultLimits,
      minDate: '2026-10-03',
      maxDate: '2026-10-17',
    );
  }
}
