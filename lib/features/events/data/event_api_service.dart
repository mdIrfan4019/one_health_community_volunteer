import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import '../../sync/data/sync_repository.dart';
import '../domain/event_models.dart';

class EventApiService {
  // =========================================================================
  // 🔌 BACKEND API CONFIGURATION (Centralized in ApiConstants)
  // =========================================================================
  static const String baseUrl = ApiConstants.baseUrl;
  static const String endpointEvents = ApiConstants.endpointEvents;
  static const String endpointReportEvent = ApiConstants.endpointReportEvent;
  static const String endpointEventFormMetadata =
      ApiConstants.endpointEventFormMetadata;

  final http.Client _client;
  final SyncRepository _syncRepository;

  EventApiService({
    http.Client? client,
    SyncRepository? syncRepository,
  })  : _client = client ?? http.Client(),
        _syncRepository = syncRepository ?? SyncRepository();

  /// Retrieve cached event form metadata for instant UI rendering without flicker
  Future<EventFormMetadata?> getCachedMetadata() async {
    try {
      final cachedJson = await SessionManager.getEventFormMetadata();
      if (cachedJson != null) {
        return EventFormMetadata.fromJson(cachedJson);
      }
    } catch (e) {
      debugPrint('[EVENT_API] Error reading cached event form metadata: $e');
    }
    return null;
  }

