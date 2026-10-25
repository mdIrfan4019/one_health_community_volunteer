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

    // In the absence of a backend notification endpoint, return an empty list without fake data.
    return [];
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
