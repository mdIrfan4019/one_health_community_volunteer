// Create file: lib/features/referrals/domain/referral_models.dart

import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/models/geo_location_data.dart';

class ReferralAttachmentItem {
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

  const ReferralAttachmentItem({
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

  factory ReferralAttachmentItem.fromJson(Map<String, dynamic> json) {
    final rawFileName = (json['file_name'] ?? json['filename'] ?? json['name'] ?? '').toString();
    final rawStorage = (json['storage_path'] ?? json['file_path'] ?? json['path'] ?? '').toString();
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
        : (json['lat'] != null ? double.tryParse(json['lat'].toString()) : null);
    final lng = json['longitude'] != null
        ? double.tryParse(json['longitude'].toString())
        : (json['lng'] != null ? double.tryParse(json['lng'].toString()) : null);
    final acc = json['gps_accuracy_m'] != null
        ? int.tryParse(json['gps_accuracy_m'].toString())
        : (json['accuracy'] != null ? int.tryParse(json['accuracy'].toString()) : null);
    final rawDt = json['captured_at'] ?? json['created_at'] ?? json['timestamp'] ?? json['date'];

    return ReferralAttachmentItem(
      attachmentId: json['attachment_id'] is int
          ? json['attachment_id'] as int
          : (json['id'] is int
              ? json['id'] as int
              : int.tryParse(json['attachment_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0),
      fileKind: json['file_kind']?.toString() ?? 'DOCUMENT',
      fileName: name,
      storagePath: rawStorage,
      mimeType: json['mime_type']?.toString() ?? json['content_type']?.toString(),
      sizeBytes: json['size_bytes'] is int
          ? json['size_bytes'] as int
          : int.tryParse(json['size_bytes']?.toString() ?? json['size']?.toString() ?? '0') ?? 0,
      caption: json['caption']?.toString() ?? json['description']?.toString(),
      fileUrl: rawUrl,
      latitude: lat,
      longitude: lng,
      gpsAccuracyM: acc,
      capturedAt: rawDt != null ? DateTime.tryParse(rawDt.toString())?.toLocal() : null,
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
        if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
        if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
        if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
        if (capturedAt != null) 'captured_at': capturedAt!.toUtc().toIso8601String(),
      };
}

class ReferralItem {
  final int? referralId;
  final String id; // e.g. REF-26-0005
  final String facilityName; // e.g. CHC or Sub-Centre / HWC
  final String stream; // Human, Animal
  final String referralType;
  final String village;
  final DateTime eventDate;
  final DateTime referralDate;
  final String? reason;
  final bool isFollowedUp;
  final String status; // 'synced' or 'pending'
  final List<String> mediaFiles;
  final List<ReferralAttachmentItem> attachments;
  final String? mediaCaption;
  final double? latitude;
  final double? longitude;
  final int? accuracy;
  final String volunteerId;
  final int? numericVolunteerId;
  final String? volunteerName;
  final String? volunteerCode;
  final String deviceId;
  final String? clientRef;
  final int? referralFacilityId;
  final bool? facilityIsOther;
  final int? eventReportId;
  final int? villageLgdCode;
  final String? gramPanchayatName;
  final String? blockName;
  final String? districtName;
  final String? stateName;
  final int? stateLgdCode;
  final int? districtLgdCode;
  final int? blockLgdCode;
  final DateTime? followedUpAt;
  final String? gpsUnavailableReason;
  final DateTime? capturedAt;
  final String? verificationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<AppAttachmentItem> get appAttachments {
    if (attachments.isNotEmpty) {
      return attachments
          .map((a) => a.toAppAttachment(
                fallbackLat: latitude,
                fallbackLng: longitude,
                fallbackAcc: accuracy,
                fallbackDt: capturedAt ?? referralDate,
              ))
          .toList();
    }
    return mediaFiles
        .map((p) => AppAttachmentItem.fromPath(
              p,
              latitude: latitude,
              longitude: longitude,
              accuracy: accuracy,
              capturedAt: capturedAt ?? referralDate,
            ))
        .toList();
  }

  ReferralItem({
    this.referralId,
    required this.id,
    required this.facilityName,
    required this.stream,
    required this.referralType,
    required this.village,
    required this.eventDate,
    required this.referralDate,
    this.reason,
    required this.isFollowedUp,
    this.status = 'synced',
    this.mediaFiles = const [],
    this.attachments = const [],
    this.mediaCaption,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.volunteerId,
    this.numericVolunteerId,
    this.volunteerName,
    this.volunteerCode,
    required this.deviceId,
    this.clientRef,
    this.referralFacilityId,
    this.facilityIsOther,
    this.eventReportId,
    this.villageLgdCode,
    this.gramPanchayatName,
    this.blockName,
    this.districtName,
    this.stateName,
    this.stateLgdCode,
    this.districtLgdCode,
    this.blockLgdCode,
    this.followedUpAt,
    this.gpsUnavailableReason,
    this.capturedAt,
    this.verificationStatus,
    this.createdAt,
    this.updatedAt,
  });

  ReferralItem copyWith({
    int? referralId,
    String? id,
    String? facilityName,
    String? stream,
    String? referralType,
    String? village,
    DateTime? eventDate,
    DateTime? referralDate,
    String? reason,
    bool? isFollowedUp,
    String? status,
    List<String>? mediaFiles,
    List<ReferralAttachmentItem>? attachments,
    String? mediaCaption,
    double? latitude,
    double? longitude,
    int? accuracy,
    String? volunteerId,
    int? numericVolunteerId,
    String? volunteerName,
    String? volunteerCode,
    String? deviceId,
    String? clientRef,
    int? referralFacilityId,
    bool? facilityIsOther,
    int? eventReportId,
    int? villageLgdCode,
    String? gramPanchayatName,
    String? blockName,
    String? districtName,
    String? stateName,
    int? stateLgdCode,
    int? districtLgdCode,
    int? blockLgdCode,
    DateTime? followedUpAt,
    String? gpsUnavailableReason,
    DateTime? capturedAt,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReferralItem(
      referralId: referralId ?? this.referralId,
      id: id ?? this.id,
      facilityName: facilityName ?? this.facilityName,
      stream: stream ?? this.stream,
      referralType: referralType ?? this.referralType,
      village: village ?? this.village,
      eventDate: eventDate ?? this.eventDate,
      referralDate: referralDate ?? this.referralDate,
      reason: reason ?? this.reason,
      isFollowedUp: isFollowedUp ?? this.isFollowedUp,
      status: status ?? this.status,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      attachments: attachments ?? this.attachments,
      mediaCaption: mediaCaption ?? this.mediaCaption,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      volunteerId: volunteerId ?? this.volunteerId,
      numericVolunteerId: numericVolunteerId ?? this.numericVolunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      volunteerCode: volunteerCode ?? this.volunteerCode,
      deviceId: deviceId ?? this.deviceId,
      clientRef: clientRef ?? this.clientRef,
      referralFacilityId: referralFacilityId ?? this.referralFacilityId,
      facilityIsOther: facilityIsOther ?? this.facilityIsOther,
      eventReportId: eventReportId ?? this.eventReportId,
      villageLgdCode: villageLgdCode ?? this.villageLgdCode,
      gramPanchayatName: gramPanchayatName ?? this.gramPanchayatName,
      blockName: blockName ?? this.blockName,
      districtName: districtName ?? this.districtName,
      stateName: stateName ?? this.stateName,
      stateLgdCode: stateLgdCode ?? this.stateLgdCode,
      districtLgdCode: districtLgdCode ?? this.districtLgdCode,
      blockLgdCode: blockLgdCode ?? this.blockLgdCode,
      followedUpAt: followedUpAt ?? this.followedUpAt,
      gpsUnavailableReason: gpsUnavailableReason ?? this.gpsUnavailableReason,
      capturedAt: capturedAt ?? this.capturedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        if (referralId != null) 'referral_id': referralId,
        'id': id,
        'referral_code': id,
        'facility_name': facilityName,
        'referral_facility_name': facilityName,
        'stream': stream,
        'referral_stream': stream,
        'referral_type': referralType,
        'village': village,
        'village_name': village,
        'event_date': eventDate.toIso8601String(),
        'referral_date': referralDate.toIso8601String(),
        'reason': reason,
        'is_followed_up': isFollowedUp,
        'status': status,
        'media_files': mediaFiles,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'media_caption': mediaCaption,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'gps_accuracy_m': accuracy,
        'volunteer_id': volunteerId,
        if (numericVolunteerId != null)
          'numeric_volunteer_id': numericVolunteerId,
        if (volunteerName != null) 'volunteer_name': volunteerName,
        if (volunteerCode != null) 'volunteer_code': volunteerCode,
        'device_id': deviceId,
        if (clientRef != null) 'client_ref': clientRef,
        if (referralFacilityId != null)
          'referral_facility_id': referralFacilityId,
        if (facilityIsOther != null) 'facility_is_other': facilityIsOther,
        if (eventReportId != null) 'event_report_id': eventReportId,
        if (villageLgdCode != null) 'village_lgd_code': villageLgdCode,
        if (gramPanchayatName != null)
          'gram_panchayat_name': gramPanchayatName,
        if (blockName != null) 'block_name': blockName,
        if (districtName != null) 'district_name': districtName,
        if (stateName != null) 'state_name': stateName,
        if (stateLgdCode != null) 'state_lgd_code': stateLgdCode,
        if (districtLgdCode != null) 'district_lgd_code': districtLgdCode,
        if (blockLgdCode != null) 'block_lgd_code': blockLgdCode,
        if (followedUpAt != null)
          'followed_up_at': followedUpAt!.toIso8601String(),
        if (gpsUnavailableReason != null)
          'gps_unavailable_reason': gpsUnavailableReason,
        if (capturedAt != null) 'captured_at': capturedAt!.toIso8601String(),
        if (verificationStatus != null)
          'verification_status': verificationStatus,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  static String normalizeReferralStream(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Human';
    final lower = raw.trim().toLowerCase();
    if (lower.contains('anim')) return 'Animal';
    if (lower.contains('env')) return 'Environment';
    if (lower.contains('forest') || lower.contains('wild')) return 'Forest';
    return 'Human';
  }

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    List<String> media = [];
    List<ReferralAttachmentItem> attachmentList = [];

    void addPath(String p, String kind) {
      if (p.trim().isEmpty) return;
      if (!media.contains(p)) media.add(p);
      if (!attachmentList.any((a) => a.storagePath == p || a.fileUrl == p)) {
        attachmentList.add(ReferralAttachmentItem(
          attachmentId: 0,
          fileUrl: p,
          storagePath: p,
          fileKind: kind,
          fileName: p.split(RegExp(r'[/\\]')).last.split('?').first,
        ));
      }
    }

    if (json['attachments'] is List) {
      for (final a in json['attachments']) {
        if (a is Map) {
          final item = ReferralAttachmentItem.fromJson(
            Map<String, dynamic>.from(a),
          );
          attachmentList.add(item);
          final path = item.storagePath.isNotEmpty ? item.storagePath : (item.fileUrl ?? '');
          if (path.isNotEmpty && !media.contains(path)) {
            media.add(path);
          }
        }
      }
    }
    if (json['media_files'] is List) {
      for (final m in json['media_files']) {
        if (m != null) addPath(m.toString(), 'FILE');
      }
    }
    if (json['photos'] is List) {
      for (final p in json['photos']) {
        if (p != null) addPath(p is Map ? (p['file_url'] ?? p['storage_path'] ?? p['path'] ?? '').toString() : p.toString(), 'PHOTO');
      }
    }
    if (json['videos'] is List) {
      for (final v in json['videos']) {
        if (v != null) addPath(v is Map ? (v['file_url'] ?? v['storage_path'] ?? v['path'] ?? '').toString() : v.toString(), 'VIDEO');
      }
    }
    if (json['documents'] is List) {
      for (final d in json['documents']) {
        if (d != null) addPath(d is Map ? (d['file_url'] ?? d['storage_path'] ?? d['path'] ?? '').toString() : d.toString(), 'DOCUMENT');
      }
    }

    final refId = json['referral_id'] is int
        ? json['referral_id'] as int
        : int.tryParse(json['referral_id']?.toString() ?? '');

    final rawStatus = json['verification_status']?.toString() ??
        json['status']?.toString() ??
        'synced';

    final lat = json['latitude'] is num
        ? (json['latitude'] as num).toDouble()
        : double.tryParse(json['latitude']?.toString() ?? '');
    final lng = json['longitude'] is num
        ? (json['longitude'] as num).toDouble()
        : double.tryParse(json['longitude']?.toString() ?? '');
    final acc = json['gps_accuracy_m'] is int
        ? json['gps_accuracy_m'] as int
        : int.tryParse(json['gps_accuracy_m']?.toString() ?? '') ??
            (json['accuracy'] as num?)?.toInt();

    final rawNumVolId = json['volunteer_id'] is int
        ? json['volunteer_id'] as int
        : (json['numeric_volunteer_id'] is int
            ? json['numeric_volunteer_id'] as int
            : int.tryParse(json['volunteer_id']?.toString() ?? ''));

    final rawVolId = json['volunteer_code']?.toString() ??
        json['volunteer_id']?.toString() ??
        (rawNumVolId != null ? rawNumVolId.toString() : '');

    return ReferralItem(
      referralId: refId,
      id: json['referral_code']?.toString() ??
          json['id']?.toString() ??
          (refId != null
              ? 'REF-26-${refId.toString().padLeft(4, '0')}'
              : 'REF-26-0001'),
      facilityName: json['referral_facility_name']?.toString() ??
          json['facility_name']?.toString() ??
          'Sub-Centre / HWC',
      stream: normalizeReferralStream(
        json['referral_stream']?.toString() ?? json['stream']?.toString(),
      ),
      referralType: json['referral_facility_name']?.toString() ??
          json['referral_type']?.toString() ??
          'Sub-Centre / HWC',
      village: json['village_name']?.toString() ??
          json['village']?.toString() ??
          'Amrabad',
      eventDate: DateTime.tryParse(json['event_date']?.toString() ?? '') ??
          DateTime.now(),
      referralDate:
          DateTime.tryParse(json['referral_date']?.toString() ?? '') ??
              DateTime.now(),
      reason: json['reason']?.toString() ??
          json['description']?.toString() ??
          json['remarks']?.toString(),
      isFollowedUp: json['is_followed_up'] == true ||
          json['is_followed_up']?.toString().toLowerCase() == 'true',
      status: rawStatus.toLowerCase() == 'submitted' ? 'synced' : rawStatus,
      mediaFiles: media,
      attachments: attachmentList,
      mediaCaption: json['media_caption']?.toString() ??
          json['caption']?.toString() ??
          json['description']?.toString() ??
          json['remarks']?.toString() ??
          json['reason']?.toString(),
      latitude: lat,
      longitude: lng,
      accuracy: acc,
      volunteerId: rawVolId,
      numericVolunteerId: rawNumVolId,
      volunteerName: json['volunteer_name']?.toString(),
      volunteerCode: json['volunteer_code']?.toString(),
      deviceId: json['device_id']?.toString() ?? 'DEV-C0YBZ9WK',
      clientRef: json['client_ref']?.toString(),
      referralFacilityId: json['referral_facility_id'] is int
          ? json['referral_facility_id'] as int
          : int.tryParse(json['referral_facility_id']?.toString() ?? ''),
      facilityIsOther: json['facility_is_other'] == true,
      eventReportId: json['event_report_id'] is int
          ? json['event_report_id'] as int
          : int.tryParse(json['event_report_id']?.toString() ?? ''),
      villageLgdCode: json['village_lgd_code'] is int
          ? json['village_lgd_code'] as int
          : int.tryParse(json['village_lgd_code']?.toString() ?? ''),
      gramPanchayatName: json['gram_panchayat_name']?.toString(),
      blockName: json['block_name']?.toString(),
      districtName: json['district_name']?.toString(),
      stateName: json['state_name']?.toString(),
      stateLgdCode: json['state_lgd_code'] is int
          ? json['state_lgd_code'] as int
          : int.tryParse(json['state_lgd_code']?.toString() ?? ''),
      districtLgdCode: json['district_lgd_code'] is int
          ? json['district_lgd_code'] as int
          : int.tryParse(json['district_lgd_code']?.toString() ?? ''),
      blockLgdCode: json['block_lgd_code'] is int
          ? json['block_lgd_code'] as int
          : int.tryParse(json['block_lgd_code']?.toString() ?? ''),
      followedUpAt:
          DateTime.tryParse(json['followed_up_at']?.toString() ?? ''),
      gpsUnavailableReason: json['gps_unavailable_reason']?.toString(),
      capturedAt: DateTime.tryParse(json['captured_at']?.toString() ?? ''),
      verificationStatus: json['verification_status']?.toString() ?? rawStatus,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class ReferralFacility {
  final int facilityId;
  final String stream;
  final String facilityName;
  final bool isOther;

  const ReferralFacility({
    required this.facilityId,
    required this.stream,
    required this.facilityName,
    this.isOther = false,
  });

  factory ReferralFacility.fromJson(Map<String, dynamic> json) {
    return ReferralFacility(
      facilityId: json['referral_facility_id'] is int
          ? json['referral_facility_id'] as int
          : int.tryParse(json['referral_facility_id']?.toString() ?? '0') ?? 0,
      stream: json['referral_stream']?.toString() ?? 'HUMAN',
      facilityName: json['referral_facility_name']?.toString() ?? '',
      isOther: json['is_other'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'referral_facility_id': facilityId,
    'referral_stream': stream,
    'referral_facility_name': facilityName,
    'is_other': isOther,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralFacility &&
          runtimeType == other.runtimeType &&
          facilityId == other.facilityId;

  @override
  int get hashCode => facilityId.hashCode;

  @override
  String toString() => facilityName;
}

/// Request model matching backend POST /api/referrals multipart schema
class ReferralCreateRequest {
  final int volunteerId;
  final String? clientRef;
  final String? deviceId;
  final String referralStream; // "HUMAN" or "ANIMAL"
  final int referralFacilityId;
  final int? eventReportId;
  final int villageLgdCode;
  final DateTime eventDate;
  final DateTime referralDate;
  final String? reason;
  final bool isFollowedUp;
  final double? latitude;
  final double? longitude;
  final int? gpsAccuracyM;
  final String? gpsUnavailableReason;
  final DateTime? capturedAt;
  final String? mediaCaption;
  final List<String> photos;
  final List<String> videos;
  final List<String> documents;

  ReferralCreateRequest({
    required this.volunteerId,
    this.clientRef,
    this.deviceId,
    required this.referralStream,
    required this.referralFacilityId,
    this.eventReportId,
    required this.villageLgdCode,
    required this.eventDate,
    required this.referralDate,
    this.reason,
    this.isFollowedUp = false,
    this.latitude,
    this.longitude,
    this.gpsAccuracyM,
    this.gpsUnavailableReason,
    this.capturedAt,
    this.mediaCaption,
    this.photos = const [],
    this.videos = const [],
    this.documents = const [],
  });

  Map<String, dynamic> toJson() => {
        'volunteer_id': volunteerId,
        if (clientRef != null && clientRef!.isNotEmpty) 'client_ref': clientRef,
        if (deviceId != null && deviceId!.isNotEmpty) 'device_id': deviceId,
        'referral_stream': referralStream,
        'referral_facility_id': referralFacilityId,
        if (eventReportId != null) 'event_report_id': eventReportId,
        'village_lgd_code': villageLgdCode,
        'event_date':
            '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
        'referral_date':
            '${referralDate.year.toString().padLeft(4, '0')}-${referralDate.month.toString().padLeft(2, '0')}-${referralDate.day.toString().padLeft(2, '0')}',
        if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
        'is_followed_up': isFollowedUp,
        if (mediaCaption != null && mediaCaption!.trim().isNotEmpty) ...{
          'media_caption': mediaCaption!.trim(),
          'description': mediaCaption!.trim(),
          'caption': mediaCaption!.trim(),
        },
        if (latitude != null) 'latitude': GeoLocationData.formatCoordinate(latitude),
        if (longitude != null) 'longitude': GeoLocationData.formatCoordinate(longitude),
        if (gpsAccuracyM != null) 'gps_accuracy_m': gpsAccuracyM,
        if (gpsUnavailableReason != null)
          'gps_unavailable_reason': gpsUnavailableReason,
        if (capturedAt != null) 'captured_at': capturedAt!.toUtc().toIso8601String(),
        'photos': photos,
        'videos': videos,
        'documents': documents,
      };
}

/// Response returned from POST /api/referrals
class ReferralCreateResult {
  final int referralId;
  final String referralCode;
  final int volunteerId;
  final String referralStream;
  final int referralFacilityId;
  final int villageLgdCode;
  final DateTime eventDate;
  final DateTime referralDate;
  final bool isFollowedUp;
  final String verificationStatus;
  final DateTime createdAt;
  final String status; // 'synced' or 'queued_offline'

  ReferralCreateResult({
    required this.referralId,
    required this.referralCode,
    required this.volunteerId,
    required this.referralStream,
    required this.referralFacilityId,
    required this.villageLgdCode,
    required this.eventDate,
    required this.referralDate,
    this.isFollowedUp = false,
    this.verificationStatus = 'SUBMITTED',
    required this.createdAt,
    this.status = 'synced',
  });

  factory ReferralCreateResult.fromJson(Map<String, dynamic> json) =>
      ReferralCreateResult(
        referralId: json['referral_id'] is int
            ? json['referral_id'] as int
            : int.tryParse(json['referral_id']?.toString() ?? '0') ?? 0,
        referralCode: json['referral_code']?.toString() ?? 'REF-26-0001',
        volunteerId: json['volunteer_id'] is int
            ? json['volunteer_id'] as int
            : int.tryParse(json['volunteer_id']?.toString() ?? '0') ?? 0,
        referralStream: json['referral_stream']?.toString() ?? 'HUMAN',
        referralFacilityId: json['referral_facility_id'] is int
            ? json['referral_facility_id'] as int
            : int.tryParse(json['referral_facility_id']?.toString() ?? '0') ?? 0,
        villageLgdCode: json['village_lgd_code'] is int
            ? json['village_lgd_code'] as int
            : int.tryParse(json['village_lgd_code']?.toString() ?? '0') ?? 0,
        eventDate: DateTime.tryParse(json['event_date']?.toString() ?? '') ??
            DateTime.now(),
        referralDate:
            DateTime.tryParse(json['referral_date']?.toString() ?? '') ??
                DateTime.now(),
        isFollowedUp: json['is_followed_up'] == true ||
            json['is_followed_up']?.toString().toLowerCase() == 'true',
        verificationStatus:
            json['verification_status']?.toString() ?? 'SUBMITTED',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        status: json['status']?.toString() ?? 'synced',
      );
}

