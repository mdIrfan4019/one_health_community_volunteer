import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/storage/session_manager.dart';

class AttachmentApiService {
  final http.Client _client;

  AttachmentApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Stream endpoint for inline viewing
  String getStreamUrl(int attachmentId) =>
      ApiConstants.endpointAttachmentStream(attachmentId);

  /// Download endpoint URL
  String getDownloadUrl(int attachmentId) =>
      ApiConstants.endpointAttachmentDownload(attachmentId);

  /// Fetch attachment metadata: GET /api/attachments/{attachment_id}/meta
  Future<AppAttachmentItem?> fetchAttachmentMeta(int attachmentId) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(ApiConstants.endpointAttachmentMeta(attachmentId));

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          final data = decoded['data'] is Map
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : Map<String, dynamic>.from(decoded);
          return AppAttachmentItem.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('[ATTACHMENT_API] Error fetching meta for $attachmentId: $e');
    }
    return null;
  }

  /// Download attachment binary data: GET /api/attachments/{attachment_id}/download
  Future<Uint8List?> downloadAttachment(int attachmentId) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(ApiConstants.endpointAttachmentDownload(attachmentId));

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders(token: token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[ATTACHMENT_API] Error downloading attachment $attachmentId: $e');
    }
    return null;
  }
}
