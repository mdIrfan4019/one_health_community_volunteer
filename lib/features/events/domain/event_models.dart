// Domain models for Event Reporting & Dynamic Form Metadata
// File: lib/features/events/domain/event_models.dart

import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/models/geo_location_data.dart';

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
  final int? populationSubcategoryId;
  final String? populationSubcategory;
  final String? populationSubcategoryOther;
  final String observations;
  final String actionTaken;
  final String? description; // Media caption / description
  final bool isReferralGenerated;
  final bool isAlertGenerated;
  final bool isFollowUpRequired;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;
  final double? latitude;
  final double? longitude;
  final int? accuracy;
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
    this.populationSubcategoryId,
    this.populationSubcategory,
    this.populationSubcategoryOther,
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
    this.latitude,
    this.longitude,
    this.accuracy,
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
        if (populationSubcategoryId != null)
          'population_subcategory_id': populationSubcategoryId,
        if (populationSubcategory != null && populationSubcategory!.isNotEmpty)
          'population_subcategory': populationSubcategory,
        if (populationSubcategoryOther != null &&
            populationSubcategoryOther!.isNotEmpty)
          'population_subcategory_other': populationSubcategoryOther,
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
        if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
        if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
        if (accuracy != null) 'gps_accuracy_m': accuracy,
        if (accuracy != null) 'accuracy': accuracy,
        if (gpsUnavailableReason != null && gpsUnavailableReason!.isNotEmpty)
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

/// Model for submitted health event reports shown in the Event Reports list
class EventReportItem {
  final String id; // e.g. 'VISIT-26-0003' or 'VISIT-26-0009'
  final int? numericId; // e.g. 22
  final String eventType; // e.g. 'Animal-borne disease events'
  final String primarySector; // e.g. 'Animal Health' or 'Public Health'
  final String? sectorCode; // e.g. 'human', 'animal', 'environment', 'wildlife'
  final DateTime eventDate; // e.g. 23 Oct 2026 15:43
  final String village; // e.g. 'Amrabad' or 'Uppununthala'
  final String status; // 'synced' or 'pending'
  final bool isAlert;
  final bool isFollowUp;
  final String verificationStatus; // 'Submitted', 'SUBMITTED', 'PENDING', 'VERIFIED'
  final int totalVisits;
  final String? targetPopulation; // e.g. 'Livestock'
  final String? purposeOfVisit; // e.g. 'testing'
  final String? locationType; // e.g. 'Urban'
  final String? description; // e.g. 'testing'
  final String? observations; // e.g. 'testing'
  final String? actionTaken; // e.g. 'testing'
  final bool referralGenerated;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? volunteerId;
  final int? numericVolunteerId;
  final String? volunteerName;
  final List<AppAttachmentItem> attachments;
  final List<String> mediaFiles;

  const EventReportItem({
    required this.id,
    this.numericId,
    required this.eventType,
    required this.primarySector,
    this.sectorCode,
    required this.eventDate,
    required this.village,
    this.status = 'synced',
    this.isAlert = false,
    this.isFollowUp = false,
    this.verificationStatus = 'Submitted',
    this.totalVisits = 1,
    this.targetPopulation,
    this.purposeOfVisit,
    this.locationType,
    this.description,
    this.observations,
    this.actionTaken,
    this.referralGenerated = false,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.volunteerId,
    this.numericVolunteerId,
    this.volunteerName,
    this.attachments = const [],
    this.mediaFiles = const [],
  });

  EventReportItem copyWith({
    String? id,
    int? numericId,
    String? eventType,
    String? primarySector,
    String? sectorCode,
    DateTime? eventDate,
    String? village,
    String? status,
    bool? isAlert,
    bool? isFollowUp,
    String? verificationStatus,
    int? totalVisits,
    String? targetPopulation,
    String? purposeOfVisit,
    String? locationType,
    String? description,
    String? observations,
    String? actionTaken,
    bool? referralGenerated,
    double? latitude,
    double? longitude,
    int? gpsAccuracyM,
    String? volunteerId,
    int? numericVolunteerId,
    String? volunteerName,
    List<AppAttachmentItem>? attachments,
    List<String>? mediaFiles,
  }) {
    return EventReportItem(
      id: id ?? this.id,
      numericId: numericId ?? this.numericId,
      eventType: eventType ?? this.eventType,
      primarySector: primarySector ?? this.primarySector,
      sectorCode: sectorCode ?? this.sectorCode,
      eventDate: eventDate ?? this.eventDate,
      village: village ?? this.village,
      status: status ?? this.status,
      isAlert: isAlert ?? this.isAlert,
      isFollowUp: isFollowUp ?? this.isFollowUp,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      totalVisits: totalVisits ?? this.totalVisits,
      targetPopulation: targetPopulation ?? this.targetPopulation,
      purposeOfVisit: purposeOfVisit ?? this.purposeOfVisit,
      locationType: locationType ?? this.locationType,
      description: description ?? this.description,
      observations: observations ?? this.observations,
      actionTaken: actionTaken ?? this.actionTaken,
      referralGenerated: referralGenerated ?? this.referralGenerated,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracyM: gpsAccuracyM ?? this.gpsAccuracyM,
      volunteerId: volunteerId ?? this.volunteerId,
      numericVolunteerId: numericVolunteerId ?? this.numericVolunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      attachments: attachments ?? this.attachments,
      mediaFiles: mediaFiles ?? this.mediaFiles,
    );
  }

