import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import '../domain/report_models.dart';

class ReportsApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointRequestReport = ApiConstants.endpointRequestReport;
  static const String endpointReportHistory = ApiConstants.endpointReportHistory;
  static const String endpointReportTypes = ApiConstants.endpointReportTypes;
  static const String endpointReportRequests = ApiConstants.endpointReportRequests;
  static const String endpointSendReportEmail =
      ApiConstants.endpointSendReportEmail;

  final http.Client _client = http.Client();

  /// Fetch list of available report types from /api/volunteers/me/reports/types
  Future<List<ReportTypeModel>> fetchReportTypes() async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointReportTypes);

    try {
      debugPrint('[REPORTS_API] GET $url');
      final response = await _client.get(
        url,
        headers: ApiConstants.defaultHeaders(token: token),
      ).timeout(const Duration(seconds: 15));

      debugPrint('[REPORTS_API] GET $url status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List list = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : []);

        if (list.isNotEmpty) {
          final types = list
              .whereType<Map>()
              .map((e) => ReportTypeModel.fromJson(Map<String, dynamic>.from(e)))
              .where((t) => t.value.isNotEmpty && t.label.isNotEmpty)
              .toList();
          if (types.isNotEmpty) {
            return types;
          }
        }
      }
    } catch (e) {
      debugPrint('[REPORTS_API] Error fetching report types: $e');
    }

    // Safe fallback list matching API specifications
    return ReportTypeModel.fallbackReportTypes;
  }

  /// Send report on email: POST /api/volunteers/me/reports/send-email
  Future<ReportItem> requestReport(ReportRequest request) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointSendReportEmail);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final payloadJson = jsonEncode(request.toJson());
    debugPrint('[REPORTS_API] POST $url body: $payloadJson');

    try {
      final response = await _client
          .post(
            url,
            headers: headers,
            body: payloadJson,
          )
          .timeout(const Duration(seconds: 25));

      debugPrint(
        '[REPORTS_API] POST $url status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> data = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
        return ReportItem.fromJson(data);
      }

      // Handle server error response
      String errorMsg = 'Server returned error status ${response.statusCode}';
      try {
        final errJson = jsonDecode(utf8.decode(response.bodyBytes));
        if (errJson is Map) {
          if (errJson['detail'] != null) {
            final detail = errJson['detail'];
            if (detail is String) {
              errorMsg = detail;
            } else if (detail is List && detail.isNotEmpty) {
              final first = detail.first;
              errorMsg = first['msg']?.toString() ?? detail.toString();
            }
          } else if (errJson['message'] != null) {
            errorMsg = errJson['message'].toString();
          }
        }
      } catch (_) {}

      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('[REPORTS_API] Error sending report on email: $e');
      rethrow;
    }
  }

  /// Get list of requested reports strictly for the authenticated volunteer:
  /// GET /api/volunteers/me/reports/requests
  Future<List<ReportItem>> getReportHistory() async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointReportRequests);

    debugPrint('[REPORTS_API] GET $url with Bearer token');

    try {
      final response = await _client.get(
        url,
        headers: ApiConstants.defaultHeaders(token: token),
      ).timeout(const Duration(seconds: 15));

      debugPrint(
        '[REPORTS_API] GET $url status: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List list = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : []);

        return list
            .whereType<Map>()
            .map((e) => ReportItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('[REPORTS_API] Network error getting report history: $e');
    }

    // Dummy card removed! Return empty list when no reports exist or upon network failure
    return [];
  }
}
