// Create file: lib/features/dashboard/domain/dashboard_models.dart

class DashboardMetrics {
  final int totalVisits;
  final int alertsGenerated;
  final int openAlerts;
  final int referrals;
  final int referralsFollowup;
  final int pendingFollowUps;
  final int awarenessActivities;
  final int trainingsImparted;
  final int trainingsAttended;
  final int meetings;
  final int samplesSupported;
  final int successStories;
  final int pendingSyncCount;
  final int? volunteerId;
  final String? volunteerCode;
  final String? volunteerName;

  DashboardMetrics({
    this.totalVisits = 0,
    this.alertsGenerated = 0,
    this.openAlerts = 0,
    this.referrals = 0,
    this.referralsFollowup = 0,
    this.pendingFollowUps = 0,
    this.awarenessActivities = 0,
    this.trainingsImparted = 0,
    this.trainingsAttended = 0,
    this.meetings = 0,
    this.samplesSupported = 0,
    this.successStories = 0,
    this.pendingSyncCount = 0,
    this.volunteerId,
    this.volunteerCode,
    this.volunteerName,
  });

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  factory DashboardMetrics.fromJson(
    Map<String, dynamic> json, {
    int? localPendingSync,
  }) {
    // If wrapped in 'data' object from API payload, drill down
    final Map<String, dynamic> data =
        (json['data'] is Map<String, dynamic>)
            ? json['data'] as Map<String, dynamic>
            : (json['data'] is Map
                ? Map<String, dynamic>.from(json['data'] as Map)
                : json);

    final rawVid = data['volunteer_id'];
    int? parsedVid;
    if (rawVid is int) {
      parsedVid = rawVid;
    } else if (rawVid is String) {
      parsedVid = int.tryParse(rawVid);
    }

    return DashboardMetrics(
      totalVisits: _parseInt(data['total_visits']),
      alertsGenerated: _parseInt(data['alerts_generated']),
      openAlerts: _parseInt(data['open_alerts']),
      referrals: _parseInt(data['referrals']),
      referralsFollowup: _parseInt(data['referrals_followup']),
      pendingFollowUps: _parseInt(
        data['pending_follow_ups'] ?? data['pending_followups'],
      ),
      awarenessActivities: _parseInt(
        data['awareness_activities'] ?? data['awareness'],
      ),
      trainingsImparted: _parseInt(data['trainings_imparted']),
      trainingsAttended: _parseInt(data['trainings_attended']),
      meetings: _parseInt(data['meetings']),
      samplesSupported: _parseInt(
        data['samples_supported'] ?? data['samples'],
      ),
      successStories: _parseInt(data['success_stories']),
      pendingSyncCount: localPendingSync ??
          _parseInt(data['pending_sync_count'] ?? data['pending_sync']),
      volunteerId: parsedVid,
      volunteerCode: data['volunteer_code']?.toString(),
      volunteerName: data['volunteer_name']?.toString() ??
          data['full_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_visits': totalVisits,
    'alerts_generated': alertsGenerated,
    'open_alerts': openAlerts,
    'referrals': referrals,
    'referrals_followup': referralsFollowup,
    'pending_follow_ups': pendingFollowUps,
    'awareness_activities': awarenessActivities,
    'trainings_imparted': trainingsImparted,
    'trainings_attended': trainingsAttended,
    'meetings': meetings,
    'samples_supported': samplesSupported,
    'success_stories': successStories,
    'pending_sync_count': pendingSyncCount,
    if (volunteerId != null) 'volunteer_id': volunteerId,
    if (volunteerCode != null) 'volunteer_code': volunteerCode,
    if (volunteerName != null) 'volunteer_name': volunteerName,
  };
}

class VolunteerProfile {
  final String fullName;
  final String volunteerId;
  final String status;
  final String locationBreadcrumb;
  final String? photoUrl;
  final String departmentName;

  VolunteerProfile({
    required this.fullName,
    required this.volunteerId,
    required this.status,
    required this.locationBreadcrumb,
    this.photoUrl,
    this.departmentName = 'Public Health Department',
  });

  factory VolunteerProfile.fromJson(Map<String, dynamic> json) {
    return VolunteerProfile(
      fullName: json['full_name'] ?? json['volunteer_name'] ?? '',
      volunteerId: json['volunteer_id'] ?? json['volunteer_code'] ?? '',
      status: json['status'] ?? 'Active',
      locationBreadcrumb: json['location_breadcrumb'] ?? json['village_name'] ?? '—',
      photoUrl: json['photo_url'] ?? json['photo_path'],
      departmentName: json['department_name'] ?? json['cohv_type'] ?? json['sector'] ?? 'Public Health Department',
    );
  }
}