  /// Normalizes backend sector codes and names into user-facing sector labels.
  /// Maps 'human' or 'public' to 'Public Health', avoiding incorrect fallbacks to 'Animal Health'.
  static String normalizeSector({
    String? rawSector,
    String? sectorCode,
    String? eventTypeName,
    String? populationTypeName,
    String? fallbackSector,
  }) {
    // 1. If explicit sectorCode is provided
    final code = (sectorCode ?? '').trim().toLowerCase();
    if (code.isNotEmpty) {
      if (code == 'human' ||
          code == 'public' ||
          code.contains('human') ||
          code.contains('public')) {
        return 'Public Health';
      }
      if (code == 'animal' ||
          code.contains('anim') ||
          code.contains('vet')) {
        return 'Animal Health';
      }
      if (code == 'wildlife' || code.contains('wild')) {
        return 'Wildlife';
      }
      if (code == 'environment' || code.contains('env')) {
        return 'Environment';
      }
      if (code == 'urban') {
        return 'Urban';
      }
      if (code == 'rural') {
        return 'Rural';
      }
    }

    // 2. If rawSector string is provided
    final sector = (rawSector ?? '').trim();
    if (sector.isNotEmpty) {
      final sLower = sector.toLowerCase();
      if (sLower == 'human health') {
        return 'Human Health';
      }
      if (sLower.contains('public health') ||
          sLower == 'public' ||
          sLower.contains('human')) {
        return 'Public Health';
      }
      if (sLower.contains('animal') || sLower.contains('veterinary')) {
        return 'Animal Health';
      }
      if (sLower.contains('wildlife') || sLower.contains('forest')) {
        return 'Wildlife';
      }
      if (sLower.contains('environment') || sLower.contains('ulb')) {
        return 'Environment';
      }
      if (sLower.contains('urban')) {
        return 'Urban';
      }
      if (sLower.contains('rural')) {
        return 'Rural';
      }
      return sector;
    }

    // 3. Fallback to active volunteer's session sector if available
    final fb = (fallbackSector ?? '').trim();
    if (fb.isNotEmpty) {
      final fbLower = fb.toLowerCase();
      if (fbLower.contains('public') || fbLower.contains('human')) {
        return 'Public Health';
      }
      if (fbLower.contains('animal') || fbLower.contains('vet')) {
        return 'Animal Health';
      }
      if (fbLower.contains('wildlife')) {
        return 'Wildlife';
      }
      if (fbLower.contains('environment')) {
        return 'Environment';
      }
      if (fbLower.contains('urban')) {
        return 'Urban';
      }
      if (fbLower.contains('rural')) {
        return 'Rural';
      }
    }

    // 4. Infer from event type name
    final evLower = (eventTypeName ?? '').trim().toLowerCase();
    if (evLower.isNotEmpty) {
      if (evLower.contains('human') ||
          evLower.contains('outbreak') ||
          evLower.contains('food poisoning') ||
          evLower.contains('fever') ||
          evLower.contains('diarrhoea') ||
          evLower.contains('respiratory') ||
          evLower.contains('maternal') ||
          evLower.contains('child health') ||
          evLower.contains('household') ||
          evLower.contains('skin disease')) {
        return 'Public Health';
      }
      if (evLower.contains('livestock') ||
          evLower.contains('poultry') ||
          evLower.contains('cattle') ||
          evLower.contains('anthrax') ||
          evLower.contains('brucellosis') ||
          evLower.contains('rabid') ||
          evLower.contains('animal-borne')) {
        return 'Animal Health';
      }
      if (evLower.contains('wild') ||
          evLower.contains('carnivore') ||
          evLower.contains('primate')) {
        return 'Wildlife';
      }
      if (evLower.contains('water') ||
          evLower.contains('chemical') ||
          evLower.contains('sewage') ||
          evLower.contains('waste') ||
          evLower.contains('pesticide')) {
        return 'Environment';
      }
    }

    // 5. Infer from population type name
    final popLower = (populationTypeName ?? '').trim().toLowerCase();
    if (popLower.isNotEmpty) {
      if (popLower.contains('human') ||
          popLower.contains('general') ||
          popLower.contains('children') ||
          popLower.contains('pregnant') ||
          popLower.contains('elderly') ||
          popLower.contains('migrant')) {
        return 'Public Health';
      }
      if (popLower.contains('livestock') ||
          popLower.contains('cattle') ||
          popLower.contains('sheep') ||
          popLower.contains('swine') ||
          popLower.contains('poultry') ||
          popLower.contains('dog')) {
        return 'Animal Health';
      }
      if (popLower.contains('wild') ||
          popLower.contains('primate') ||
          popLower.contains('carnivore')) {
        return 'Wildlife';
      }
    }

    // 6. Safe default fallback: 'Public Health'
    return 'Public Health';
  }