  /// Fetch dynamic event form metadata for the logged-in volunteer from:
  /// GET /api/events/form-metadata with Bearer token
  Future<EventFormMetadata> getEventFormMetadata({
    bool forceRefresh = false,
  }) async {
    // 1. If not forcing refresh, check if valid cache exists
    if (!forceRefresh) {
      final cached = await getCachedMetadata();
      if (cached != null) {
        // Asynchronously refresh in background
        _refreshMetadataInBackground();
        return cached;
      }
    }

    try {
      final token = await SessionManager.getToken();
      final url = Uri.parse(endpointEventFormMetadata);

      debugPrint(
          '[EVENT_API] GET $url with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}');

      final response = await _client
          .get(
            url,
            headers: ApiConstants.defaultHeaders(token: token),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
          '[EVENT_API] /api/events/form-metadata status: ${response.statusCode}, body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        // Cache to SharedPreferences for offline support
        await SessionManager.saveEventFormMetadata(decoded);
        return EventFormMetadata.fromJson(decoded);
      } else {
        debugPrint(
            '[EVENT_API] Server returned non-200 status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[EVENT_API] Network error fetching event form metadata: $e');
    }

    // 2. Fallback to cached data if network failed
    final cached = await getCachedMetadata();
    if (cached != null) {
      return cached;
    }

    // 3. Fallback to default schema if offline with no previous cache
    debugPrint('[EVENT_API] Returning schema fallback metadata for volunteer.');
    return EventFormMetadata.fallback();
  }

  void _refreshMetadataInBackground() async {
    try {
      final token = await SessionManager.getToken();
      final response = await _client
          .get(
            Uri.parse(endpointEventFormMetadata),
            headers: ApiConstants.defaultHeaders(token: token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        await SessionManager.saveEventFormMetadata(decoded);
        debugPrint(
            '[EVENT_API] Background refresh of event form metadata succeeded.');
      }
    } catch (_) {}
  }

  /// Submit event report via POST /api/events (multipart/form-data)
  ///
  /// Sends event metadata along with uploaded photographs, videos, and documents
  /// to the backend server with the logged-in volunteer's Bearer token.
  /// If offline, automatically enqueues into SyncRepository for later synchronization.
  Future<EventReportResult> submitEventReport(EventReportRequest request) async {
    final token = await SessionManager.getToken();
    final url = Uri.parse(endpointEvents);

    debugPrint(
        '[EVENT_API] POST $url (multipart/form-data) with Bearer token: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[NONE]"}');

    try {
      final multipartRequest = http.MultipartRequest('POST', url);

      // 1. Authorization & Header Setup
      if (token != null && token.isNotEmpty) {
        multipartRequest.headers['Authorization'] = 'Bearer $token';
      }
      multipartRequest.headers['Accept'] = 'application/json';

      // 2. Required Form Fields (Schema: EventReportForm)
      multipartRequest.fields['event_type_id'] =
          request.eventTypeId.toString();

      if (request.eventTypeOther != null &&
          request.eventTypeOther!.trim().isNotEmpty) {
        multipartRequest.fields['event_type_other'] =
            request.eventTypeOther!.trim();
      }

      final dateFormatted =
          '${request.date.year.toString().padLeft(4, '0')}-${request.date.month.toString().padLeft(2, '0')}-${request.date.day.toString().padLeft(2, '0')}';
      multipartRequest.fields['date'] = dateFormatted;

      var timeFormatted = request.time.trim();
      if (timeFormatted.length == 5) {
        // e.g. "09:30" -> "09:30:00"
        timeFormatted = '$timeFormatted:00';
      }
      multipartRequest.fields['time'] = timeFormatted;

      multipartRequest.fields['village_lgd_code'] =
          request.villageLgdCode.toString();
      multipartRequest.fields['is_out_of_area'] =
          request.isOutOfAreaVisit ? 'true' : 'false';
      multipartRequest.fields['purpose_of_visit'] = request.purposeOfVisit;
      multipartRequest.fields['location_type'] = request.locationType;
      multipartRequest.fields['total_visits'] =
          request.totalVisits.toString();
      multipartRequest.fields['population_type_id'] =
          request.populationTypeId.toString();

      // Optional Content Fields
      if (request.populationOther != null &&
          request.populationOther!.trim().isNotEmpty) {
        multipartRequest.fields['population_other'] =
            request.populationOther!.trim();
      }
      if (request.observations.trim().isNotEmpty) {
        multipartRequest.fields['observations'] = request.observations.trim();
      }
      if (request.actionTaken.trim().isNotEmpty) {
        multipartRequest.fields['action_taken'] = request.actionTaken.trim();
      }
      final desc = request.description ?? request.mediaCaption;
      if (desc != null && desc.trim().isNotEmpty) {
        multipartRequest.fields['description'] = desc.trim();
      }

      // Flags
      multipartRequest.fields['referral_generated'] =
          request.isReferralGenerated ? 'true' : 'false';
      multipartRequest.fields['alert_generated'] =
          request.isAlertGenerated ? 'true' : 'false';
      multipartRequest.fields['follow_up_required'] =
          request.isFollowUpRequired ? 'true' : 'false';

      // Geolocation Coordinates
      multipartRequest.fields['latitude'] = request.latitude.toString();
      multipartRequest.fields['longitude'] = request.longitude.toString();
      multipartRequest.fields['gps_accuracy_m'] = request.accuracy.toString();

      if (request.gpsUnavailableReason != null &&
          request.gpsUnavailableReason!.trim().isNotEmpty) {
        multipartRequest.fields['gps_unavailable_reason'] =
            request.gpsUnavailableReason!.trim();
      }

      if (request.deviceId.trim().isNotEmpty) {
        multipartRequest.fields['device_id'] = request.deviceId.trim();
      }

      final clientRef = request.clientRef ??
          'EVT-CLI-${DateTime.now().millisecondsSinceEpoch}';
      multipartRequest.fields['client_ref'] = clientRef;

      // 3. Attach Media Files (photos, videos, documents)
      final photos =
          request.photos.isNotEmpty ? request.photos : request.mediaFiles;
      for (final filePath in photos) {
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile =
              await http.MultipartFile.fromPath('photos', file.path);
          multipartRequest.files.add(multipartFile);
        }
      }

      for (final filePath in request.videos) {
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile =
              await http.MultipartFile.fromPath('videos', file.path);
          multipartRequest.files.add(multipartFile);
        }
      }

      for (final filePath in request.documents) {
        final file = File(filePath);
        if (await file.exists()) {
          final multipartFile =
              await http.MultipartFile.fromPath('documents', file.path);
          multipartRequest.files.add(multipartFile);
        }
      }

      debugPrint(
          '[EVENT_API] Dispatching multipart request with ${multipartRequest.fields.length} fields and ${multipartRequest.files.length} files...');

      final streamedResponse = await _client
          .send(multipartRequest)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
          '[EVENT_API] POST /api/events response status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        return EventReportResult.fromJson(data);
      } else {
        String errorMsg = 'Server returned status ${response.statusCode}';
        try {
          final errJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errJson is Map && errJson['detail'] != null) {
            final detail = errJson['detail'];
            if (detail is String) {
              errorMsg = detail;
            } else if (detail is List && detail.isNotEmpty) {
              final first = detail.first;
              errorMsg =
                  '${first['loc'] != null ? first['loc'].last : "Validation"}: ${first['msg']}';
            }
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('[EVENT_API] Exception during event report submission: $e');

      // Offline Resilience: If network error or host unreachable, store in SyncRepository
      final isOffline = e is SocketException ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException');

      if (isOffline) {
        final seq = DateTime.now().millisecondsSinceEpoch % 1000;
        final reportId = 'OFFLINE-EVT-26-${seq.toString().padLeft(4, '0')}';
        final alertId = request.isAlertGenerated
            ? 'ALERT-26-${(seq + 1).toString().padLeft(4, '0')}'
            : null;

        await _syncRepository.enqueueRecord(
          entityType: 'EVENT',
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
              ? 'Network offline. Event report queued locally. Alert $alertId will synchronize once connectivity is restored.'
              : 'Network offline. Event report saved locally and queued for automatic sync.',
        );
      }

      rethrow;
    }
  }
}
