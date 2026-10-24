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

  VolunteerProfile({
    required this.fullName,
    required this.volunteerId,
    required this.status,
    required this.locationBreadcrumb,
    this.photoUrl,
  });

  factory VolunteerProfile.fromJson(Map<String, dynamic> json) {
    return VolunteerProfile(
      fullName: json['full_name'] ?? '',
      volunteerId: json['volunteer_id'] ?? '',
      status: json['status'] ?? 'Active',
      locationBreadcrumb: json['location_breadcrumb'] ?? '—',
      photoUrl: json['photo_url'],
    );
  }
}