  /// Maps a sector name to its backend sector code string ('human', 'animal', etc.).
  static String sectorToCode(String? sector) {
    final lower = (sector ?? '').trim().toLowerCase();
    if (lower.contains('public') || lower.contains('human')) return 'human';
    if (lower.contains('animal') || lower.contains('veterinary')) return 'animal';
    if (lower.contains('wildlife') || lower.contains('forest')) return 'wildlife';
    if (lower.contains('environment') || lower.contains('ulb')) return 'environment';
    if (lower.contains('urban')) return 'urban';
    if (lower.contains('rural')) return 'rural';
    return 'human';
  }

  factory EventReportItem.fromJson(
    Map<String, dynamic> json, {
    String? fallbackSector,
  }) {
    // 1. Identification
    final rawId = json['event_report_code']?.toString() ??
        json['id']?.toString() ??
        '';
    final rawNumericId = json['event_report_id'] is int
        ? json['event_report_id'] as int
        : int.tryParse(json['event_report_id']?.toString() ?? '');

    // 2. Titles & Category
    final rawEventType = json['event_type_name']?.toString() ??
        json['event_type']?.toString() ??
        'Health Event';
    final rawSectorCode = json['sector_code']?.toString() ??
        json['primary_sector_code']?.toString();
    final rawPop = json['population_type_name']?.toString() ??
        json['target_population']?.toString() ??
        json['population_name']?.toString();

    final rawSector = normalizeSector(
      rawSector: json['primary_sector']?.toString() ??
          json['sector_name']?.toString() ??
          json['sector']?.toString() ??
          json['cohv_type']?.toString() ??
          json['department_name']?.toString() ??
          json['department']?.toString(),
      sectorCode: rawSectorCode,
      eventTypeName: rawEventType,
      populationTypeName: rawPop,
      fallbackSector: fallbackSector,
    );
    final rawVillage = json['village_name']?.toString() ??
        json['village']?.toString() ??
        '—';

    // 3. Date & Time
    DateTime parsedDate;
    if (json['created_at'] != null) {
      parsedDate =
          DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
          DateTime.now();
    } else if (json['event_date'] != null) {
      final dateStr = json['event_date'].toString();
      final timeStr = json['event_time']?.toString() ?? '00:00:00';
      parsedDate =
          DateTime.tryParse('${dateStr}T$timeStr') ??
          DateTime.tryParse(dateStr) ??
          DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // 4. Status
    final rawVerification =
        json['verification_status']?.toString() ?? 'Submitted';
    final rawStatus = json['status']?.toString() ?? 'synced';

    // 5. Details
    final rawPurpose = json['purpose_of_visit']?.toString();
    final rawLocType = json['location_type']?.toString();
    final rawTotalVisits = json['total_visits'] is int
        ? json['total_visits'] as int
        : int.tryParse(json['total_visits']?.toString() ?? '1') ?? 1;
    final rawDesc = json['description']?.toString();
    final rawObs = json['observations']?.toString();
    final rawAction = json['action_taken']?.toString();
    final rawReferral = json['referral_generated'] == true ||
        json['referral_generated']?.toString().toLowerCase() == 'true';
    final rawAlert = json['alert_generated'] == true ||
        json['is_alert'] == true ||
        json['alert_generated']?.toString().toLowerCase() == 'true';
    final rawFollowUp = json['follow_up_required'] == true ||
        json['is_follow_up'] == true ||
        json['follow_up_required']?.toString().toLowerCase() == 'true';
    final rawLat = json['latitude'] != null
        ? double.tryParse(json['latitude'].toString())
        : null;
    final rawLng = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString())
        : null;
    final rawAccuracy = json['gps_accuracy_m'] != null
        ? int.tryParse(json['gps_accuracy_m'].toString())
        : null;

    // 6. Volunteer Ownership
    final rawVolunteerId = json['volunteer_code']?.toString() ??
        json['volunteer_id']?.toString();
    final rawNumericVolunteerId = json['volunteer_id'] is int
        ? json['volunteer_id'] as int
        : (json['numeric_volunteer_id'] is int
            ? json['numeric_volunteer_id'] as int
            : int.tryParse(json['volunteer_id']?.toString() ?? ''));
    final rawVolunteerName = json['volunteer_name']?.toString();

    // 7. Attachments & Media Files
    final List<AppAttachmentItem> attachmentsList = [];
    final List<String> media = [];

    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        if (a is Map) {
          final item = AppAttachmentItem.fromJson(Map<String, dynamic>.from(a));
          attachmentsList.add(item);
          if (item.storagePath.isNotEmpty) {
            media.add(item.storagePath);
          } else if (item.fileUrl != null && item.fileUrl!.isNotEmpty) {
            media.add(item.fileUrl!);
          }
        }
      }
    } else if (json['media_files'] is List) {
      media.addAll(List<String>.from(json['media_files']));
      for (final path in media) {
        attachmentsList.add(
          AppAttachmentItem.fromPath(
            path,
            latitude: rawLat,
            longitude: rawLng,
            accuracy: rawAccuracy,
            capturedAt: parsedDate,
          ),
        );
      }
    } else {
      if (json['photos'] is List) {
        for (final p in json['photos']) {
          if (p != null) {
            media.add(p.toString());
            attachmentsList.add(
              AppAttachmentItem.fromPath(
                p.toString(),
                fileKind: 'IMAGE',
                latitude: rawLat,
                longitude: rawLng,
                accuracy: rawAccuracy,
                capturedAt: parsedDate,
              ),
            );
          }
        }
      }
      if (json['videos'] is List) {
        for (final v in json['videos']) {
          if (v != null) {
            media.add(v.toString());
            attachmentsList.add(
              AppAttachmentItem.fromPath(
                v.toString(),
                fileKind: 'VIDEO',
                latitude: rawLat,
                longitude: rawLng,
                accuracy: rawAccuracy,
                capturedAt: parsedDate,
              ),
            );
          }
        }
      }
      if (json['documents'] is List) {
        for (final d in json['documents']) {
          if (d != null) {
            media.add(d.toString());
            attachmentsList.add(
              AppAttachmentItem.fromPath(
                d.toString(),
                fileKind: 'DOCUMENT',
                latitude: rawLat,
                longitude: rawLng,
                accuracy: rawAccuracy,
                capturedAt: parsedDate,
              ),
            );
          }
        }
      }
    }

    return EventReportItem(
      id: rawId,
      numericId: rawNumericId,
      eventType: rawEventType,
      primarySector: rawSector,
      sectorCode: rawSectorCode ?? sectorToCode(rawSector),
      eventDate: parsedDate,
      village: rawVillage,
      status: rawStatus,
      isAlert: rawAlert,
      isFollowUp: rawFollowUp,
      verificationStatus: rawVerification,
      totalVisits: rawTotalVisits,
      targetPopulation: rawPop,
      purposeOfVisit: rawPurpose,
      locationType: rawLocType,
      description: rawDesc,
      observations: rawObs,
      actionTaken: rawAction,
      referralGenerated: rawReferral,
      latitude: rawLat,
      longitude: rawLng,
      gpsAccuracyM: rawAccuracy,
      volunteerId: rawVolunteerId,
      numericVolunteerId: rawNumericVolunteerId,
      volunteerName: rawVolunteerName,
      attachments: attachmentsList,
      mediaFiles: media,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (numericId != null) 'event_report_id': numericId,
    'event_report_code': id,
    'event_type': eventType,
    'event_type_name': eventType,
    'primary_sector': primarySector,
    'sector_name': primarySector,
    'sector_code': sectorCode ?? sectorToCode(primarySector),
    'primary_sector_code': sectorCode ?? sectorToCode(primarySector),
    'event_date': eventDate.toIso8601String(),
    'created_at': eventDate.toIso8601String(),
    'village': village,
    'village_name': village,
    'status': status,
    'is_alert': isAlert,
    'is_follow_up': isFollowUp,
    'verification_status': verificationStatus,
    'total_visits': totalVisits,
    if (targetPopulation != null) 'target_population': targetPopulation,
    if (targetPopulation != null) 'population_type_name': targetPopulation,
    if (purposeOfVisit != null) 'purpose_of_visit': purposeOfVisit,
    if (locationType != null) 'location_type': locationType,
    if (description != null) 'description': description,
    if (observations != null) 'observations': observations,
    if (actionTaken != null) 'action_taken': actionTaken,
    'referral_generated': referralGenerated,
    if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
    if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
    if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
    if (volunteerId != null) 'volunteer_id': volunteerId,
    if (numericVolunteerId != null) 'numeric_volunteer_id': numericVolunteerId,
    if (volunteerName != null) 'volunteer_name': volunteerName,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'media_files': mediaFiles,
  };
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
      sectorName: json['sector_name']?.toString() ?? 'Public Health',
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

