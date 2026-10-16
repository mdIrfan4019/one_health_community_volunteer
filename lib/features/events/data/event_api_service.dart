import 'package:cohv/core/constants/api_constants.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/event_models.dart';

class EventApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointReportEvent = ApiConstants.endpointReportEvent;

  final SyncRepository _syncRepository = SyncRepository();

  /// Submit event report (Supports online upload and automatic offline queuing)
  Future<EventReportResult> submitEventReport(EventReportRequest request) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API endpoint is ready, uncomment this block:
    //
    // final response = await http.post(
    //   Uri.parse(endpointReportEvent),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     // 'Authorization': 'Bearer $token',
    //   },
    //   body: jsonEncode(request.toJson()),
    // );
    // if (response.statusCode == 200 || response.statusCode == 201) {
    //   return EventReportResult.fromJson(jsonDecode(response.body));
    // } else {
    //   throw Exception('Failed to submit event report to server.');
    // }
    // =======================================================================

    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 900));

    // Generate Standard Entity Sequence IDs (VISIT-26-XXXX and ALERT-26-XXXX)
    final seq = DateTime.now().millisecondsSinceEpoch % 1000;
    final reportId = 'VISIT-26-${seq.toString().padLeft(4, '0')}';
    final alertId = request.isAlertGenerated ? 'ALERT-26-${(seq + 1).toString().padLeft(4, '0')}' : null;

    // Automatically enqueue into local offline Sync Repository
    await _syncRepository.enqueueRecord(
      entityType: 'VISIT',
      payload: {
        'report_id': reportId,
        'alert_id': alertId,
        ...request.toJson(),
      },
    );

    return EventReportResult(
      reportId: reportId,
      status: 'queued_offline',
      alertId: alertId,
      message: request.isAlertGenerated
          ? 'Event $reportId generated alert $alertId.'
          : 'Event $reportId saved successfully.',
    );
  }
}
