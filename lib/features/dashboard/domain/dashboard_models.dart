// Create file: lib/features/dashboard/domain/dashboard_models.dart

class DashboardMetrics {
  final int totalVisits;
  final int alertsGenerated;
  final int referrals;
  final int pendingFollowUps;
  final int awarenessActivities;
  final int trainingsImparted;
  final int trainingsAttended;
  final int pendingSyncCount;

  DashboardMetrics({
    this.totalVisits = 0,
    this.alertsGenerated = 0,
    this.referrals = 0,
    this.pendingFollowUps = 0,
    this.awarenessActivities = 0,
    this.trainingsImparted = 0,
    this.trainingsAttended = 0,
    this.pendingSyncCount = 0,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalVisits: json['total_visits'] ?? 0,
      alertsGenerated: json['alerts_generated'] ?? 0,
      referrals: json['referrals'] ?? 0,
      pendingFollowUps: json['pending_follow_ups'] ?? 0,
      awarenessActivities: json['awareness_activities'] ?? 0,
      trainingsImparted: json['trainings_imparted'] ?? 0,
      trainingsAttended: json['trainings_attended'] ?? 0,
      pendingSyncCount: json['pending_sync_count'] ?? 0,
    );
  }
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