class PopulationSubcategoryOption {
  final int id;
  final String name;
  final bool isOther;

  const PopulationSubcategoryOption({
    required this.id,
    required this.name,
    this.isOther = false,
  });

  factory PopulationSubcategoryOption.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final rawIsOther = json['is_other'] == true ||
        rawName.trim().toLowerCase() == 'other';
    return PopulationSubcategoryOption(
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
      other is PopulationSubcategoryOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class PopulationSubcategoriesResponse {
  final bool success;
  final String message;
  final int? populationTypeId;
  final List<PopulationSubcategoryOption> data;

  const PopulationSubcategoriesResponse({
    required this.success,
    required this.message,
    this.populationTypeId,
    required this.data,
  });

  factory PopulationSubcategoriesResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] is List ? json['data'] as List : const [];
    return PopulationSubcategoriesResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      populationTypeId: json['population_type_id'] is int
          ? json['population_type_id'] as int
          : int.tryParse(json['population_type_id']?.toString() ?? ''),
      data: rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => PopulationSubcategoryOption.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (populationTypeId != null) 'population_type_id': populationTypeId,
        'data': data.map((e) => e.toJson()).toList(),
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

  /// Fallback metadata configured per volunteer sector (Human, Animal, Environment, Wildlife)
  factory EventFormMetadata.fallback({String? sector}) {
    final lower = (sector ?? '').trim().toLowerCase();

    final isAnimal = lower.contains('animal') || lower.contains('veterinary');
    final isEnvironment = lower.contains('environment') || lower.contains('ulb');
    final isWildlife = lower.contains('wildlife') || lower.contains('forest');

    final PrimarySector primarySector;
    final List<EventTypeOption> eventTypes;
    final PopulationMetadata population;

    final now = DateTime.now();
    final minDt = now.subtract(const Duration(days: 14));
    final minDateStr =
        '${minDt.year}-${minDt.month.toString().padLeft(2, '0')}-${minDt.day.toString().padLeft(2, '0')}';
    final maxDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (isAnimal) {
      primarySector = const PrimarySector(
        sectorCode: 'animal',
        sectorName: 'Animal Husbandry / Veterinary',
      );
      eventTypes = const [
        EventTypeOption(id: 3, name: 'Unusual livestock morbidity / sickness'),
        EventTypeOption(id: 4, name: 'Unusual animal mortality / death cluster'),
        EventTypeOption(id: 7, name: 'Animal-borne disease events'),
        EventTypeOption(id: 8, name: 'Suspected anthrax in animals'),
        EventTypeOption(id: 9, name: 'Suspected avian influenza / bird flu'),
        EventTypeOption(id: 10, name: 'Suspected foot and mouth disease (FMD)'),
        EventTypeOption(id: 11, name: 'Suspected brucellosis in cattle'),
        EventTypeOption(id: 12, name: 'Rabid animal observation / aggression'),
        EventTypeOption(id: 13, name: 'Mass poultry / duck mortality'),
        EventTypeOption(id: 14, name: 'Heavy tick / vector infestation on livestock'),
        EventTypeOption(id: 20, name: 'Suspected zoonotic disease cases'),
        EventTypeOption(id: 21, name: 'Animal-bite exposure cases'),
        EventTypeOption(id: 22, name: 'Suspected rabies exposure'),
        EventTypeOption(id: 68, name: 'Other', isOther: true),
      ];
      population = const PopulationMetadata(
        label: 'Animal Population / Livestock',
        options: [
          PopulationOption(id: 1, name: 'Cattle & Buffalo'),
          PopulationOption(id: 2, name: 'Sheep & Goat'),
          PopulationOption(id: 3, name: 'Pigs / Swine'),
          PopulationOption(id: 4, name: 'Poultry / Backyard birds'),
          PopulationOption(id: 5, name: 'Dogs & Cats (Domestic)'),
          PopulationOption(id: 6, name: 'Equine (Horses / Donkeys)'),
          PopulationOption(id: 7, name: 'Other', isOther: true),
        ],
      );
    } else if (isEnvironment) {
      primarySector = const PrimarySector(
        sectorCode: 'environment',
        sectorName: 'Environmental Health',
      );
      eventTypes = const [
        EventTypeOption(id: 30, name: 'Contaminated community drinking water source'),
        EventTypeOption(id: 31, name: 'Mass fish mortality in natural water body'),
        EventTypeOption(id: 32, name: 'Chemical spill / industrial effluent discharge'),
        EventTypeOption(id: 33, name: 'Severe sewage overflow near residential area'),
        EventTypeOption(id: 34, name: 'Stagnant water vector breeding hotspot'),
        EventTypeOption(id: 35, name: 'Unregulated medical or hazardous waste dumping'),
        EventTypeOption(id: 36, name: 'Acute crop pesticide toxicity cluster'),
        EventTypeOption(id: 6, name: 'Chemical exposure'),
        EventTypeOption(id: 68, name: 'Other', isOther: true),
      ];
      population = const PopulationMetadata(
        label: 'Environmental Target Area',
        options: [
          PopulationOption(id: 1, name: 'Community drinking water source'),
          PopulationOption(id: 2, name: 'Natural water body (River / Pond / Lake)'),
          PopulationOption(id: 3, name: 'Solid waste dumpsite'),
          PopulationOption(id: 4, name: 'Residential / Slum sanitation cluster'),
          PopulationOption(id: 5, name: 'Agricultural field / Drainage canal'),
          PopulationOption(id: 6, name: 'Marketplace / Public area'),
          PopulationOption(id: 7, name: 'Other', isOther: true),
        ],
      );
    } else if (isWildlife) {
      primarySector = const PrimarySector(
        sectorCode: 'wildlife',
        sectorName: 'Wildlife Health',
      );
      eventTypes = const [
        EventTypeOption(id: 40, name: 'Unusual wild animal death cluster'),
        EventTypeOption(id: 41, name: 'Mass wild bird / water bird mortality'),
        EventTypeOption(id: 42, name: 'Wild carnivore carcass found'),
        EventTypeOption(id: 43, name: 'Suspected primate disease or sudden deaths'),
        EventTypeOption(id: 44, name: 'Wildlife-livestock interaction hotspot'),
        EventTypeOption(id: 20, name: 'Suspected zoonotic disease cases'),
        EventTypeOption(id: 68, name: 'Other', isOther: true),
      ];
      population = const PopulationMetadata(
        label: 'Wildlife Target Population',
        options: [
          PopulationOption(id: 1, name: 'Wild herbivores (Deer / Nilgai / Boar)'),
          PopulationOption(id: 2, name: 'Primates (Monkeys / Langurs)'),
          PopulationOption(id: 3, name: 'Wild birds / Migratory birds'),
          PopulationOption(id: 4, name: 'Carnivores (Leopards / Hyenas / Foxes)'),
          PopulationOption(id: 5, name: 'Bats / Cave fauna'),
          PopulationOption(id: 6, name: 'Reptiles & Amphibians'),
          PopulationOption(id: 7, name: 'Other', isOther: true),
        ],
      );
    } else {
      // Default: Human Health / Public Health
      primarySector = const PrimarySector(
        sectorCode: 'human',
        sectorName: 'Public Health',
      );
      eventTypes = const [
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
      ];
      population = const PopulationMetadata(
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
      );
    }

    return EventFormMetadata(
      primarySector: primarySector,
      eventTypes: eventTypes,
      population: population,
      locationTypes: const [
        'Urban',
        'Rural',
      ],
      villages: const [
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
      minDate: minDateStr,
      maxDate: maxDateStr,
    );
  }
}
