// Create file: lib/features/events/domain/event_models.dart

class EventReportRequest {
  final String eventType;
  final String primarySector;
  final DateTime date;
  final String time;
  final String village;
  final bool isOutOfAreaVisit;
  final String purposeOfVisit;
  final String locationType;
  final int totalVisits;
  final String targetPopulation;
  final String observations;
  final String actionTaken;
  final bool isReferralGenerated;
  final bool isAlertGenerated;
  final bool isFollowUpRequired;
  final List<String> mediaFiles;
  final String? mediaCaption;
  final double latitude;
  final double longitude;
  final int accuracy;
  final String volunteerId;
  final String deviceId;

  EventReportRequest({
    required this.eventType,
    required this.primarySector,
    required this.date,
    required this.time,
    required this.village,
    required this.isOutOfAreaVisit,
    required this.purposeOfVisit,
    required this.locationType,
    required this.totalVisits,
    required this.targetPopulation,
    required this.observations,
    required this.actionTaken,
    required this.isReferralGenerated,
    required this.isAlertGenerated,
    required this.isFollowUpRequired,
    required this.mediaFiles,
    this.mediaCaption,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.volunteerId,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    'primary_sector': primarySector,
    'date': date.toIso8601String(),
    'time': time,
    'village': village,
    'is_out_of_area_visit': isOutOfAreaVisit,
    'purpose_of_visit': purposeOfVisit,
    'location_type': locationType,
    'total_visits': totalVisits,
    'target_population': targetPopulation,
    'observations': observations,
    'action_taken': actionTaken,
    'is_referral_generated': isReferralGenerated,
    'is_alert_generated': isAlertGenerated,
    'is_follow_up_required': isFollowUpRequired,
    'media_files': mediaFiles,
    'media_caption': mediaCaption,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'volunteer_id': volunteerId,
    'device_id': deviceId,
  };
}

class EventReportResult {
  final String reportId; // e.g. VISIT-26-0002
  final String status;   // 'synced' or 'queued_offline'
  final String? alertId; // e.g. ALERT-26-0003 if alert flag is true
  final String message;

  EventReportResult({
    required this.reportId,
    required this.status,
    this.alertId,
    required this.message,
  });

  factory EventReportResult.fromJson(Map<String, dynamic> json) => EventReportResult(
    reportId: json['report_id'] ?? 'VISIT-26-0001',
    status: json['status'] ?? 'synced',
    alertId: json['alert_id'],
    message: json['message'] ?? 'Event reported successfully.',
  );
}
