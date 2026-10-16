import 'package:cohv/core/constants/api_constants.dart';
import '../domain/notification_models.dart';

class NotificationsApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointNotifications = ApiConstants.endpointNotifications;
  static const String endpointMarkRead = ApiConstants.endpointMarkRead;

  /// Fetch notifications for the logged-in volunteer
  Future<List<AppNotification>> getNotifications(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointNotifications?volunteer_id=$volunteerId'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     // 'Authorization': 'Bearer $token',
    //   },
    // );
    // if (response.statusCode == 200) {
    //   final List data = jsonDecode(response.body);
    //   return data.map((e) => AppNotification.fromJson(e)).toList();
    // } else {
    //   throw Exception('Failed to load notifications from server.');
    // }
    // =======================================================================

    // Simulated network latency
    await Future.delayed(const Duration(milliseconds: 350));

    // Simulated fallback data matching prototype screenshot
    return [
      AppNotification(
        id: 'NOTIF-26-0009',
        title: 'Synchronisation complete',
        timestamp: '13 Oct 2026, 11:40',
        message: '2 record(s) uploaded. Supervisor Assigned on approval notified.',
        type: 'sync',
      ),
      AppNotification(
        id: 'NOTIF-26-0008',
        title: 'Synchronisation complete',
        timestamp: '13 Oct 2026, 10:59',
        message: '1 record(s) uploaded. Supervisor Assigned on approval notified.',
        type: 'sync',
      ),
      AppNotification(
        id: 'NOTIF-26-0007',
        title: 'Synchronisation complete',
        timestamp: '13 Oct 2026, 10:55',
        message: '4 record(s) uploaded. Supervisor Assigned on approval notified.',
        type: 'sync',
      ),
      AppNotification(
        id: 'NOTIF-26-0006',
        title: 'Synchronisation complete',
        timestamp: '13 Oct 2026, 10:12',
        message: '1 record(s) uploaded. Supervisor Assigned on approval notified.',
        type: 'sync',
      ),
      AppNotification(
        id: 'NOTIF-26-0005',
        title: 'Report requested',
        timestamp: '13 Oct 2026, 10:11',
        message: 'Report for 13 Oct 2026 — 13 Oct 2026 queued for delivery to test1@gmail.com.',
        type: 'report',
      ),
      AppNotification(
        id: 'NOTIF-26-0004',
        title: 'Synchronisation complete',
        timestamp: '13 Oct 2026, 10:11',
        message: '2 record(s) uploaded. Supervisor Assigned on approval notified.',
        type: 'sync',
      ),
      AppNotification(
        id: 'NOTIF-26-0003',
        title: 'Alert raised',
        timestamp: '13 Oct 2026, 10:10',
        message: 'Event VISIT-26-0002 generated alert ALERT-26-0003, sent to Assigned on approval for escalation.',
        type: 'alert',
      ),
      AppNotification(
        id: 'NOTIF-26-0002',
        title: 'Registration approved',
        timestamp: '13 Oct 2026, 10:05',
        message: 'Your supervisor activated the account. Reporting is open.',
        type: 'registration',
      ),
      AppNotification(
        id: 'NOTIF-26-0001',
        title: 'Registration submitted',
        timestamp: '13 Oct 2026, 10:04',
        message: 'Volunteer ID COHV-26-0001 issued. Awaiting approval by Assigned on approval.',
        type: 'registration',
      ),
    ];
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // await http.post(
    //   Uri.parse(endpointMarkRead),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'id': notificationId}),
    // );
    // =======================================================================
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
