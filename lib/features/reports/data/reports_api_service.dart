import 'package:cohv/core/constants/api_constants.dart';
import '../domain/report_models.dart';

class ReportsApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointRequestReport = ApiConstants.endpointRequestReport;
  static const String endpointReportHistory = ApiConstants.endpointReportHistory;

  /// Request a summary report to be dispatched via email
  Future<ReportItem> requestReport(ReportRequest request) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API is ready, uncomment this block:
    //
    // final response = await http.post(
    //   Uri.parse(endpointRequestReport),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(request.toJson()),
    // );
    // if (response.statusCode == 200 || response.statusCode == 201) {
    //   return ReportItem.fromJson(jsonDecode(response.body));
    // } else {
    //   throw Exception('Failed to generate report. Please try again.');
    // }
    // =======================================================================

    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 900));

    // Simulated response with Section 4 Entity ID nomenclature (RPT-YY-0000)
    final sequence = DateTime.now().millisecondsSinceEpoch % 1000;
    return ReportItem(
      reportId: 'RPT-26-${sequence.toString().padLeft(4, '0')}',
      fromDate: request.fromDate,
      toDate: request.toDate,
      email: request.email,
      status: 'sent',
    );
  }

  /// Get list of requested reports
  Future<List<ReportItem>> getReportHistory(String volunteerId) async {
    // =======================================================================
    // 🔌 REAL API INTEGRATION:
    // When real API is ready, uncomment this block:
    //
    // final response = await http.get(
    //   Uri.parse('$endpointReportHistory?volunteer_id=$volunteerId'),
    // );
    // if (response.statusCode == 200) {
    //   final List data = jsonDecode(response.body);
    //   return data.map((e) => ReportItem.fromJson(e)).toList();
    // }
    // =======================================================================

    await Future.delayed(const Duration(milliseconds: 400));

    // Initial mock item matching prototype screenshot
    return [
      ReportItem(
        reportId: 'RPT-26-0004',
        fromDate: DateTime(2026, 10, 13),
        toDate: DateTime(2026, 10, 13),
        email: 'test1@gmail.com',
        status: 'sent',
      ),
    ];
  }
}
